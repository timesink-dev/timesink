defmodule TimesinkWeb.Accounts.AccountLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="user" class="relative">
      <div class="absolute -left-56 top-16 flex flex-col gap-y-4">
        <button class="rounded w-full text-backroom-black font-semibold mt-4 px-12 py-2.5 bg-neon-blue-lightest focus:ring-2 focus:bg-neon-blue-light flex items-center justify-center">
          Profile
        </button>
        <button class="text-mystery-white rounded w-full text-backroom-black font-semibold mt-4 px-12 py-2.5  focus:ring-2 focus:bg-neon-blue-light flex items-center justify-center">
          Security
        </button>
        <button class="text-mystery-white rounded w-full text-backroom-black font-semibold mt-4 px-12 py-2.5 focus:ring-2 focus:bg-neon-blue-light flex items-center justify-center">
          Activity
        </button>
      </div>
      <div class="user-section">
        <.live_component
          id="account_form"
          module={TimesinkWeb.AccountFormComponent}
          user={@user}
          profile={@profile}
        />
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    case Timesink.Accounts.get_me() do
      {:ok, %{user: user, profile: profile}} ->
        {:ok, assign(socket, user: user, profile: profile)}

      {:error, _} ->
        {:error, socket}
    end
  end
end
