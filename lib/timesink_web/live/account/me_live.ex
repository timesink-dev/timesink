defmodule TimesinkWeb.Accounts.MeLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="user" class="sm:flex sm:justify-center sm:gap-x-32 sm:items-start sm:mt-16">
      <div class="sm:ml-16 md:ml-32 sm:flex sm:flex-col gap-y-6 mt-24 basis-1/6">
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
        </button>
      </div>
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
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, user} = Timesink.Accounts.get_me()
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

  def handle_info({:user_updated, updated_user}, socket) do
    {:noreply, assign(socket, user: updated_user)}
  end
end
