defmodule TimesinkWeb.FilmSubmission.StepIntroComponent do
  use TimesinkWeb, :live_component

  alias Timesink.Films.FilmSubmission

  def update(assigns, socket) do
    data = assigns[:data] || %{}

    changeset =
      FilmSubmission.changeset(%{}, %{
        contact_name: Map.get(data, :contact_name, ""),
        contact_email: Map.get(data, :contact_email, "")
      })

    {:ok,
     assign(socket,
       form: to_form(changeset),
       data: data
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full max-w-md bg-backroom-black shadow-xl rounded-2xl p-8 text-white">
      <h2 class="text-2xl font-bold font-brand">Let’s begin</h2>
      <p class="text-gray-400 text-sm mt-2">
        Tell us how we can reach you about your submission.
      </p>

      <.simple_form
        for={@form}
        phx-submit="save_intro"
        phx-change="validate"
        phx-target={@myself}
        class="mt-6 space-y-4"
      >
        <.input
          type="text"
          field={@form[:contact_name]}
          label="Your name"
          placeholder="e.g. Alex Rivera"
          required
          input_class="w-full p-3 rounded text-mystery-white border-none"
        />

        <.input
          type="email"
          field={@form[:contact_email]}
          label="Email address"
          placeholder="you@example.com"
          required
          input_class="w-full p-3 rounded text-mystery-white border-none"
        />

        <:actions>
          <div class="mt-6">
            <.button color="primary" class="w-full py-3 text-lg">Continue</.button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("validate", %{"film_submission" => params}, socket) do
    changeset =
      %{}
      |> FilmSubmission.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save_intro", %{"film_submission" => params}, socket) do
    # changeset = FilmSubmission.changeset(%FilmSubmission{}, params)
    changeset = %{}

    if changeset.valid? do
      send(self(), {:update_user_data, %{params: params}})
      send(self(), {:go_to_step, :next})
      {:noreply, socket}
    else
      {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("go_back", _params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end
end
