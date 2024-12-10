defmodule TimesinkWeb.Accounts.AccountLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="user" class="relative">
      <div class="absolute -left-56 top-16 flex flex-col gap-y-2">
        <button
          phx-click="profile"
          class={[
            "rounded w-full text-mystery-white font-semibold mt-4 px-12 py-2.5 flex items-center justify-center",
            @active_tab === :profile && "bg-neon-blue-lightest text-black focus-none"
          ]}
        >
          Profile
        </button>
        <button
          class={[
            "rounded w-full text-mystery-white font-semibold mt-4 px-12 py-2.5 flex items-center justify-center",
            @active_tab === :security && "bg-neon-blue-lightest text-black focus-none"
          ]}
          phx-click="security"
        >
          Security
        </button>
        <button
          phx-click="activity"
          class={[
            "rounded w-full text-mystery-white font-semibold mt-4 px-12 py-2.5 flex items-center justify-center",
            @active_tab === :activity && "bg-neon-blue-lightest text-black focus-none"
          ]}
        >
          Activity
        </button>
      </div>
      <div class="user-section">
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
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, user} = Timesink.Accounts.get_me()
    # {:ok, %{user: user}} ->
    {:ok, assign(socket, user: user, active_tab: :profile)}

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
end
