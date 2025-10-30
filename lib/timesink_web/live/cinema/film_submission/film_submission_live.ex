defmodule TimesinkWeb.FilmSubmissionLive do
  use TimesinkWeb, :live_view

  alias Timesink.Cinema.Mail

  alias TimesinkWeb.FilmSubmission.{
    StepIntroComponent,
    StepFilmDetailsComponent,
    StepPaymentComponent
  }

  require Logger

  alias TimesinkWeb.Components.Stepper
  alias Timesink.Payment.BtcPay

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
    user: nil,
    payment_id: nil,
    stripe_client_secret: nil
  }

  def mount(_params, _session, socket) do
    socket = assign_new(socket, :stripe_client_secret, fn -> nil end)

    if connected?(socket) && is_nil(socket.assigns.stripe_client_secret) do
      Phoenix.PubSub.subscribe(Timesink.PubSub, "film_submission")
      send(self(), :create_payment_intent)
    end

    form_data = Map.put(@initial_form_data, :user, socket.assigns[:current_user])

    {:ok,
     socket
     |> assign(
       steps: @steps,
       step: hd(@step_order),
       step_order: @step_order,
       step_display_names: @step_display_names,
       data: form_data,
       complete_film_details: film_details_complete?(form_data),
       stripe_client_secret: nil,
       film_submission: nil
     )
     |> update_navigation_assigns()}
  end

  def render(assigns) do
    ~H"""
    <section
      id="film-submission"
      class="relative h-screen px-6 md:px-12 py-16 md:py-24 flex flex-col justify-between"
    >
      <div class="flex flex-col-reverse md:flex-row items-center gap-6">
        <div class="w-full">
          <div class="min-h-[calc(100vh-200px)] max-h-[calc(100vh-200px)] overflow-auto">
            <%= if !@film_submission do %>
              <.live_component
                id="film_submission_stepper"
                module={Stepper}
                steps={@steps}
                current_step={@step}
                data={@data}
                stripe_client_secret={@stripe_client_secret}
              />
            <% else %>
              <div class="w-full px-6">
                <div class="max-w-3xl mx-auto text-center space-y-10">
                  <!-- Success Icon -->
                  <div class="mx-auto w-20 h-20 rounded-full bg-green-600/10 border border-green-600 flex items-center justify-center">
                    <svg
                      class="w-10 h-10 text-green-400"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      viewBox="0 0 24 24"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                  
    <!-- Headline -->
                  <div>
                    <h2 class="text-3xl font-brand text-white">Your film has been submitted!</h2>
                    <p class="mt-2 text-gray-300 text-lg">
                      We’ve received your submission and sent a confirmation email to <span class="text-white font-semibold">{@film_submission.contact_email || ""}</span>.
                    </p>
                  </div>

                  <div class="bg-orange-400/2 border-[1px] border-orange-500 rounded-lg px-6 py-5 text-left relative overflow-hidden">
                    <div class="space-y-2 text-sm text-amber-100">
                      <div class="flex justify-between items-center">
                        <span class="font-semibold text-white">Film Title</span>
                        <span>{@film_submission.title || "Untitled Masterpiece"}</span>
                      </div>
                      <div class="flex justify-between items-start gap-4">
                        <span class="font-semibold text-white">Synopsis</span>
                        <span class="text-right">
                          {@film_submission.synopsis || "No synopsis provided."}
                        </span>
                      </div>
                      <div class="flex justify-between items-center">
                        <span class="font-semibold text-white">Private Video Link</span>
                        <span>{@film_submission.video_url || "Not provided"}</span>
                      </div>
                      <div class="flex justify-between items-center">
                        <span class="font-semibold text-white">Payment Ref</span>
                        <span>{@film_submission.payment_id}</span>
                      </div>
                    </div>
                  </div>
                  
    <!-- Next Steps -->
                  <div class="text-gray-400 text-sm">
                    Our programming team reviews every submission with care. If your work is selected, we’ll reach out with next steps.
                  </div>
                  
    <!-- Optional Share or CTA -->
                  <div class="mt-6">
                    <a
                      href="/"
                      class="inline-block bg-white text-black font-semibold px-6 py-2 rounded hover:bg-gray-100 transition"
                    >
                      Return to Homepage
                    </a>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
      
    <!-- Step Navigation + Dots -->
      <%= if !@film_submission do %>
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
      <% end %>
    </section>
    """
  end

  def handle_params(%{"step" => step_param}, _url, socket) do
    step_atom = String.to_existing_atom(step_param)

    cond do
      # Invalid step
      step_atom not in socket.assigns.step_order ->
        {:noreply, socket}

      # # Prevent skipping to payment if film details aren't complete
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

  def handle_event("go_to_step", %{"step" => step}, socket) do
    # Convert string key to atom
    step_atom = String.to_existing_atom(step)

    send(self(), {:go_to_step, step_atom})
    {:noreply, socket}
  end

  def handle_info({:update_film_submission_data, %{params: params}}, socket) do
    updated = Map.merge(socket.assigns.data, params)
    complete = film_details_complete?(updated)

    # Only try to update if we have a payment intent ID
    maybe_update_stripe_metadata(updated)

    {:noreply, assign(socket, data: updated, complete_film_details: complete)}
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

  def handle_info(:create_payment_intent, socket) do
    user = socket.assigns[:current_user]
    user_id = (user && user.id) || nil

    metadata = %{
      "submitted_by_id" => user_id
    }

    case Timesink.Payment.Stripe.create_payment_intent(%{
           amount: 2500,
           currency: "usd",
           metadata: metadata
         }) do
      {:ok, %Stripe.PaymentIntent{client_secret: secret, id: id}} ->
        updated_data = Map.put(socket.assigns.data, "stripe_client_secret", secret)
        updated_data = Map.put(updated_data, "payment_id", id)

        {:noreply, assign(socket, data: updated_data)}

      {:error, err} ->
        Logger.error("❌ Stripe error: #{inspect(err)}")
        {:noreply, socket}
    end
  end

  def handle_info({:create_btcpay_invoice, data}, socket) do
    send_update(
      TimesinkWeb.FilmSubmission.StepPaymentComponent,
      id: "payment_step",
      btcpay_loading: true,
      btcpay_invoice: nil,
      method: "bitcoin",
      data: socket.assigns.data,
      stripe_client_secret: socket.assigns.stripe_client_secret
    )

    case BtcPay.create_invoice(%{
           amount: 25,
           currency: "USD",
           metadata: data
         }) do
      {:ok, invoice} ->
        send_update(
          TimesinkWeb.FilmSubmission.StepPaymentComponent,
          id: "payment_step",
          btcpay_invoice: invoice,
          method: "bitcoin",
          data: socket.assigns.data
        )

        {:noreply, socket}

      {:error, _} ->
        send_update(
          TimesinkWeb.FilmSubmission.StepPaymentComponent,
          id: "payment_step",
          btcpay_loading: false,
          method: "bitcoin",
          data: socket.assigns.data
        )

        {:noreply, socket}
    end
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{event: "film_submission_completed", payload: submission},
        socket
      ) do
    Mail.send_film_submission_completion_notification(
      socket.assigns.applicant.contact_email,
      socket.assigns.applicant.contact_name,
      submission
    )

    {:noreply,
     socket
     |> assign(:film_submission, submission)}
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

  defp maybe_update_stripe_metadata(%{"payment_id" => id} = data) when is_binary(id) do
    metadata = %{
      "title" => data["title"],
      "year" => data["year"],
      "duration_min" => data["duration_min"],
      "synopsis" => data["synopsis"],
      "video_url" => data["video_url"],
      "video_pw" => data["video_pw"],
      "contact_name" => data["contact_name"],
      "contact_email" => data["contact_email"]
    }

    case Stripe.PaymentIntent.update(id, %{metadata: metadata}) do
      {:ok, _intent} -> :ok
      {:error, err} -> Logger.error("❌ Stripe update error: #{inspect(err)}")
    end
  end

  defp maybe_update_stripe_metadata(_), do: :noop
end
