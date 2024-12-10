defmodule TimesinkWeb.ActivityComponent do
  use TimesinkWeb, :live_component

  def render(assigns) do
    ~H"""
    <section class="mt-16">
      <div class="mb-8">
        <h2 class="text-[2rem] font-semibold text-mystery-white">Activity</h2>
        <span> Review your comments, interactions with other members, and film submissions </span>
      </div>
    </section>
    """
  end
end
