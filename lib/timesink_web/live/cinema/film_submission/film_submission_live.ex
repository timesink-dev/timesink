defmodule TimesinkWeb.FilmSubmissionLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.FilmSubmission.{
    StepIntroComponent,
    StepFilmDetailsComponent,
    StepPaymentComponent
  }

  alias TimesinkWeb.Components.Stepper

  @step_order [
    :intro,
    :film_details,
    :payment
  ]
  @steps %{
    intro: StepIntroComponent,
    film_details: StepFilmDetailsComponent,
    payment: StepPaymentComponent
  }

  @step_display_names %{
    intro: "About",
    film_details: "Film info",
    payment: "Payment"
  }

  @initial_form_data %{
    contact_name: "",
    contact_email: "",
    title: "",
    year: nil,
    duration_min: nil,
    synopsis: "",
    video_url: "",
    video_pw: "",
    user: nil
  }

  def mount(_params, _session, socket) do
    form_data = Map.put(@initial_form_data, :user, socket.assigns[:current_user])

    {:ok,
     socket
     |> assign(
       steps: @steps,
       step: hd(@step_order),
       step_order: @step_order,
       step_display_names: @step_display_names,
       data: form_data,
       complete_film_details: film_details_complete?(form_data)
     )
     |> update_navigation_assigns()}
  end

  def render(assigns) do
    ~H"""
    <section
      id="film-submission"
      class="relative h-[100vh] px-6 md:px-12 py-16 md:py-24 flex flex-col justify-between"
    >
      <div class="flex flex-col-reverse md:flex-row items-center gap-6">
        <div class="w-full">
          <div class="min-h-[calc(100vh-200px)] max-h-[calc(100vh-200px)] overflow-auto">
            <.live_component
              module={Stepper}
              id="film-submission-form"
              steps={@steps}
              current_step={@step}
              data={@data}
              current_user={@current_user}
            />
          </div>
        </div>
      </div>

    <!-- Step Navigation + Dots -->
      <div class="w-full mt-12 md:mt-2 max-w-5xl mx-auto px-4 mb-12 py-6">
        <div class="flex flex-col sm:flex-row justify-between items-center gap-4">
          <!-- Prev button -->
          <%= unless @step == hd(@step_order) do %>
            <button
              type="button"
              phx-click={JS.push("go_to_step", value: %{step: "back"})}
              class="text-md text-white hover:text-gray-300"
            >
              &larr; Prev ({@step_display_names[@prev_step]})
            </button>
          <% end %>

    <!-- Dots -->
          <div class="flex space-x-3 justify-center">
            <%= for step_key <- @step_order do %>
              <% is_clickable = step_key != :payment || @complete_film_details %>
              <%= if is_clickable do %>
                <div
                  phx-click="go_to_step"
                  phx-value-step={step_key}
                  class={[
                    "w-4 h-4 rounded-full transition duration-200 cursor-pointer",
                    step_key == @step && "bg-white",
                    step_key != @step && "bg-gray-600 hover:bg-gray-400"
                  ]}
                />
              <% else %>
                <div class="w-4 h-4 rounded-full bg-gray-700 opacity-40" />
              <% end %>
            <% end %>
          </div>

    <!-- Next button -->
          <%= unless @step == List.last(@step_order) do %>
            <% can_advance = @next_step != :payment || @complete_film_details %>

            <button
              type="button"
              phx-click={JS.push("go_to_step", value: %{step: "next"})}
              class={[
                "text-md",
                can_advance && "text-white hover:text-gray-300",
                !can_advance && "text-gray-600 cursor-not-allowed"
              ]}
              disabled={!can_advance}
            >
              Next ({@step_display_names[@next_step]}) &rarr;
            </button>
          <% end %>
        </div>
      </div>
    </section>
    """
  end

  def handle_params(%{"step" => step_param}, _url, socket) do
    step_atom = String.to_existing_atom(step_param)

    cond do
      # Invalid step
      step_atom not in socket.assigns.step_order ->
        {:noreply, socket}

      # Prevent skipping to payment if film details aren't complete
      step_atom == :payment and not socket.assigns.complete_film_details ->
        {:noreply,
         socket
         |> assign(step: :film_details)
         |> update_navigation_assigns()
         |> push_patch(to: "/submit?step=film_details")}

      # Valid step and allowed
      true ->
        {:noreply,
         socket
         |> assign(step: step_atom)
         |> update_navigation_assigns()}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @spec handle_event(<<_::80>>, map(), any()) :: {:noreply, any()}
  def handle_event("go_to_step", %{"step" => step}, socket) do
    # Convert string key to atom
    step_atom = String.to_existing_atom(step)

    send(self(), {:go_to_step, step_atom})
    {:noreply, socket}
  end

  def handle_info({:update_film_submission_data, %{params: params}}, socket) do
    updated = Map.merge(socket.assigns.data, params)

    {:noreply,
     assign(socket,
       data: updated,
       complete_film_details: film_details_complete?(updated)
     )}
  end

  # Step navigation logic
  def handle_info({:go_to_step, direction}, socket) do
    new_step =
      determine_step(
        socket.assigns.step,
        direction,
        socket.assigns.step_order,
        socket.assigns.complete_film_details
      )

    {:noreply,
     socket
     |> assign(step: new_step)
     |> update_navigation_assigns()
     |> push_patch(to: "/submit?step=#{new_step}")}
  end

  defp update_navigation_assigns(socket) do
    index = Enum.find_index(socket.assigns.step_order, &(&1 == socket.assigns.step)) || 0
    prev_step = Enum.at(socket.assigns.step_order, index - 1)
    next_step = Enum.at(socket.assigns.step_order, index + 1)

    assign(socket,
      prev_step: prev_step,
      next_step: next_step
    )
  end

  defp determine_step(:film_details, :next, _step_order, false), do: :film_details

  defp determine_step(current_step, :next, step_order, _complete_film_details) do
    index = Enum.find_index(step_order, &(&1 == current_step)) || 0
    Enum.at(step_order, index + 1) || current_step
  end

  defp determine_step(current_step, :back, step_order, _),
    do:
      Enum.at(step_order, max(Enum.find_index(step_order, &(&1 == current_step)) - 1, 0)) ||
        current_step

  defp determine_step(_current_step, step, _step_order, _) when is_atom(step), do: step

  defp film_details_complete?(data) do
    Enum.all?([
      data["title"] not in [nil, ""],
      data["year"],
      data["duration_min"],
      data["synopsis"] not in [nil, ""],
      data["video_url"] not in [nil, ""]
    ])
  end
end
