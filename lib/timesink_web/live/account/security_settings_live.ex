defmodule TimesinkWeb.Accounts.SecuritySettingsLive do
  alias Timesink.Accounts.User
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <section class="w-1/2 mx-auto">
      <div class="my-8">
        <.back navigate={~p"/me"}></.back>
        <h2 class="text-[1.5rem] font-semibold text-mystery-white flex justify-center">
          Security settings
        </h2>
      </div>
      <div>
        <.simple_form
          as="security"
          for={@security_form}
          phx-submit="save"
          class="mt-8 mb-8 w-full mx-auto"
        >
          <div class="w-full flex flex-col gap-y-2">
            <.input
              label="Old Password"
              field={@security_form[:old_password]}
              type="password"
              placeholder="Password"
              input_class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              class="w-full"
            />
            <.input
              label="New Password"
              field={@security_form[:new_password]}
              type="password"
              placeholder="Password"
              input_class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              class="w-full"
            />
            <.input
              label="Confirm Password"
              field={@security_form[:confirm_password]}
              type="password"
              placeholder="Password"
              input_class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              class="w-full"
            />
          </div>
          <:actions>
            <.button
              phx-disable-with="Updating..."
              class="w-full text-backroom-black font-semibold mt-4 px-6 py-4 hover:bg-neon-blue-lightest flex items-center justify-center"
            >
              Update password
            </.button>
          </:actions>
        </.simple_form>
      </div>
      <div class="mt-96">
        <h2 class="w-full bg-neon-red-light bg-opacity-10 px-12 py-6 border-[0.4px] border-neon-red-light rounded text-neon-red-light text-xl font-brand">
          Danger zone!
        </h2>
        <button class="mt-6 focus-none py-4 px-16 bg-backroom-black text-neon-red-light font-semibold border-neon-red-light border-[1px]">
          Delete account
        </button>
      </div>
    </section>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, user} = Timesink.Accounts.get_me()

    changeset =
      User.changeset(user)

    {:ok, assign(socket, security_form: to_form(changeset))}
  end
end
