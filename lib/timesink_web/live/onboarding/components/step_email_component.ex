defmodule TimesinkWeb.Onboarding.StepEmailComponent do
  use TimesinkWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white">
        <h1 class="text-3xl font-bold text-center">Welcome to TimeSink</h1>
        <p class="text-gray-400 text-center mt-2">
          Let’s Get You Set Up. Just a few quick steps before you’re in.
        </p>

        <form class="mt-6 space-y-4" phx-submit="send_verification_email">
          <div>
            <label class="block text-sm font-medium text-gray-300">Email</label>
            <.input
              type="email"
              name="email"
              value=""
              error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
              placeholder="Enter your email"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-300">Password</label>
            <.input
              type="password"
              name="password"
              value=""
              required
              error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
              input_class="w-full p-3 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              placeholder="Create a password"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-300">Confirm Password</label>
            <.input
              type="password"
              name="password_confirmation"
              value=""
              required
              error_class="md:absolute md:-bottom-8 md:left-0 md:items-center md:gap-1"
              input_class="w-full p-3 outline-width-0 rounded text-mystery-white border-none focus:outline-none outline-none bg-dark-theater-primary"
              placeholder="Confirm your password"
            />
          </div>

          <div class="mt-6">
            <.button color="secondary" class="w-full py-3 text-lg">Continue</.button>
          </div>
        </form>

        <p class="text-gray-400 text-center text-sm mt-6">
          Your email will be used to confirm your account and notify you about new screenings.
        </p>
      </div>
    </div>
    """
  end
end
