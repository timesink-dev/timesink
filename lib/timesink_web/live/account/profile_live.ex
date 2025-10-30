defmodule TimesinkWeb.Account.ProfileLive do
  use TimesinkWeb, :live_view

  import Ecto.Query
  alias Timesink.{Repo}
  alias Timesink.Account.{User, Profile}

  # /u/@username -> param arrives like "@aaron"
  def mount(%{"profile_username" => raw}, _session, socket) do
    username =
      raw
      |> to_string()
      |> String.trim()
      |> String.trim_leading("@")

    user =
      from(u in User,
        where: fragment("LOWER(?) = LOWER(?)", u.username, ^username),
        join: p in assoc(u, :profile),
        # ← no :location here
        preload: [profile: [avatar: [:blob]]],
        limit: 1
      )
      |> Repo.one()

    case user do
      %User{} = user ->
        # is_me? = match?(%{id: ^user.id}, socket.assigns[:current_user])

        {:ok,
         socket
         |> assign(
           user: user,
           profile: user.profile

           #  is_me?: is_me?
         )}

      nil ->
        {:ok, assign(socket, not_found: true)}
    end
  end

  def render(%{not_found: true} = assigns) do
    ~H"""
    <section class="px-4 md:px-6 py-16">
      <div class="max-w-3xl mx-auto text-center">
        <h1 class="text-xl md:text-2xl font-semibold text-mystery-white">Member not found</h1>
        <p class="mt-3 text-zinc-400">
          We couldn't find that profile. Check the handle and try again.
        </p>
        <.link navigate={~p"/"} class="inline-block mt-6 text-neon-blue-lightest hover:opacity-80">
          Back to home
        </.link>
      </div>
    </section>
    """
  end

  def render(assigns) do
    ~H"""
    <section id="profile-page" class="px-4 md:px-6 pb-16">
      <!-- Header / Cover -->
      <div class="mx-auto max-w-5xl mt-24">
        <!-- Avatar overlaps the banner -->
        <div class="px-4 md:px-6 w-full rounded-2xl bg-gradient-to-br from-zinc-900 via-backroom-black to-zinc-900
            ring-1 ring-inset ring-zinc-800/60 overflow-hidden">
          <div class="flex items-start gap-3 py-4">
            <div class="shrink-0">
              <%= if avatar_url(@profile) do %>
                <img
                  src={avatar_url(@profile)}
                  alt={"#{display_name(@user)} avatar"}
                  class={["rounded-full object-cover ring-1 ring-zinc-700", avatar_size()]}
                />
              <% else %>
                <span class={[
                  "inline-flex items-center justify-center rounded-full bg-zinc-700 text-lg md:text-xl font-semibold text-mystery-white ring-1 ring-zinc-700",
                  avatar_size()
                ]}>
                  {initials(@user)}
                </span>
              <% end %>
            </div>

            <div class="pb-1">
              <h1 class={["font-semibold text-mystery-white leading-tight pb-1.5", h1_size()]}>
                {display_name(@user)}
              </h1>
              <div class="mt-0.5 flex flex-wrap items-center gap-4 text-[13px] md:text-sm leading-tight">
                <span class="text-zinc-400">@{@user.username}</span>
                <span
                  :if={location_label(@profile)}
                  class="inline-flex items-center gap-1 rounded-full bg-zinc-800/70 px-2.5 py-0.5 text-zinc-300 ring-1 ring-zinc-700 text-xs"
                >
                  <.icon name="hero-map-pin" class="h-3.5 w-3.5" /> {location_label(@profile)}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Body -->
      <div class="mx-auto max-w-5xl mt-5 grid grid-cols-1 md:grid-cols-[1.2fr,2fr] gap-5">
        <section class="rounded-2xl bg-backroom-black/60 backdrop-blur ring-1 ring-zinc-800">
          <div class={[card_pad_x(), "py-3 border-b border-zinc-800"]}>
            <h2 class="text-base font-medium text-mystery-white">About</h2>
          </div>
          <div class={[card_pad_x(), card_pad_y()]}>
            <p
              :if={@profile && present?(@profile.bio)}
              class="text-zinc-300 leading-relaxed text-[15px]"
            >
              {@profile.bio}
            </p>
            <p :if={not (@profile && present?(@profile.bio))} class="text-zinc-500 text-[15px]">
              No bio yet.
            </p>

            <dl class="mt-5 space-y-2.5 text-[13px] md:text-sm">
              <div :if={location_label(@profile)} class="flex items-start gap-2">
                <dt class="text-zinc-500 w-20">Location</dt>
                <dd class="text-zinc-300">{location_label(@profile)}</dd>
              </div>
              <div class="flex items-start gap-2">
                <dt class="text-zinc-500 w-20">Member</dt>
                <dd class="text-zinc-300">Since {Calendar.strftime(@user.inserted_at, "%b %Y")}</dd>
              </div>
            </dl>
          </div>
        </section>

        <section class="rounded-2xl bg-backroom-black/60 backdrop-blur ring-1 ring-zinc-800">
          <div class={[
            card_pad_x(),
            "py-3 border-b border-zinc-800 flex items-center justify-between"
          ]}>
            <h2 class="text-base font-medium text-mystery-white">Activity</h2>
          </div>
          <div class={[card_pad_x(), "py-6"]}>
            <p class="text-zinc-500 text-[15px]">No recent activity yet.</p>
          </div>
        </section>
      </div>
    </section>
    """
  end

  # --- helpers ---------------------------------------------------------------

  defp avatar_url(%Profile{avatar: nil}), do: nil
  defp avatar_url(%Profile{avatar: att}) when not is_nil(att), do: Profile.avatar_url(att)
  defp avatar_url(_), do: nil

  defp display_name(%{first_name: f, last_name: l}) do
    [to_s(f), to_s(l)]
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> "User"
      parts -> Enum.join(parts, " ")
    end
  end

  defp location_label(%Profile{location: nil}), do: nil

  defp location_label(%Profile{location: loc}) do
    label =
      cond do
        to_s(loc.label) != "" -> loc.label
        to_s(loc.locality) != "" and to_s(loc.country) != "" -> "#{loc.locality}, #{loc.country}"
        to_s(loc.locality) != "" -> loc.locality
        to_s(loc.country) != "" -> loc.country
        true -> nil
      end

    if present?(label), do: label, else: nil
  end

  defp initials(%{first_name: fnm, last_name: lnm}) do
    f = fnm |> to_s() |> String.first() || ""
    l = lnm |> to_s() |> String.first() || ""

    case String.upcase(f <> l) do
      "" -> "?"
      s -> s
    end
  end

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?(s) when is_binary(s), do: String.trim(s) != ""
  defp present?(_), do: true

  defp to_s(nil), do: ""
  defp to_s(v) when is_binary(v), do: v
  defp to_s(v), do: to_string(v)

  defp avatar_size(), do: "w-14 h-14 md:w-16 md:h-16"
  defp h1_size(), do: "text-lg md:text-xl"
  defp card_pad_x(), do: "px-5 md:px-6"
  defp card_pad_y(), do: "py-4"
end
