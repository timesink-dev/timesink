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
    <div class="w-full min-h-screen flex items-center justify-center">
      <%= if @joined || @message do %>
        <section class="relative w-full max-w-[1400px] grid grid-cols-1 md:grid-cols-12 items-center justify-center md:gap-8 px-6 py-12 md:py-24">
          <!-- TEXT SIDE -->
          <div class="md:col-span-5 lg:col-span-4 flex flex-col justify-center items-center md:items-start text-center md:text-left space-y-5">
            <h1 class="text-3xl md:text-4xl font-semibold tracking-tight text-white">
              You've joined the line!
            </h1>

            <p class="text-zinc-300 leading-relaxed max-w-md">
              {@message}
            </p>

            <p class="text-sm text-zinc-400">
              <strong class="font-medium text-zinc-200">
                Estimated time until ticket invitation:
              </strong>
              {@wait_time}
            </p>

            <.button color="primary" class="mt-6 px-4 py-2 border border-white/20">
              <a href="/">Go back outside</a>
            </.button>
          </div>
          
    <!-- IMAGE SIDE -->
          <div class="md:col-span-7 lg:col-span-8 flex justify-center items-center relative w-full h-[50vh] md:h-[90vh] overflow-hidden">
            <img
              src="/images/waiting_list.png"
              alt="TimeSink waitlist success"
              class="object-contain w-full h-full max-h-[90vh]"
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
