defmodule TimesinkWeb.HomepageLive do
  use TimesinkWeb, :live_view

  def mount(_params, _session, socket) do
    # Dummy data for theaters
    theaters = [
      %{
        id: 1,
        name: "Theater 1",
        film: %{
          title: "The Silent Sea",
          description: "A haunting journey through a deserted oceanic planet.",
          cover_image: "silent_sea.jpg"
        }
      },
      %{
        id: 2,
        name: "Theater 2",
        film: %{
          title: "Echoes of Eternity",
          description: "A poetic tale of love and loss across dimensions.",
          cover_image: "echoes_eternity.jpg"
        }
      },
      %{
        id: 3,
        name: "Theater 3",
        film: %{
          title: "Neon Reverie",
          description: "A cyberpunk thriller exploring dreams and reality.",
          cover_image: "neon_reverie.jpg"
        }
      },
      %{
        id: 4,
        name: "Theater 4",
        film: %{
          title: "Whispers in the Woods",
          description: "A suspenseful drama unraveling deep forest secrets.",
          cover_image: "whispers_woods.jpg"
        }
      },
      %{
        id: 5,
        name: "Theater 5",
        film: %{
          title: "Chronicles of the Unknown",
          description: "An epic sci-fi saga spanning the cosmos.",
          cover_image: "chronicles_unknown.jpg"
        }
      }
    ]

    socket =
      socket
      |> assign(:theaters, theaters)
      # Initially no theater is selected
      |> assign(:current_theater_id, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="hero" class="h-screen flex flex-col items-center justify-center text-center">
      <h1>Welcome to TimeSink</h1>
      <p>Scroll down to explore cinema</p>
    </div>

    <div id="theaters-container" phx-hook="ScrollHook" data-current-theater-id={@current_theater_id}>
      <div class="sticky top-0 right-0 h-full w-52 text-white flex flex-col gap-y-4 items-center pt-12">
        <%= for theater <- @theaters do %>
          <div
            class={"rounded cursor-pointer bg-dark-theater-primary px-12 py-4 #{if @current_theater_id === Integer.to_string(theater.id), do: "border-[1px] border-neon-red-primary"}"}
            phx-click="navigate"
            phx-value-id={theater.id}
          >
            <%= theater.name %>
          </div>
        <% end %>
      </div>
      <div class="flex justify-center items-center flex-col gap-y-96">
        <%= for theater <- @theaters do %>
          <section id={"theater-#{theater.id}"} class="film-cover-section">
            <%!-- <img
              src={Routes.static_path(@socket, "/images/#{theater.film.cover_image}")}
              alt={theater.film.title}
            /> --%>
            <div class="bg-neon-blue-primary px-6 py-24">
              <h2><%= theater.film.title %></h2>
              <p><%= theater.film.description %></p>
            </div>
          </section>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("navigate", %{"id" => theater_id}, socket) do
    IO.inspect("Navigating to theater with id #{theater_id}")
    {:noreply, socket |> assign(:current_theater_id, String.to_integer(theater_id))}
  end

  def handle_event("scroll_to_theater", %{"id" => theater_id}, socket) do
    IO.inspect("Scrolling to theater with id #{theater_id}")

    # Find the corresponding theater based on the theater_id
    # theater =
    #   Enum.find(socket.assigns.theaters, fn theater ->
    #     Integer.to_string(theater.id) == theater_id
    #   end)

    # You can also assign the current theater here to highlight it in the sidebar, for example
    socket = assign(socket, :current_theater_id, theater_id)

    {:noreply, socket}
  end
end
