defmodule TimesinkWeb.NavAvatarLive do
  use Phoenix.LiveComponent

  def update(%{avatar_url: _url} = assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <span>
      <%= if @avatar_url do %>
        <img
          id={"nav-avatar-#{@user.id}"}
          src={@avatar_url}
          class="rounded-full w-8 h-8 object-cover ring-2 ring-zinc-700"
        />
      <% else %>
        <span class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-zinc-700 text-[11px] font-semibold">
          {initials(@user)}
        </span>
      <% end %>
    </span>
    """
  end

  defp initials(%{first_name: fnm, last_name: lnm}) do
    f = fnm |> to_string() |> String.trim() |> String.first() || ""
    l = lnm |> to_string() |> String.trim() |> String.first() || ""

    case String.upcase(f <> l) do
      "" -> "?"
      s -> s
    end
  end
end
