defmodule TimesinkWeb.Accounts.MeLive do
  use TimesinkWeb, :live_view
  alias TimesinkWeb.Utils

  def render(assigns) do
    ~H"""
    <section id="user" class={["w-full", @active_tab != nil && "hidden"]}>
      <span class="text-sm text-dark-theater-lightest">
        {@user.username} joined {Utils.format_date(@user.inserted_at)}
      </span>
      <h2 class="my-4">Account</h2>
      <div id="account" class="rounded-lg bg-zinc-300/10 px-4 py-2 w-full inset-0">
        <div
          phx-click="profile"
          class="cursor-pointer py-4 border-b-[1px] border-zinc-600/20 flex justify-start items-center gap-x-2"
        >
          <span class="rounded-lg px-2 py-2 flex items-center justify-center bg-zinc-500/10">
            <.icon
              name="hero-identification"
              class="bg-dark-theater-primary-light h-4 w-4 opacity-100 group-hover:opacity-70"
            />
          </span>
          <h3>Profile</h3>
        </div>
        <div phx-click="security" class="cursor-pointer py-4 flex justify-start items-center gap-x-2">
          <span class="rounded-lg px-2 py-2 flex items-center justify-center bg-zinc-500/10">
            <.icon
              name="hero-lock-closed"
              class="bg-dark-theater-primary-light h-4 w-4 opacity-100 group-hover:opacity-70 px-2 py-2"
            />
          </span>
          <h3>Security</h3>
        </div>
      </div>
      <h2 class="my-4">Activity</h2>
      <div id="activity" class="rounded-lg bg-zinc-300/10 inset-o px-4 py-2 w-full">
        <div
          phx-click="activity"
          class="cursor-pointer py-4 border-b-[1px]  border-zinc-600/20  flex justify-start items-center gap-x-2"
        >
          <span class="rounded-lg px-2 py-2 flex items-center justify-center bg-zinc-500/10">
            <.icon
              name="hero-bolt"
              class="bg-dark-theater-primary-light h-4 w-4 opacity-100 group-hover:opacity-70 px-2 py-2"
            />
          </span>
          <h3>Notifications</h3>
        </div>
        <div phx-click="activity" class="cursor-pointer py-4 flex justify-start items-center gap-x-2">
          <span class="rounded-lg px-2 py-2 flex items-center justify-center bg-zinc-500/10">
            <.icon
              name="hero-film"
              class="bg-dark-theater-primary-light h-4 w-4 opacity-100 group-hover:opacity-70 px-2 py-2"
            />
          </span>
          <h3>Film submissions</h3>
        </div>
      </div>
      <h2 class="my-4">Integrations</h2>
      <div id="tips" class="rounded-lg bg-zinc-300/10 inset-o px-4 py-2 w-full">
        <div phx-click="activity" class="cursor-pointer py-4 flex justify-start items-center gap-x-2">
          <span class="rounded-lg px-2 py-2 flex items-center justify-center bg-zinc-500/10">
            <.icon
              name="hero-currency-dollar"
              class="bg-dark-theater-primary-light h-4 w-4 opacity-100 group-hover:opacity-70 px-2 py-2"
            />
          </span>
          <h3>Tips</h3>
        </div>
      </div>
    </section>
    <div class="mt-8 sm:mt-0 account-info-section basis-5/6">
      <%= if @active_tab == :profile do %>
        <.live_component module={TimesinkWeb.ProfileFormComponent} id="profile_form" user={@user} />
      <% end %>
      <%= if @active_tab == :security do %>
        <.live_component module={TimesinkWeb.SecurityFormComponent} id="security_form" user={@user} />
      <% end %>
      <%= if @active_tab == :activity do %>
        <.live_component module={TimesinkWeb.ActivityComponent} id="activity" />
      <% end %>
    </div>
    <%!-- <div id="user" class="sm:flex sm:justify-center sm:gap-x-32 sm:items-start sm:mt-16"> --%>
    <%!-- <div class="sm:ml-16 md:ml-32 sm:flex sm:flex-col gap-y-6 mt-24 basis-1/6">
        <button
          phx-click="profile"
          class={[
            "rounded-sm w-full font-semibold px-12 py-2.5 flex items-center justify-center bg-backroom-black border-[0.5px] border-dark-theater-light hover:border-dark-theater-lightest",
            @active_tab === :profile && "bg-backroom border-mystery-white hover:border-mystery-white"
          ]}
        >
          Profile
        </button>
        <button
          class={[
            "rounded-sm w-full font-semibold px-12 py-2.5 flex items-center justify-center bg-backroom-black border-[0.5px] border-dark-theater-light hover:border-dark-theater-lightest",
            @active_tab === :security && "bg-backroom border-mystery-white hover:border-mystery-white"
          ]}
          phx-click="security"
        >
          Security
        </button>
        <button
          phx-click="activity"
          class={[
            "rounded-sm w-full font-semibold px-12 py-2.5 flex items-center justify-center bg-backroom-black border-[0.5px] border-dark-theater-light hover:border-dark-theater-lightest",
            @active_tab === :activity && "bg-backroom border-mystery-white hover:border-mystery-white"
          ]}
        >
          Activity
        </button> --%>
    <%!-- </div> --%>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, user} = Timesink.Accounts.get_me()
    {:ok, assign(socket, user: user, active_tab: nil)}

    # {:error, _} ->
    #   {:error, socket}
  end

  def handle_event("profile", _params, socket) do
    {:noreply, assign(socket, active_tab: :profile)}
  end

  def handle_event("security", _params, socket) do
    {:noreply, assign(socket, active_tab: :security)}
  end

  def handle_event("activity", _params, socket) do
    {:noreply, assign(socket, active_tab: :activity)}
  end

  def handle_event("back", _params, socket) do
    socket = assign(socket, active_tab: nil)
    {:noreply, socket}
  end

  def handle_info({:user_updated, updated_user}, socket) do
    {:noreply, assign(socket, user: updated_user)}
  end
end
