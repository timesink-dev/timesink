defmodule TimesinkWeb.JoinLive do
  use TimesinkWeb, :live_view
  alias Timesink.Waitlist.Applicant

  def mount(_params, _session, socket) do
    changeset =
      Applicant.changeset(%Timesink.Waitlist.Applicant{})

    socket = assign(socket, form: to_form(changeset))
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-xl mt-24 w-full">
      <span class="flex flex-col -space-y-2.5 font-brand items-center">
        <p class="text-[3rem] leading-10 tracking-tighter">
          TimeSink
        </p>
        <p class="pl-4 text-[2.6rem]">
          Presents
        </p>
      </span>
      <h2 class="uppercase text-[2rem] mt-20 mb-2 tracking-tighter items-center">
        Welcome to the show.
      </h2>
      <div class="flex flex-col gap-y-2">
        <p>
          <b>While the world outside buzzes with the chaos of endless content</b>, we sift through it all to bring you a collection of hand-picked cinematic gems made by the filmmakers of today.
        </p>
      </div>
      <.simple_form
        for={@form}
        phx-change="validate"
        phx-submit="save"
        class="mt-8 mb-8 md:flex md:justify-center gap-x-4 h-full md:items-end"
      >
        <div class="w-full flex flex-col gap-y-2">
          <div class="flex gap-x-2">
            <.input
              field={@form[:first_name]}
              placeholder="First name"
              class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
            />
            <.input
              field={@form[:last_name]}
              placeholder="Last name"
              class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
            />
          </div>
          <.input
            field={@form[:email]}
            type="email"
            placeholder="Enter your email"
            class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
          />
        </div>
        <%!-- to do: why is this messing with my css styling of button below ? <:actions> --%>
        <.button
          phx-disable-with="Joining..."
          color="primary"
          class="text-backroom-black font-semibold mt-4 w-full md:w-2/3 px-6 py-4 hover:bg-neon-blue-lightest focus:ring-2 focus:bg-neon-blue-light"
        >
          Join the Waitlist
        </.button>
        <%!-- </:actions> --%>
      </.simple_form>
    </div>
    """
  end

  def handle_event("save", %{"applicant" => applicant_params}, socket) do
    case Timesink.Waitlist.join(applicant_params) do
      {:ok, _applicant} ->
        socket =
          assign(socket, :form, to_form(Applicant.changeset(%Timesink.Waitlist.Applicant{})))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
