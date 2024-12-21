defmodule TimesinkWeb.ProfileFormComponent do
  alias Timesink.Accounts
  alias Timesink.Accounts.User
  use TimesinkWeb, :live_component

  def render(assigns) do
    ~H"""
    <section class="w-full mx-auto">
      <div class="mb-8 flex justify-between">
        <button phx-click="back">
          <.icon name="hero-arrow-left" class=" h-5 w-5 opacity-100 group-hover:opacity-70 px-2 py-2" />
        </button>
        <h2 class="text-[2rem] font-semibold text-mystery-white">Profile</h2>
      </div>
      <div class="flex gap-x-12 justify-start items-end">
        <div>
          <label class="mb-2">Profile image</label>
          <img src={@user.profile.avatar_url} alt="Profile picture" class="rounded-full w-24 h-24" />
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

  def mount(socket) do
    changeset =
      User.changeset_update(%User{})

    {:ok, assign(socket, account_form: to_form(changeset))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    with {:ok, updated_user} <- Accounts.update_me(socket.assigns.user, user_params) do
      send(self(), {:user_updated, updated_user})

      socket =
        socket
        |> assign(user: updated_user, account_form: to_form(User.changeset_update(updated_user)))
        |> put_flash!(:info, "Account updated successfully.")

      {:noreply, socket}
    end
  end
end
