defmodule TimesinkWeb.Account.ProfileLive do
  use TimesinkWeb, :live_view

  import Ecto.Query
  alias Timesink.{Repo}
  alias Timesink.Account.{User, Profile}

  # @avatar_size "w-28 h-28 md:w-32 md:h-32"

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
      <div class="relative mx-auto max-w-5xl">
        <div class="h-36 md:h-44 w-full rounded-2xl bg-gradient-to-br from-zinc-900 via-backroom-black to-zinc-900
                 ring-1 ring-inset ring-zinc-800/60 overflow-hidden">
          <!-- Soft vignette -->
          <div
            class="absolute inset-0 pointer-events-none"
            style="background: radial-gradient(110% 60% at 50% 100%, rgba(12,12,12,0) 40%, rgba(12,12,12,0.7) 100%);"
          >
          </div>
        </div>
        
    <!-- Avatar overlaps the banner -->
        <div class="px-4 md:px-8">
          <div class="relative -mt-12 md:-mt-16 flex items-end gap-4">
            <div class="relative shrink-0">
              <%= if avatar_url(@profile) do %>
                <img
                  src={avatar_url(@profile)}
                  alt={"#{display_name(@user)} avatar"}
                  class={["rounded-full object-cover ring-2 ring-zinc-700"]}
                />
              <% else %>
                <span class={[
                  "inline-flex items-center justify-center rounded-full bg-zinc-700 text-3xl md:text-4xl font-semibold text-mystery-white ring-2 ring-zinc-700"
                ]}>
                  {initials(@user)}
                </span>
              <% end %>
            </div>
            
    <!-- Name + username + location -->
            <div class="pb-2">
              <h1 class="text-2xl md:text-3xl font-semibold text-mystery-white">
                {display_name(@user)}
              </h1>
              <div class="mt-1 flex flex-wrap items-center gap-2 text-sm">
                <span class="text-zinc-400">@{@user.username}</span>
                <span
                  :if={location_label(@profile)}
                  class="inline-flex items-center gap-1 rounded-full bg-zinc-800/70 px-2 py-0.5 text-zinc-300 ring-1 ring-zinc-700"
                >
                  <.icon name="hero-map-pin" class="h-4 w-4" /> {location_label(@profile)}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Body -->
      <div class="mx-auto max-w-5xl mt-6 grid grid-cols-1 md:grid-cols-[1.2fr,2fr] gap-6">
        <!-- Left: About card -->
        <section class="rounded-2xl bg-backroom-black/60 backdrop-blur ring-1 ring-zinc-800">
          <div class="px-6 py-5 border-b border-zinc-800">
            <h2 class="text-lg font-medium text-mystery-white">About</h2>
          </div>
          <div class="px-6 py-5">
            <p :if={@profile && present?(@profile.bio)} class="text-zinc-300 leading-relaxed">
              {@profile.bio}
            </p>
            <p :if={not (@profile && present?(@profile.bio))} class="text-zinc-500">
              No bio yet.
            </p>

            <dl class="mt-6 space-y-3 text-sm">
              <div :if={location_label(@profile)} class="flex items-start gap-2">
                <dt class="text-zinc-500 w-24">Location</dt>
                <dd class="text-zinc-300">{location_label(@profile)}</dd>
              </div>
              <div class="flex items-start gap-2">
                <dt class="text-zinc-500 w-24">Member</dt>
                <dd class="text-zinc-300">
                  <!-- If you track inserted_at on users, you can show a real date -->
                  Since
                  {Calendar.strftime(@user.inserted_at, "%b %Y")}
                </dd>
              </div>
            </dl>
          </div>
        </section>
        
    <!-- Right: Activity / Films / Comments -->
        <section class="rounded-2xl bg-backroom-black/60 backdrop-blur ring-1 ring-zinc-800">
          <div class="px-6 py-5 border-b border-zinc-800 flex items-center justify-between">
            <h2 class="text-lg font-medium text-mystery-white">Activity</h2>
            <!-- Future: tabs for "Films", "Comments", "Likes" -->
            <!-- <div class="text-sm text-zinc-400">Films · Comments</div> -->
          </div>

          <div class="px-6 py-8">
            <p class="text-zinc-500">No recent activity yet.</p>
            <!--
            TODO: Replace with a list like:
            <ul class="space-y-4">
              <li class="flex items-start gap-3">
                <img class="h-10 w-10 rounded object-cover" src={poster_url} />
                <div>
                  <p class="text-zinc-300"><.link navigate={~p"/films/#{film.id}"} class="hover:underline">{film.title}</.link></p>
                  <p class="text-sm text-zinc-500">Added to favorites · 2h ago</p>
                </div>
              </li>
            </ul>
            -->
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
end
