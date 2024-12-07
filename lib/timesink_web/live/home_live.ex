defmodule TimesinkWeb.HomepageLive do
  alias TimesinkWeb.NowPlayingListComponent
  use TimesinkWeb, :live_view

  def mount(_params, _session, socket) do
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

    socket = socket |> assign(:theaters, theaters) |> assign(:current_theater_id, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="hero" class="h-screen flex flex-col items-center justify-center text-center">
      <h1>Welcome to TimeSink</h1>
      <p>Scroll down to explore cinema</p>
    </div>

    <.live_component
      module={NowPlayingListComponent}
      id="now_playing_list"
      current_theater_id={@current_theater_id}
      theaters={@theaters}
    />
    """
  end

  def handle_event("scroll_to_theater", %{"id" => theater_id}, socket) do
    {:noreply, assign(socket, :current_theater_id, theater_id)}
  end
end
