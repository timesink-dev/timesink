defmodule TimesinkWeb.FilmSubmission.StepFilmDetailsComponent do
  use TimesinkWeb, :live_component

  alias Timesink.Cinema.FilmSubmission

  def update(assigns, socket) do
    data = assigns[:data] || %{}

    changeset =
      FilmSubmission.changeset(%FilmSubmission{}, %{
        contact_name: Map.get(data, :contact_name, ""),
        contact_email: Map.get(data, :contact_email, ""),
        film_title: Map.get(data, :film_title, ""),
        runtime_minutes: Map.get(data, :runtime_minutes, ""),
        synopsis: Map.get(data, :synopsis, ""),
        video_url: Map.get(data, :video_url, ""),
        video_pw: Map.get(data, :video_pw, "")
      })

    {:ok,
     assign(socket,
       form: to_form(changeset),
       data: data
     )}
  end

  def render(assigns) do
    ~H"""
    <section class="w-full px-6 h-1/2">
      <div class="max-w-7xl mx-auto flex flex-col-reverse md:flex-row items-start gap-12 md:gap-24">
        
    <!-- Left: Form Content -->
        <div class="w-full md:w-2/5">
          <h2 class="text-3xl font-brand font-bold mb-6">Film Submission</h2>

          <.simple_form
            for={@form}
            phx-submit="save_intro"
            phx-change="validate"
            phx-target={@myself}
            class="space-y-12"
          >
            <!-- Contact Info -->
            <div>
              <h3 class="text-xl font-semibold mb-4 text-neon-blue-lightest">Contact Information</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <.input
                  type="text"
                  field={@form[:contact_name]}
                  label="Your name"
                  placeholder="e.g. Alex Rivera"
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
            
    <!-- Film Info -->
            <div>
              <h3 class="text-xl font-semibold mb-4 text-neon-blue-lightest">Film Details</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <.input
                  type="text"
                  field={@form[:film_title]}
                  label="Film title"
                  placeholder="Your film’s name"
                  required
                  input_class="w-full p-3 rounded text-mystery-white border-none"
                />
                <.input
                  type="number"
                  field={@form[:runtime_minutes]}
                  label="Runtime (minutes)"
                  placeholder="e.g. 14"
                  min="1"
                  required
                  input_class="w-full p-3 rounded text-mystery-white border-none"
                />
              </div>
              <div class="mt-6">
                <.input
                  type="textarea"
                  field={@form[:synopsis]}
                  label="Synopsis"
                  placeholder="Give us a taste of what it’s about..."
                  required
                  rows="5"
                  input_class="w-full p-3 rounded text-mystery-white border-none"
                />
              </div>
              <div class="mt-6 grid grid-cols-1 md:grid-cols-2 gap-6">
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
        
    <!-- Right: Shared Image -->
        <div class="w-full md:w-3/5 self-center">
          <div class="aspect-[3/2] md:aspect-[16/9] w-full rounded-xl overflow-hidden">
            <img
              src="/images/submit-2.png"
              alt="Film submission visual"
              class="w-full h-full object-cover"
            />
          </div>
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

  def handle_event("save_intro", %{"film_submission" => params}, socket) do
    changeset = FilmSubmission.changeset(%FilmSubmission{}, params)

    if changeset.valid? do
      send(self(), {:update_user_data, %{params: params}})
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
end
