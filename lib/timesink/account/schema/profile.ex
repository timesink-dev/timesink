defmodule Timesink.Account.Profile do
  use Ecto.Schema
  use SwissSchema, repo: Timesink.Repo
  use Timesink.Schema
  import Ecto.Changeset
  alias Timesink.Account
  alias Timesink.{Repo, Storage}
  alias Timesink.Account.Profile
  alias Timesink.Images

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

    case Repo.transaction(fn ->
           # 0) Remove existing avatar (avoid unique constraint on [:assoc_id, :name])
           profile = Repo.preload(profile, avatar: [:blob])

           #  if profile.avatar do
           #    case Storage.delete_attachment(profile.avatar) do
           #      {:ok, :deleted} -> :ok
           #      {:error, reason} -> Repo.rollback({:delete_avatar_failed, reason})
           #    end
           #  end

           # Upload each variant as its own blob
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

           # Build metadata
           meta_variants =
             blobs_by_name
             |> Enum.map(fn {name, blob} -> {Atom.to_string(name), blob.uri} end)
             |> Enum.into(%{})

           metadata = %{"variants" => meta_variants, "canonical" => "md"}

           # Create the attachment pointing to the canonical blob
           canonical = blobs_by_name[:md] || blobs_by_name[:lg] || blobs_by_name[:sm]

           case upsert_avatar!(profile, canonical, metadata) do
             # or :md based on your UI
             {:ok, att} ->
               att

             {:error, cs} ->
               Repo.rollback({:create_or_update_attachment_failed, cs})
           end
         end) do
      {:ok, %Timesink.Storage.Attachment{} = att} ->
        {:ok, att}

      {:error, cs} ->
        require Logger
        Logger.error("Attachment insert failed: #{inspect(cs.errors)}")
        {:error, cs}
    end
  end

  defp variant_name(orig, name) do
    base = Path.rootname(orig || "avatar")
    "#{base}-#{name}.webp"
  end

  # --- private ---

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

  alias Timesink.{Repo, Storage}
  alias Timesink.Storage.Attachment

  defp upsert_avatar!(
         %Timesink.Account.Profile{} = profile,
         %Timesink.Storage.Blob{} = canonical_blob,
         metadata
       ) do
    # Load existing avatar (has_one with where name: "avatar")
    profile = Repo.preload(profile, avatar: [:blob])

    params = %{
      blob_id: canonical_blob.id,
      name: "avatar",
      metadata: metadata
    }

    case profile.avatar do
      %Attachment{} = existing ->
        # UPDATE path
        existing
        |> Attachment.changeset(params)
        # SwissSchema
        |> Attachment.insert_or_update()

      nil ->
        # INSERT path (build assoc sets assoc_id for you)
        profile
        |> Ecto.build_assoc(:avatar)
        |> Attachment.changeset(params)
        # SwissSchema
        |> Attachment.insert_or_update()
    end
  end

  defp too_young?(date), do: Date.diff(Date.utc_today(), date) < 16 * 365
  defp too_old_to_believe?(date), do: Date.diff(Date.utc_today(), date) > 110 * 365
end
