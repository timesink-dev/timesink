defmodule TimesinkWeb.WaitlistLive do
  use TimesinkWeb, :live_view
  alias Timesink.Waitlist

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(10_000, self(), :update_waitlist_status)
    end

    %{:message => message, :estimated_wait_time => estimated_wait_time} =
      Waitlist.get_waitlist_message("")

    spots_remaining = Waitlist.get_wave_spots_remaining()

    {:ok,
     assign(socket,
       joined: false,
       email: "",
       spots_remaining: spots_remaining,
       message: message,
       wait_time: estimated_wait_time,
       # or :below
       image_variant: :left
     ), layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full min-h-screen bg-backroom-black flex items-center justify-center overflow-hidden">
      <%= if @joined || @message do %>
        <section class="gap-x-16 flex flex-col md:flex-row items-center justify-between w-full max-w-[1600px] px-6 md:px-12 py-8 md:py-0">
          
    <!-- TEXT SIDE -->
          <div class="flex-1 md:basis-[55%] flex flex-col justify-center text-center md:text-left space-y-6 md:space-y-8 max-w-lg z-10">
            <h1 class="text-3xl md:text-4xl font-semibold tracking-tight text-mystery-white leading-tight">
              You’ve joined the line!
            </h1>

            <%= if @message do %>
              <p class="text-zinc-300 text-lg">
                {@message}
              </p>
            <% end %>
            <p class="text-sm text-zinc-400">
              <strong class="font-medium text-zinc-200">
                Estimated time until ticket invitation:
              </strong>
              {@wait_time}
            </p>

            <.button color="primary" class="mt-6 self-center md:self-start">
              <a href="/">Go back outside</a>
            </.button>
          </div>
          
    <!-- IMAGE SIDE -->
          <div class="relative flex-1 md:basis-[85%] flex justify-center md:justify-end items-center overflow-hidden">
            <img
              src="/images/waitlist.webp"
              alt="TimeSink waitlist success"
              class="object-cover w-full md:h-[450px]"
            />
          </div>
        </section>
      <% else %>
        <.live_component
          module={TimesinkWeb.WaitlistFormComponent}
          id="waitlist_form"
          joined={@joined}
          spots_remaining={@spots_remaining}
        />
      <% end %>
    </div>
    """
  end

  def handle_info(:applicant_joined, socket) do
    socket = assign(socket, joined: true)
    {:noreply, socket}
  end

  def handle_info(:update_waitlist_status, socket) do
    spots = Waitlist.get_wave_spots_remaining()
    {:noreply, assign(socket, spots_remaining: spots)}
  end
end
