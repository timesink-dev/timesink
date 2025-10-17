defmodule Timesink.Account.Profile do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Timesink.Account
  alias Timesink.{Repo, Storage}
  alias Timesink.Account.Profile
  alias Timesink.Images
  alias Timesink.Storage.Attachment

  @type t :: %{
          __struct__: __MODULE__,
          user_id: Ecto.UUID.t(),
          user: Account.User.t(),
          avatar: Timesink.Storage.Attachment.t(),
          birthdate: Date.t(),
          location: Account.Location.t(),
          org_name: String.t(),
          org_position: String.t(),
          bio: String.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "profile" do
    belongs_to :user, Account.User

    has_one :avatar, {"profile_attachment", Storage.Attachment},
      foreign_key: :assoc_id,
      where: [name: "avatar"]

    field :birthdate, :date
    field :org_name, :string
    field :org_position, :string
    field :bio, :string

    embeds_one :location, Account.Location

    has_one :creative, Timesink.Cinema.Creative

    timestamps(type: :utc_datetime)
  end

  @spec changeset(profile :: t(), params :: %{optional(atom()) => term()}) ::
          Ecto.Changeset.t()
  def changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:user_id, :birthdate, :org_name, :org_position, :bio])
    |> cast_embed(:location, required: false)
    |> cast_assoc(:user, with: &Account.User.changeset/2)
  end

  def birthdate_changeset(%{__struct__: __MODULE__} = struct, %{} = params) do
    struct
    |> cast(params, [:birthdate])
    |> validate_required([:birthdate])
    |> validate_date()
  end

  @doc "Avatar resize/encode spec"
  def avatar_resize do
    %{
      accept_exts: ~w(.jpg .jpeg .png .webp .heic),
      max_bytes: 8_000_000,
      variants: %{
        md: %{resize: {:fill, 256, 256}, format: :webp, quality: 82}
      }
    }
  end

  def avatar_url(att, variant \\ :md)

  def avatar_url(nil, _variant),
    do: "/images/default-avatar.png"

  def avatar_url(%Timesink.Storage.Attachment{metadata: %{"variants" => vs}}, variant) do
    key = vs[Atom.to_string(variant)] || vs["md"] || vs["lg"] || vs["sm"]
    Timesink.Storage.S3.public_url(key)
  end

  def avatar_url(%Timesink.Storage.Attachment{blob: %{uri: path}}, _variant)
      when is_binary(path) do
    Timesink.Storage.S3.public_url(path)
  end

  def avatar_url(_anything, _variant),
    do: "/images/default-avatar.png"

  @doc """
  Processes avatar variants with libvips (`image`), uploads each as a Blob,
  and creates a single `:avatar` Attachment whose metadata contains a `variants` map.
  """
  def attach_avatar(%{__struct__: __MODULE__} = profile, %Plug.Upload{} = upload, opts \\ []) do
    attach(profile, upload, opts)
  end

  defp attach(%Profile{} = profile, %Plug.Upload{} = upload, opts) do
    user_id = Keyword.get(opts, :user_id, profile.user_id)
    spec = Profile.avatar_resize()
    variants = Images.process_variants!(upload, spec)

    # Load current avatar so we can purge its blobs after we swap
    profile = Repo.preload(profile, avatar: [:blob])

    # Collect what we must keep later (new URIs) and what to purge (old)
    old_att = profile.avatar
    old_blob_id = old_att && old_att.blob_id

    old_variant_uris =
      (old_att && get_in(old_att.metadata, ["variants"]))
      |> case do
        m when is_map(m) -> Map.values(m)
        _ -> []
      end

    result =
      Repo.transaction(fn ->
        # upload new blobs
        blobs_by_name =
          for {name, %{path: path, content_type: ct}} <- variants, into: %{} do
            pseudo = %Plug.Upload{
              path: path,
              filename: variant_name(upload.filename, name),
              content_type: ct
            }

            case Storage.create_blob(pseudo, user_id: user_id) do
              {:ok, blob} -> {name, blob}
              {:error, reason} -> Repo.rollback({:create_blob_failed, name, reason})
            end
          end

        # build new metadata
        meta_variants =
          blobs_by_name
          |> Enum.map(fn {name, blob} -> {Atom.to_string(name), blob.uri} end)
          |> Enum.into(%{})

        metadata = %{"variants" => meta_variants, "canonical" => "md"}
        canonical = blobs_by_name[:md] || blobs_by_name[:lg] || blobs_by_name[:sm]

        # upsert the single attachment pointing at the new canonical blob
        case upsert_avatar!(profile, canonical, metadata) do
          {:ok, att} ->
            # Return enough info for post-commit purge
            keep_uris = Map.values(meta_variants)

            %{
              attachment: att,
              keep_uris: keep_uris,
              old_blob_id: old_blob_id,
              old_variant_uris: old_variant_uris
            }

          {:error, cs} ->
            Repo.rollback({:create_or_update_attachment_failed, cs})
        end
      end)

    case result do
      {:ok,
       %{
         attachment: att,
         keep_uris: keep_uris,
         old_blob_id: old_blob_id,
         old_variant_uris: old_variant_uris
       }} ->
        # purge AFTER commit so we don’t risk rolling back new writes while S3 deletion already happened
        Task.start(fn -> purge_old_blobs(old_blob_id, old_variant_uris, keep_uris) end)
        {:ok, att}

      {:error, cs} ->
        require Logger
        Logger.error("Attachment insert failed: #{inspect(cs)}")
        {:error, cs}
    end
  end

  defp purge_old_blobs(old_blob_id, old_variant_uris, keep_uris) do
    # Build the set of URIs we should NOT delete (the new ones)
    keep = MapSet.new(keep_uris || [])

    # Delete the previous canonical blob by id (if any)
    if is_binary(old_blob_id) do
      # Prefer a Storage helper that deletes from S3 *and* DB:
      # Storage.delete_blob/1 (example below)
      _ = Storage.delete_blob(old_blob_id)
    end

    # Delete any old variant blobs that aren’t kept
    uris_to_delete =
      (old_variant_uris || [])
      |> Enum.reject(&MapSet.member?(keep, &1))

    if uris_to_delete != [] do
      # Find blob rows by URI so we can delete them cleanly
      from(b in Timesink.Storage.Blob,
        where: b.uri in ^uris_to_delete,
        select: %{id: b.id, uri: b.uri}
      )
      |> Timesink.Repo.all()
      |> Enum.each(fn %{id: id} ->
        _ = Storage.delete_blob(id)
      end)
    end
  end

  defp variant_name(orig, name) do
    base = Path.rootname(orig)
    "#{base}-#{name}.webp"
  end

  defp validate_date(changeset) do
    validate_change(changeset, :birthdate, fn :birthdate, date ->
      cond do
        Date.compare(date, Date.utc_today()) == :gt ->
          [birthdate: "You can’t be born in the future McFly!"]

        too_old_to_believe?(date) ->
          [birthdate: "That seems a bit early. We’re flattered, though."]

        too_young?(date) ->
          [birthdate: "Sorry! You'll have to wait a few years to be able to join the platform."]

        true ->
          []
      end
    end)
  end

  defp upsert_avatar!(
         %Timesink.Account.Profile{} = profile,
         %Timesink.Storage.Blob{} = canonical_blob,
         metadata
       ) do
    # Load existing avatar
    profile = Repo.preload(profile, avatar: [:blob])

    params = %{
      blob_id: canonical_blob.id,
      name: "avatar",
      metadata: metadata
    }

    case profile.avatar do
      %Attachment{} = existing ->
        existing
        |> Attachment.changeset(params)
        |> Attachment.insert_or_update()

      nil ->
        profile
        |> Ecto.build_assoc(:avatar)
        |> Attachment.changeset(params)
        |> Attachment.insert_or_update()
    end
  end

  defp too_young?(date), do: Date.diff(Date.utc_today(), date) < 16 * 365
  defp too_old_to_believe?(date), do: Date.diff(Date.utc_today(), date) > 110 * 365
end
