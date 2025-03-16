defmodule TimesinkWeb.Components.Stepper do
  use TimesinkWeb, :live_component

  attr :steps, :map, required: true
  attr :current_step, :atom, required: true
  attr :data, :map, required: false

  def render(assigns) do
    ~H"""
    <div class="onboarding-container">
      <.live_component module={@steps[@current_step]} id={"#{@current_step}_step"} data={@data} />
    </div>
    """
  end
end
