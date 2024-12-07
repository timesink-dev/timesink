defmodule TimesinkWeb.NowPlayingListComponent do
  use TimesinkWeb, :live_component

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
      |> assign(:current_theater_id, "1")

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
