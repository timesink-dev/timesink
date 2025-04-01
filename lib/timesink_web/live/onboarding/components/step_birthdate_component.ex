defmodule TimesinkWeb.Onboarding.StepBirthdateComponent do
  use TimesinkWeb, :live_component

  alias Timesink.Accounts.Profile
  import Ecto.Changeset

  def update(assigns, socket) do
    birthdate = get_in(assigns.data, ["profile", "birthdate"])

    changeset =
      Timesink.Accounts.Profile.birthdate_changeset(
        %Timesink.Accounts.Profile{},
        if(birthdate, do: %{"birthdate" => birthdate}, else: %{})
      )

    form = to_form(changeset, as: "birthdate")

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)
     |> assign_new(:birth_month, fn ->
       (birthdate && birthdate.month |> to_string() |> String.pad_leading(2, "0")) || ""
     end)
     |> assign_new(:birth_day, fn ->
       (birthdate && birthdate.day |> to_string() |> String.pad_leading(2, "0")) || ""
     end)
     |> assign_new(:birth_year, fn -> (birthdate && birthdate.year |> to_string()) || "" end)
     |> assign_new(:error, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-backroom-black px-6">
      <div class="w-full max-w-md bg-backroom-black shadow-lg rounded-2xl p-8 text-white text-center">
        <h1 class="text-3xl font-bold">What's your birthday?</h1>
        <p class="text-gray-400 mt-2">
          Time reveals all illusions — even our favorite cinema. Knowing your age helps us better tailor screenings and platform vibes.
        </p>

        <.simple_form
          for={@form}
          as="birthdate"
          phx-target={@myself}
          phx-submit="submit_birthdate"
          class="mt-6 space-y-4"
        >
          <div class="flex justify-center gap-x-2">
            <.input
              type="text"
              name="birth_month"
              maxlength="2"
              phx-hook="DigitsOnlyAutoTab"
              placeholder="MM"
              inputmode="numeric"
              value={@birth_month}
              input_class="w-full p-3 rounded text-center text-mystery-white border-none"
            />
            <.input
              type="text"
              name="birth_day"
              maxlength="2"
              phx-hook="DigitsOnlyAutoTab"
              placeholder="DD"
              inputmode="numeric"
              value={@birth_day}
              input_class="w-full p-3 rounded text-center text-mystery-white border-none"
            />
            <.input
              type="text"
              name="birth_year"
              maxlength="4"
              placeholder="YYYY"
              inputmode="numeric"
              phx-hook="DigitsOnlyAutoTab"
              value={@birth_year}
              input_class="w-full p-3 rounded text-center text-mystery-white border-none"
            />
          </div>

          <%= if @error do %>
            <p class="text-neon-red-light text-sm mt-2">
              <.icon name="hero-exclamation-circle-mini" class="h-5 w-5 inline" />
              {@error}
            </p>
          <% end %>

          <:actions>
            <.button color="secondary" class="w-full py-3 text-lg">Continue</.button>
          </:actions>
        </.simple_form>

        <.button color="none" class="mt-6 p-0" phx-click="go_back" phx-target={@myself}>
          ← Back
        </.button>
      </div>
    </div>
    """
  end

  def handle_event(
        "submit_birthdate",
        %{"birth_month" => mm, "birth_day" => dd, "birth_year" => yyyy},
        socket
      ) do
    mm = String.trim(mm || "")
    dd = String.trim(dd || "")
    yyyy = String.trim(yyyy || "")

    with {month, ""} <- Integer.parse(mm),
         {day, ""} <- Integer.parse(dd),
         {year, ""} <- Integer.parse(yyyy),
         {:ok, birthdate} <- Date.new(year, month, day) do
      # Validate with changeset
      changeset =
        Profile.birthdate_changeset(%Profile{}, %{"birthdate" => birthdate})

      if changeset.valid? do
        updated_profile =
          Map.update(socket.assigns.data["profile"], "birthdate", birthdate, fn _ -> birthdate end)

        updated_data = Map.put(socket.assigns.data, "profile", updated_profile)

        send(self(), {:update_user_data, %{params: updated_data}})
        send(self(), {:go_to_step, :next})
        {:noreply, socket}
      else
        {:noreply,
         socket
         |> assign(:error, "Hmm… that doesn't look like a real birthday.")
         |> assign(:birth_month, mm)
         |> assign(:birth_day, dd)
         |> assign(:birth_year, yyyy)}
      end
    else
      _ ->
        {:noreply,
         socket
         |> assign(:error, "Hmm… that doesn't look like a real birthday.")
         |> assign(:birth_month, mm)
         |> assign(:birth_day, dd)
         |> assign(:birth_year, yyyy)}
    end
  end

  def handle_event("go_back", _params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end
end
