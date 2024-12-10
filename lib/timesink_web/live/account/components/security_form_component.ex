defmodule TimesinkWeb.SecurityFormComponent do
  alias Timesink.Accounts.User
  use TimesinkWeb, :live_component

  def render(assigns) do
    ~H"""
    <section class="mt-16">
      <div class="mb-8">
        <h2 class="text-[2rem] font-semibold text-mystery-white">Security</h2>
        <span> Manage your account security settings </span>
      </div>
      <div>
        <.simple_form
          as="security"
          phx-target={@myself}
          for={@security_form}
          phx-submit="save"
          class="mt-8 mb-8 w-2/3"
        >
          <div class="w-full flex flex-col gap-y-2">
            <.input
              label="Old Password"
              field={@security_form[:old_password]}
              type="password"
              placeholder="Password"
              class="w-full"
            />
            <.input
              label="New Password"
              field={@security_form[:new_password]}
              type="password"
              placeholder="Password"
              class="w-full"
            />
            <.input
              label="Confirm Password"
              field={@security_form[:confirm_password]}
              type="password"
              placeholder="Password"
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
    </section>
    """
  end

  def mount(socket) do
    changeset =
      User.edit_changeset(%User{})

    {:ok, assign(socket, security_form: to_form(changeset))}
  end
end
