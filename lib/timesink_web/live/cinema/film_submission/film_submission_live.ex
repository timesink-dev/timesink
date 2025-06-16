defmodule TimesinkWeb.FilmSubmissionLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.FilmSubmission.{
    StepIntroComponent,
    StepFilmDetailsComponent,
    StepPaymentComponent,
    StepReviewAndSubmitComponent,
    StepConfirmationComponent
  }

  alias TimesinkWeb.Components.Stepper

  @step_order [
    :intro,
    :film_details,
    :payment,
    :confirmation
  ]
  @steps %{
    intro: StepIntroComponent,
    film_details: StepFilmDetailsComponent,
    payment: StepPaymentComponent,
    confirmation: StepConfirmationComponent
  }
  @initial_form_data %{
    contact_name: "",
    contact_email: "",
    title: "",
    synopsis: "",
    video_url: "",
    video_pw: "",
    submitted_by_id: nil,
    payment_id: nil
  }

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       steps: @steps,
       step: hd(@step_order),
       step_order: @step_order,
       data: @initial_form_data,
       current_user: socket.assigns[:current_user]
     )}
  end

  def render(assigns) do
    ~H"""
    <section id="film-submission" class="relative min-h-screen px-6 md:px-12 py-16 md:py-24">
      <div class="flex flex-col-reverse md:flex-row items-center gap-6">
        <!-- Fixed-size Step Content Container -->
        <div class="w-full">
          <div class="min-h-[700px] transition-all duration-300">
            <.live_component
              module={Stepper}
              id="film-submission-form"
              steps={@steps}
              current_step={@step}
              data={@data}
            />
          </div>
        </div>
      </div>
      <!-- Step Dots -->
      <div class="mt-24 z-50 flex justify-center items-center space-x-4 cursor-pointer">
        <div class="flex space-x-3">
          <%= for step_key <- @step_order do %>
            <div
              phx-click="go_to_step"
              phx-value-step={step_key}
              class={[
                "w-4 h-4 rounded-full transition duration-200",
                step_key == @step && "bg-white",
                step_key != @step && "bg-gray-600 hover:bg-gray-400"
              ]}
            >
            </div>
          <% end %>
        </div>
      </div>
    </section>
    """
  end

  def handle_event("go_to_step", %{"step" => step}, socket) do
    step_atom = String.to_existing_atom(step)

    if step_atom in socket.assigns.step_order do
      {:noreply, assign(socket, step: step_atom)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:update_data, %{params: params}}, socket) do
    updated = Map.merge(socket.assigns.data, params)
    {:noreply, assign(socket, data: updated)}
  end

  # Step navigation logic
  defp determine_step(current_step, :next, step_order) do
    index = Enum.find_index(step_order, &(&1 == current_step)) || 0
    Enum.at(step_order, index + 1) || current_step
  end

  defp determine_step(current_step, :back, step_order) do
    index = Enum.find_index(step_order, &(&1 == current_step)) || 0
    Enum.at(step_order, max(index - 1, 0)) || current_step
  end

  defp determine_step(_current_step, step, _step_order) when is_atom(step), do: step
end
