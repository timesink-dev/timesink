defmodule TimesinkWeb.NowPlayingListComponent do
  use TimesinkWeb, :live_component

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_theater_id, Integer.to_string(socket.assigns.current_theater_id))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div
      id="theaters-container"
      phx-hook="ScrollToTheater"
      data-current-theater-id={@current_theater_id}
      class="w-full flex justify-between items-start"
    >
      <div class="sticky top-0 right-0 h-full w-52 text-white flex flex-col gap-y-4 items-center pt-6">
        <%= for theater <- @theaters do %>
          <div
            class={"rounded cursor-pointer bg-dark-theater-primary px-12 py-4 #{if @current_theater_id === Integer.to_string(theater.id), do: "border-[1px] border-neon-red-primary"}"}
            phx-click="scroll_to_theater"
            phx-hook="NavigateToTheater"
            phx-value-id={theater.id}
            id="theater-nav"
          >
            <%= theater.name %>
          </div>
        <% end %>
      </div>
      <div class="pt-6 mx-auto max-w-2xl flex justify-center items-center flex-col gap-y-24 snap-y snap-mandatory w-full">
        <%= for theater <- @theaters do %>
          <section
            id={"theater-#{theater.id}"}
            class="film-cover-section h-screen snap-always snap-center w-full"
          >
            <div class="bg-neon-blue-primary w-full h-full">
              <h2><%= theater.film.title %></h2>
              <p><%= theater.film.description %></p>
            </div>
          </section>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("scroll_to_theater", %{"id" => theater_id}, socket) do
    {:noreply, assign(socket, :current_theater_id, theater_id)}
  end
end
