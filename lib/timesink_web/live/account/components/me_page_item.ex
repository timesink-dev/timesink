defmodule TimesinkWeb.Account.MePageItem do
  use Phoenix.Component
  import TimesinkWeb.CoreComponents, only: [icon: 1]

  attr :class, :string, default: nil
  attr :title, :string, default: nil
  attr :items, :list, default: []

  def me_page_item(assigns) do
    ~H"""
    <section class={@class}>
      <h2 class="my-4">{@title}</h2>
      <div
        id={String.replace(String.downcase(@title), " ", "-")}
        class="rounded-lg bg-zinc-300/10 px-4 py-2 w-full inset-0"
      >
        <%= for item <- @items do %>
          <.link
            navigate={item[:link] || nil}
            class={[
              "cursor-pointer py-4 border-b-[1px] border-zinc-600/20 flex justify-start items-center gap-x-2 last:border-b-0",
              item[:coming_soon] && "cursor-not-allowed opacity-50"
            ]}
          >
            <span class="rounded-lg px-2 py-2 flex items-center justify-center bg-zinc-500/10">
              <.icon
                name={item[:icon]}
                class="bg-dark-theater-primary-light h-4 w-4 opacity-100 group-hover:opacity-70"
              />
            </span>
            <h3 class="text-sm font-medium group-hover:text-primary">
              {item[:title]}
            </h3>
          </.link>
        <% end %>
      </div>
    </section>
    """
  end
end
