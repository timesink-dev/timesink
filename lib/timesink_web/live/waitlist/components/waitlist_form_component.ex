defmodule TimesinkWeb.WaitlistFormComponent do
  use TimesinkWeb, :live_component

  alias Timesink.Waitlist.Applicant

  def mount(socket) do
    changeset = Applicant.changeset(%Applicant{})

    {:ok, assign(socket, form: to_form(changeset))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-backroom-black flex flex-col items-center justify-center px-4 pt-16 pb-24 space-y-6">
      <!-- Card Container -->
      <div class="w-full max-w-2xl rounded-2xl bg-backroom-black bg-opacity-70 border border-dark-theater-medium p-10">
        
    <!-- Logo / Tagline -->
        <div class="text-center mb-8">
          <a href={~p"/"}>
            <h1 class="text-4xl font-brand text-white tracking-tight leading-none">
              TimeSink <br /> Presents
            </h1>
          </a>
          <p class="text-sm text-mystery-white mt-2 max-w-lg mx-auto">
            We sift through the noise. You get the signal. <br />
            Access opens in carefully curated waves.
          </p>
        </div>
        
    <!-- Waitlist Form -->
        <.simple_form
          as="applicant"
          for={@form}
          phx-submit="save"
          phx-target={@myself}
          class="mt-8 mb-4 w-full md:flex md:justify-center gap-x-4 h-full md:items-end"
        >
          <div class="w-full flex flex-col gap-y-2">
            <div class="flex gap-x-2">
              <.input
                field={@form[:first_name]}
                placeholder="First name"
                class="w-full"
                input_class="w-full px-3 py-4 outline-width-0 rounded-lg text-mystery-white border-none focus:outline-none outline-none"
              />
              <.input
                field={@form[:last_name]}
                placeholder="Last name"
                class="w-full"
                input_class="w-full px-3 py-4 outline-width-0 rounded-lg text-mystery-white border-none focus:outline-none outline-none"
              />
            </div>
            <.input
              field={@form[:email]}
              type="email"
              placeholder="Enter your email"
              class="md:relative"
              error_class="md:absolute md:-bottom-12 md:left-0 md:items-center md:gap-1"
              input_class="w-full px-3 py-4 outline-width-0 rounded-lg text-mystery-white border-none focus:outline-none outline-none"
            />
          </div>
          <:actions>
            <.button
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

        <%!-- <div class="pt-4 text-center text-xs text-dark-theater-lightest">
          <p>
            Questions? <a href="mailto:support@timesinkpresents.com" class="text-brand hover:underline">Contact us</a>
          </p>
        </div> --%>
      </div>
      
    <!-- Status Block Outside Card -->
      <div class="text-center text-mystery-white text-sm space-y-1 max-w-lg px-4">
        <%= if @spots_remaining > 0 do %>
          <p>
            🎟️
            <strong class="text-mystery-white">
              {@spots_remaining} spot{if @spots_remaining > 1, do: "s"}
            </strong>
            remaining in this cohort
          </p>
          <p>
            Join <i>now</i> to secure your ticket!
          </p>
        <% else %>
          <p>
            You’re joining the queue for the next cohort of invites.
          </p>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("save", %{"applicant" => applicant_params}, socket) do
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
          |> Map.get(:email)
          |> Enum.at(0, "There was an error. Please try again.")

        socket =
          socket
          |> assign(:email, applicant_params["email"])
          |> assign(:form, to_form(%{changeset | action: :insert}))
          |> put_flash!(
            :error,
            error_message
          )

        {:noreply, socket}
    end
  end
end
