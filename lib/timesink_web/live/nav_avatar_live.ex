defmodule TimesinkWeb.NavAvatarLive do
  use Phoenix.LiveComponent

  def update(%{avatar_url: _url} = assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <img
      id={"nav-avatar-#{@user_id}"}
      src={@avatar_url}
      class="rounded-full w-8 h-8 object-cover ring-2 ring-zinc-700"
    />
    """
  end
end
