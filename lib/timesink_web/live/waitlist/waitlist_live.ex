defmodule TimesinkWeb.WaitlistLive do
  use TimesinkWeb, :live_view
  alias TimesinkWeb.WaitlistFormComponent

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :reset_joined, 0)
    end

    {:ok, assign(socket, joined: false), layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-xl w-full flex flex-col justify-center min-h-screen">
      <a href="/">
        <span class="flex flex-col -space-y-2.5 font-brand items-center">
          <p class="text-[3rem] leading-10 tracking-tighter">
            TimeSink
          </p>
          <p class="pl-4 text-[2.6rem]">
            Presents
          </p>
        </span>
      </a>
      <h2 class="uppercase text-[2rem] mt-12 mb-2 tracking-tighter items-center">
        Welcome to the show.
      </h2>
      <div class="flex flex-col gap-y-2">
        <p>
          <b>While the world outside buzzes with the chaos of endless content</b>, we sift through it all to bring you a collection of hand-picked cinematic gems made by the filmmakers of today.
        </p>
      </div>
      <.live_component module={WaitlistFormComponent} id="waitlist_form" joined={@joined} />
    </div>
    """
  end

  def handle_info(:applicant_joined, socket) do
    socket = assign(socket, joined: true)
    Process.send_after(self(), :reset_joined, 3000)
    {:noreply, socket}
  end

  def handle_info(:reset_joined, socket) do
    socket = assign(socket, joined: false)
    {:noreply, socket}
  end
end
