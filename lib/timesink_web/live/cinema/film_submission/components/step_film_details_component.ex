defmodule TimesinkWeb.FilmSubmission.StepFilmDetailsComponent do
  use TimesinkWeb, :live_component

  alias Timesink.Cinema.FilmSubmission

  def update(assigns, socket) do
    raw_data = assigns[:data] || %{}
    data = atomize_keys(raw_data)

    user = Map.get(data, :user)

    contact_name =
      case Map.get(data, :contact_name) do
        nil -> user_full_name(user)
        "" -> user_full_name(user)
        name -> name
      end

    contact_email =
      case Map.get(data, :contact_email) do
        nil -> user_email(user)
        "" -> user_email(user)
        email -> email
      end

    changeset =
      FilmSubmission.changeset(%FilmSubmission{}, %{
        contact_name: contact_name || "",
        contact_email: contact_email || "",
        title: Map.get(data, :title, ""),
        duration_min: parse_int(data[:duration_min]),
        synopsis: Map.get(data, :synopsis, ""),
        video_url: Map.get(data, :video_url, ""),
        video_pw: Map.get(data, :video_pw, ""),
        year: parse_int(data[:year]),
        user: user
      })

    {:ok, assign(socket, form: to_form(changeset), data: data)}
  end

  def render(assigns) do
    ~H"""
    <section class="w-full px-6">
      <div class="max-w-4xl mx-auto">

    <!-- Left: Form Content -->
        <div class="w-full md:w-3/5">
          <h2 class="text-3xl font-brand mb-4">Film Submission</h2>
          <p class="text-mystery-white/80 mb-4 text-sm">
            This is where you share the essentials—your film’s name, runtime, synopsis, and how to watch it.
            We also ask for your contact info so we can reach you if your film is selected.
          </p>
          <.simple_form
            for={@form}
            phx-submit="save_film_details"
            phx-change="validate"
            phx-target={@myself}
            class="space-y-6"
          >

    <!-- Film Info -->
            <div>
              <h3 class="text-xl font-semibold mb-2 text-neon-blue-lightest">Film Details</h3>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <.input
                  type="text"
                  field={@form[:title]}
                  placeholder="Film title"
                  required
                  input_class="w-full p-3 rounded text-mystery-white border-none"
                />
                <.input
                  type="text"
                  inputmode="numeric"
                  field={@form[:duration_min]}
                  placeholder="Runtime (minutes)"
                  min="1"
                  required
                  input_class="w-full p-3 rounded text-mystery-white border-none"
                />
                <.input
                  type="text"
                  inputmode="numeric"
                  field={@form[:year]}
                  placeholder="Year of release"
                  min="1888"
                  max={Date.utc_today().year}
                  required
                  input_class="w-full p-3 rounded text-mystery-white border-none"
                />
              </div>

              <div class="mt-4">
                <.input
                  type="textarea"
                  field={@form[:synopsis]}
                  label="Synopsis"
                  placeholder="Give us a taste of what it’s about..."
                  required
                  rows="2"
                  input_class="w-full p-3 rounded text-mystery-white border-none"
                />
              </div>
              <div class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-6">
                <.input
                  type="url"
                  field={@form[:video_url]}
                  label="Link to your film"
                  placeholder="e.g. https://vimeo.com/123456"
                  required
                  input_class="w-full p-3 rounded text-mystery-white border-none"
                />
                <.input
                  type="text"
                  field={@form[:video_pw]}
                  label="Password (if applicable)"
                  placeholder="Leave empty if public"
                  input_class="w-full p-3 rounded text-mystery-white border-none"
                />
              </div>
            </div>

    <!-- Contact Info -->
            <div>
              <h3 class="text-xl font-semibold mb-4 text-neon-blue-lightest">Contact Information</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <.input
                  type="text"
                  field={@form[:contact_name]}
                  label="Your name"
                  placeholder="Enter your full name"
                  required
                  input_class="w-full p-3 rounded text-mystery-white border-none"
                />
                <.input
                  type="email"
                  field={@form[:contact_email]}
                  label="Email address"
                  placeholder="you@example.com"
                  required
                  input_class="w-full p-3 rounded text-mystery-white border-none"
                />
              </div>
            </div>

    <!-- Submit -->
            <:actions>
              <div class="pt-6 border-t border-white/10">
                <.button color="primary" class="w-full md:w-1/2 py-3 text-lg">
                  Continue
                </.button>
              </div>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </section>
    """
  end

  def handle_event("validate", %{"film_submission" => params}, socket) do
    changeset =
      %FilmSubmission{}
      |> FilmSubmission.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save_film_details", %{"film_submission" => params}, socket) do
    changeset = FilmSubmission.changeset(%FilmSubmission{}, params)

    if changeset.valid? do
      send(self(), {:update_film_submission_data, %{params: params}})
      send(self(), {:go_to_step, :next})
      {:noreply, socket}
    else
      {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("go_back", _params, socket) do
    send(self(), {:go_to_step, :back})
    {:noreply, socket}
  end

  defp atomize_keys(map) do
    for {k, v} <- map, into: %{} do
      key = if is_binary(k), do: String.to_atom(k), else: k
      {key, v}
    end
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp parse_int(val), do: val

  defp user_full_name(%{first_name: first, last_name: last})
       when is_binary(first) and is_binary(last) do
    "#{first} #{last}"
  end

  defp user_full_name(_), do: ""

  defp user_email(%{email: email}) when is_binary(email), do: email
  defp user_email(_), do: ""
end
