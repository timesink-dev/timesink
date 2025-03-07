defmodule TimesinkWeb.WaitlistLive do
  use TimesinkWeb, :live_view
  alias TimesinkWeb.WaitlistFormComponent
  alias Timesink.Waitlist

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :reset_joined, 0)
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
       wait_time: estimated_wait_time
     ), layout: {TimesinkWeb.Layouts, :empty}}
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-xl w-full flex flex-col justify-center min-h-screen">
      <%= if @joined || @message do %>
        <div class="flex flex-col items-center">
          <h1 class="text-3xl">You've joined the line! 🍿</h1>
          <p class="py-1.5">{@message}</p>
          <p><strong>Estimated Invite:</strong> {@wait_time}</p>
          <.button color="secondary" class="mt-8 px-4 py-1.5 border-[1px]">
            <a href="/">Go to homepage</a>
          </.button>
        </div>
      <% else %>
        <a class="flex flex-col -space-y-2.5 font-brand items-center" href={~p"/"}>
          <p class="text-[3rem] leading-10 tracking-tighter">
            TimeSink
          </p>
          <p class="pl-4 text-[2.6rem]">
            Presents
          </p>
        </a>
        <h2 class="uppercase text-[2rem] mt-12 mb-2 tracking-tighter items-center">
          Welcome to the show.
        </h2>
        <div class="flex flex-col gap-y-2">
          <p>
            <b>While the world outside buzzes with the chaos of endless content</b>, we sift through it all to bring you a collection of hand-picked cinematic gems made by the filmmakers of today.
          </p>
        </div>
        <.live_component
          module={WaitlistFormComponent}
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
    Process.send_after(self(), :reset_joined, 15000)
    {:noreply, socket}
  end

  def handle_info(:reset_joined, socket) do
    socket = assign(socket, joined: false)
    {:noreply, socket}
  end

  def handle_info(:update_waitlist_status, socket) do
    spots = Waitlist.get_wave_spots_remaining()
    {:noreply, assign(socket, spots_remaining: spots)}
  end
end
