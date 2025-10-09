defmodule TimesinkWeb.AvatarLive do
  use TimesinkWeb, :live_component
  alias Phoenix.PubSub
  alias TimesinkWeb.PubSubTopics

  @impl true
  def mount(socket) do
    {:ok, assign(socket, url: nil, user_id: nil, subscribed?: false)}
  end

  @impl true
  def update(%{user_id: user_id, initial_url: initial_url}, socket) do
    # Subscribe once when we first learn the user_id or it changes
    socket =
      if socket.assigns.user_id != user_id and not socket.assigns.subscribed? do
        PubSub.subscribe(Timesink.PubSub, PubSubTopics.profile_update_topic(user_id))
        assign(socket, subscribed?: true)
      else
        socket
      end

    {:ok, socket |> assign(:user_id, user_id) |> assign(:url, initial_url)}
  end

  def handle_info({:avatar_updated, user_id, new_url}, %{assigns: %{user_id: user_id}} = socket) do
    {:noreply, assign(socket, url: new_url)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <img
      src={@url}
      alt="Avatar"
      width="24"
      height="24"
      decoding="async"
      loading="eager"
      class="rounded-full w-6 h-6 object-cover ring-2 ring-zinc-700 transition-opacity duration-150"
      onload="this.style.opacity=1"
      style="opacity:0"
    />
    """
  end
end
