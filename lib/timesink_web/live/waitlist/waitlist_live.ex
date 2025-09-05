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

    # <-- prevents KeyError anywhere
    socket =
      socket
      |> assign_new(:current_user, fn -> nil end)
      |> assign(
        email: "",
        joined: false,
        spots_remaining: spots_remaining,
        message: message,
        wait_time: estimated_wait_time
      )

    {:ok, socket, layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-xl w-full flex flex-col justify-center min-h-screen">
      <%= if @joined || @message do %>
        <div class="flex flex-col items-center">
          <h1 class="text-3xl">You've joined the line!</h1>
          <p class="py-1.5">{@message}</p>
          <p><strong>Estimated time until ticket invitation:</strong> {@wait_time}</p>
          <.button color="secondary" class="mt-8 px-4 py-2 border-[1px]">
            <a href="/">Go back outside</a>
          </.button>
        </div>
      <% else %>
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
