defmodule TimesinkWeb.FilmSubmissionLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.FilmSubmissionStepComponent
  alias TimesinkWeb.Components.Stepper

  @step_order [
    :intro,
    :film_details,
    :payment,
    :review_and_submit
  ]
  @steps %{
    intro: FilmSubmissionStepIntroComponent,
    film_details: FilmSubmissionStepFilmDetailsComponent,
    payment: FilmSubmissionStepPaymentComponent,
    review_and_submit: FilmSubmissionStepReviewAndSubmitComponent
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

  @max_step length(@step_order)

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       steps: @steps,
       max_step: @max_step,
       step: hd(@step_order),
       data: @initial_form_data,
       current_user: socket.assigns[:current_user]
     )}
  end

  def render(assigns) do
    ~H"""
    <div
      id="film-submission"
      class="min-h-screen px-6 md:px-12 py-16 md:py-24 flex flex-col-reverse md:flex-row items-start md:items-center gap-6"
    >
      <!-- Left Column: Text + Form -->
      <div class="w-full md:w-2/5">
        <h1 class="text-4xl md:text-5xl leading-tight font-brand text-white">
          Grow your Audience.
        </h1>
        <p class="text-xl mt-4 text-gray-300">$25.00 submission fee</p>

        <div class="mt-8 space-y-6 text-base text-gray-400 max-w-md">
          <p>
            TimeSink is a live cinema platform built for bold films and the people who love them.
          </p>
          <p>
            We welcome short and feature-length projects across all genres, styles, and moods.
          </p>
          <p>
            Every submission is carefully reviewed by our programming team. You’ll hear from us directly once a decision is made.
          </p>
          <p>
            Join a vibrant community of cinephiles, creators, and curious minds. Submit your work and be part of the conversation.
          </p>
        </div>

        <%= if @current_user do %>
          <div class="mt-8 max-w-md">
            <p class="text-sm text-green-400 bg-green-600/20 p-3 rounded border border-green-500">
              You're signed in as {@current_user.email}. We’ll pre-fill your details.
            </p>
          </div>
        <% end %>
        
    <!-- Multistep form component -->
        <div class="mt-12 max-w-md">
          <.live_component
            module={Stepper}
            id="film-submission-form"
            steps={@steps}
            current_step={@step}
            data={@data}
          />
        </div>
        
    <!-- Step progress dots -->
        <div class="mt-6 flex space-x-3">
          <%= for i <- 1..@max_step do %>
            <div class={[
              "w-3 h-3 rounded-full transition",
              i == @step && "bg-white",
              i < @step && "bg-gray-500",
              i > @step && "bg-gray-700"
            ]} />
          <% end %>
        </div>
      </div>
      
    <!-- Right Column: Image -->
      <div class="w-full md:w-3/5">
        <div class="relative aspect-[4/3] md:aspect-video">
          <img
            src="/images/submit-2.png"
            alt="Film submission visual"
            class="w-full h-full object-cover rounded-xl shadow-lg"
          />
        </div>
      </div>
    </div>
    """
  end
end
