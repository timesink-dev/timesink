defmodule TimesinkWeb.ProfileFormComponent do
  alias Timesink.Accounts.Profile
  alias Timesink.Accounts.User
  use TimesinkWeb, :live_component

  def render(assigns) do
    ~H"""
    <section class="mt-16">
      <div class="mb-8">
        <h2 class="text-[2rem] font-semibold text-mystery-white">Account</h2>
        <span> Manage your personal account and profile settings </span>
      </div>
      <div class="flex gap-x-12 justify-start items-end">
        <div>
          <label class="mb-2">Profile image</label>
          <img src={@user.profile.avatar_url} alt="Profile picture" class="rounded-full w-24 h-24" />
        </div>
        <div>
          <label class="mb-2">Bio</label>
          <div class="rounded border-[0.1px] border-mystery-white px-12 py-8">
            {@user.profile.bio}
          </div>
        </div>
      </div>
      <div>
        <.simple_form
          as="account"
          phx-target={@myself}
          for={@account_form}
          phx-submit="save"
          class="mt-8 mb-8 w-2/3"
        >
          <div>
            <label class="mb-2">Bio</label>
            <.input
              field={@account_form[:bio]}
              type="text"
              class="rounded border-[0.1px] border-mystery-white px-12 py-8"
              label="Bio"
              value={@user.profile.bio}
            />
            <.input
              disabled
              field={@account_form[:locality]}
              class="px-4 py-2"
              label="Location"
              value={@user.profile.location.locality <> ", " <> to_string(@user.profile.location.country)}
            />
          </div>
          <div class="w-full flex flex-col gap-y-2">
            <.input
              label="First name"
              field={@account_form[:first_name]}
              placeholder="First name"
              class="w-full"
              value={@user.first_name}
              input_class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
            />
            <.input
              label="Last name"
              field={@account_form[:last_name]}
              value={@user.last_name}
              placeholder="Last name"
              class="w-full"
              input_class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
            />

            <.input
              label="Email"
              field={@account_form[:email]}
              value={@user.email}
              type="email"
              placeholder="Enter your email"
              class="md:relative"
              error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
              input_class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
            />
          </div>
          <:actions>
            <.button
              phx-disable-with="Updating..."
              class="w-full text-backroom-black font-semibold mt-4 px-6 py-4 hover:bg-neon-blue-lightest focus:ring-2 focus:bg-neon-blue-light flex items-center justify-center"
            >
              Update
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

    {:ok, assign(socket, account_form: to_form(changeset))}
  end

  def handle_event("save", %{"user" => account_params}, socket) do
    User.update!(socket.assigns.user, account_params)
    Profile.update!(socket.assigns.user.profile, account_params)

    socket
    |> assign(:form, to_form(User.edit_changeset(socket.assigns.user, account_params)))
    |> put_flash!(
      :info,
      "Successfully updated your account"
    )

    {:noreply, socket}
  end
end
