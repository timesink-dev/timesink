defmodule TimesinkWeb.WaitlistFormComponent do
  use TimesinkWeb, :live_component

  alias Timesink.Waitlist.Applicant

  def mount(socket) do
    changeset = Applicant.changeset(%Applicant{})

    {:ok, assign(socket, form: to_form(changeset))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="py-2.5 text-center">
        <.simple_form
          as="applicant"
          for={@form}
          phx-submit="save"
          phx-target={@myself}
          class="mt-8 mb-8 w-full md:flex md:justify-center gap-x-4 h-full md:items-end"
        >
          <div class="w-full flex flex-col gap-y-2">
            <div class="flex gap-x-2">
              <.input
                field={@form[:first_name]}
                placeholder="First name"
                class="w-full"
                input_class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              />
              <.input
                field={@form[:last_name]}
                placeholder="Last name"
                class="w-full"
                input_class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              />
            </div>
            <.input
              field={@form[:email]}
              type="email"
              placeholder="Enter your email"
              class="md:relative"
              error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
              input_class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
            />
          </div>
          <:actions>
            <.button
              color="primary"
              phx-disable-with="Joining..."
              class="w-full text-backroom-black font-semibold mt-4 px-6 py-4 hover:bg-neon-blue-lightest focus:ring-2 focus:bg-neon-blue-light flex items-center justify-center"
            >
              <%= if @joined do %>
                <.icon name="hero-check-circle-mini" class="mt-0.5 h-5 w-5 mr-2 flex-none" />
                You’re on the List!
              <% else %>
                Join the Waitlist
              <% end %>
            </.button>
          </:actions>
        </.simple_form>
        <%= if @spots_remaining > 0 do %>
          <p>Access is released by luck in limited drops</p>
        <% else %>
          <p>Reserve your place now for the next drop...</p>
        <% end %>
        <p>
          <strong>{if @spots_remaining == 0, do: "No", else: @spots_remaining}</strong> {if @spots_remaining ==
                                                                                              1,
                                                                                            do:
                                                                                              "spot",
                                                                                            else:
                                                                                              "spots"} remaining
        </p>
      </div>
    </div>
    """
  end

  def handle_event("save", %{"applicant" => applicant_params}, socket) do
    IO.inspect(applicant_params, label: "applicant params")

    case Timesink.Waitlist.join(applicant_params) do
      {:ok, _applicant} ->
        send(self(), :applicant_joined)

        socket =
          socket
          |> assign(:form, to_form(Applicant.changeset(%Applicant{})))
          |> put_flash!(
            :info,
            "Stay tuned for your official invite. 🎉"
          )

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message =
          changeset
          |> Ecto.Changeset.traverse_errors(&translate_error/1)
          |> Map.get(:email, [])
          |> Enum.at(0, "An error occurred. Please try again.")

        socket =
          socket
          |> assign(:email, applicant_params["email"])
          |> assign(:form, to_form(changeset))
          |> put_flash!(:error, error_message)

        {:noreply, socket}
    end
  end
end
