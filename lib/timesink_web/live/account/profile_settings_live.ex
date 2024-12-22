defmodule TimesinkWeb.Accounts.ProfileSettingsLive do
  alias Timesink.Accounts
  alias Timesink.Accounts.User
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <section class="w-1/2 mx-auto">
      <div class="my-8">
        <.back navigate={~p"/me"}></.back>
        <h2 class="text-[1.5rem] font-semibold text-mystery-white flex justify-center">
          Profile settings
        </h2>
      </div>
      <div>
        <.simple_form as="user" for={@account_form} phx-submit="save" class="mt-8 mb-8 w-full mx-auto">
          <div class="flex flex-col justify-center items-center">
            <label class="mb-2">Profile image</label>
            <img src={@user.profile.avatar_url} alt="Profile picture" class="rounded-full w-24 h-24" />
          </div>
          <div>
            <.input
              label="Username"
              field={@account_form[:username]}
              placeholder="Username"
              class="w-full"
              value={"@#{@user.username}"}
              input_class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
            />
            <!-- Profile Nested Fields -->
            <.inputs_for :let={pf} field={@account_form[:profile]}>
              <.input type="hidden" field={pf[:id]} value={@user.profile.id} />
              <.input
                field={pf[:bio]}
                placeholder="Tell the world about yourself"
                type="textarea"
                input_class="w-full px-4 py-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
                label="Bio"
                value={@user.profile.bio}
              />
            </.inputs_for>
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

  def mount(_params, _session, socket) do
    # later we will simply set the user as the @current_user from authenticated live plug - so no need to fetch it here
    # i.e. user: socket.assigns.current_user
    {:ok, user} = Timesink.Accounts.get_me()

    changeset =
      User.changeset_update(user)

    socket =
      socket
      |> assign(user: user, account_form: to_form(changeset))

    {:ok, socket}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    with {:ok, updated_user} <- Accounts.update_me(socket.assigns.user, user_params) do
      socket =
        socket
        |> assign(user: updated_user, account_form: to_form(User.changeset_update(updated_user)))
        |> put_flash(:info, "Profile updated successfully")

      {:noreply, socket}
    end
  end
end
