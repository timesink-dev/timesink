defmodule TimesinkWeb.NavAvatarLive do
  use Phoenix.LiveComponent

  def update(%{avatar_url: url} = assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <img
      id={"nav-avatar-#{@user_id}"}
      src={@avatar_url}
      class="rounded-full w-6 h-6 object-cover ring-2 ring-zinc-700"
    />
    """
  end
end
