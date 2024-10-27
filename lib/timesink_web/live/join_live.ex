defmodule TimesinkWeb.JoinLive do
  use TimesinkWeb, :live_view
  alias TimesinkWeb.Live.ResponsiveHelpers

  # Initial mount assigns default device type if it's missing
  @spec mount(any(), any(), map()) :: {:ok, map()}
  def mount(_params, _session, socket) do
    socket = assign_new(socket, :device_type, fn -> "desktop" end)
    {:ok, socket}
  end

  # Handle incoming device type update from the hook
  @spec handle_event(<<_::136>>, map(), map()) :: {:noreply, map()}
  def handle_event("update_breakpoint", %{"device_type" => device_type}, socket) do
    {:noreply, assign(socket, :device_type, device_type)}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-xl mt-24 w-full">
      <span class="flex flex-col -space-y-2.5 font-brand items-center">
        <p class="text-[3rem] leading-10 tracking-tighter">
          TimeSink
        </p>
        <p class="pl-4 text-[3rem]">
          presents
        </p>
      </span>
      <h2 class="uppercase text-[2rem] mt-20 mb-2 tracking-tighter items-center">
        Welcome to the show.
      </h2>
      <div class="flex flex-col gap-y-2">
        <p>
          <b>While the world outside buzzes with the chaos of endless content</b>, we sift through it all to bring you a collection of hand-picked cinematic gems made by the filmmakers of today.
        </p>
      </div>
      <div
        class={
          responsive_class(
            %{
              common: "mt-8",
              desktop: "flex justify-center gap-x-4 h-full items-end"
            },
            @device_type
          )
        }
        phx-hook="GetBreakpoints"
        id="get-breakpoints"
      >
        <div class="w-full flex flex-col gap-y-2">
          <div class="flex gap-x-2 justify-between w-full">
            <input
              type="text"
              placeholder="First name"
              class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
            />
            <input
              type="text"
              placeholder="Last name"
              class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
            />
          </div>
          <input
            type="email"
            placeholder="Enter your email"
            class="w-full p-4 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
          />
        </div>
        <.button
          color="primary"
          class="text-backroom-black font-semibold mt-4 w-full sm:w-2/3 px-6 py-4 hover:bg-neon-blue-lightest focus:ring-2 focus:bg-neon-blue-light"
        >
          Join the Waitlist
        </.button>
      </div>
    </div>
    """
  end

  # Expose `responsive_class` to LiveView's template
  defp responsive_class(classes, device_type) do
    ResponsiveHelpers.responsive_class(classes, device_type)
  end
end
