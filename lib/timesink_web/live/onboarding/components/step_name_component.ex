defmodule TimesinkWeb.Onboarding.StepNameComponent do
  use TimesinkWeb, :live_component

  def mount(socket) do
    {:ok,
     assign(socket,
       user_data: socket.assigns[:user_data],
       verified_email: socket.assigns[:verified_email]
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max">Name</div>
    </div>
    """
  end
end
