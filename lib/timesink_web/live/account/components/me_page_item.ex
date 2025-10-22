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
        class="rounded-2xl border border-zinc-800 bg-dark-theater-primary/60 px-4 py-2 w-full inset-0"
      >
        <%= for item <- @items do %>
          <%= if item[:coming_soon] do %>
            <!-- Disabled row (no link) -->
            <div
              aria-disabled="true"
              class={[
                "py-4 border-b-[1px] border-zinc-600/20 flex items-center gap-x-3 last:border-b-0",
                "opacity-60 cursor-not-allowed select-none"
              ]}
            >
              <span class="rounded-lg px-2 py-2 flex items-center justify-center bg-zinc-500/10">
                <.icon name={item[:icon]} class="h-4 w-4 opacity-100" />
              </span>
              <h3 class="text-sm font-medium">
                {item[:title]}
              </h3>
              
    <!-- badge -->
              <span class="ml-auto inline-flex items-center rounded-full bg-zinc-700/60 text-zinc-200/90 text-[11px] px-2 py-0.5 ring-1 ring-zinc-500/40">
                Coming soon
              </span>
            </div>
          <% else %>
            <!-- Clickable row (link) -->
            <.link
              navigate={item[:link]}
              class="group py-4 border-b-[1px] border-zinc-600/20 flex items-center gap-x-3 last:border-b-0 rounded-md -mx-2 px-2 hover:bg-zinc-800/30 transition"
            >
              <span class="rounded-lg px-2 py-2 flex items-center justify-center bg-zinc-500/10">
                <.icon name={item[:icon]} class="h-4 w-4 opacity-100 group-hover:opacity-70" />
              </span>
              <h3 class="text-sm font-medium group-hover:text-primary">
                {item[:title]}
              </h3>
            </.link>
          <% end %>
        <% end %>
      </div>
    </section>
    """
  end
end
