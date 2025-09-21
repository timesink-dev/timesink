defmodule TimesinkWeb.Account.SecuritySettingsLive do
  use TimesinkWeb, :live_view
  alias Timesink.Account

  def mount(_p, _s, socket) do
    {:ok,
     assign(socket,
       form: to_form(preview_user_password_changeset(%{}), as: "user"),
       dirty: false
     )}
  end

  def render(assigns) do
    ~H"""
    <section class="px-4 md:px-6 py-8">
      <div class="max-w-2xl mx-auto">
        <.back navigate={~p"/me"}></.back>
      </div>

      <div class="w-full max-w-2xl mx-auto bg-backroom-black/60 rounded-2xl shadow-lg">
        <div class="px-6 md:px-8 py-6 border-b border-zinc-800">
          <h2 class="text-2xl md:text-3xl font-semibold text-mystery-white text-center">
            Security settings
          </h2>
          <p class="text-zinc-400 text-center mt-2">Change your password. Keep your account safe.</p>
        </div>

        <div class="px-6 md:px-8 py-6">
          <.simple_form
            for={@form}
            as="user"
            phx-change="validate"
            phx-submit="save"
            class="space-y-6"
          >
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="md:col-span-2">
                <label class="block text-sm font-medium text-zinc-300 mb-2">Current password</label>
                <.input
                  type="password"
                  field={@form[:current_password]}
                  phx-debounce="400"
                  input_class="w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-zinc-300 mb-2">New password</label>
                <.input
                  type="password"
                  field={@form[:password]}
                  phx-debounce="400"
                  input_class="w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-zinc-300 mb-2">
                  Confirm new password
                </label>
                <.input
                  type="password"
                  field={@form[:password_confirmation]}
                  phx-debounce="400"
                  input_class="w-full rounded-xl bg-dark-theater-primary text-mystery-white placeholder:zinc-400 outline-none ring-0 focus:ring-2 focus:ring-neon-blue-lightest px-4 py-3"
                />
              </div>
            </div>

            <:actions>
              <button
                type="submit"
                disabled={!@dirty}
                aria-disabled={!@dirty}
                phx-disable-with="Updating…"
                class="w-full md:w-auto px-6 py-3 rounded-xl font-semibold bg-neon-blue-lightest text-backroom-black
                        hover:opacity-90 focus:ring-2 focus:ring-neon-blue-lightest transition
                        disabled:opacity-40 disabled:cursor-not-allowed phx-submit-loading:opacity-60 phx-submit-loading:cursor-wait"
              >
                <span class="inline-flex items-center gap-2 phx-submit-loading:hidden">
                  Update password
                </span>
                <span class="hidden phx-submit-loading:inline-flex items-center gap-2">
                  <svg class="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    >
                    </circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8v4A4 4 0 008 12H4z"
                    >
                    </path>
                  </svg>
                  Updating…
                </span>
              </button>
            </:actions>
          </.simple_form>
        </div>
      </div>

      <div class="mt-10 max-w-2xl mx-auto">
        <h2 class="w-full bg-neon-red-light/10 px-6 md:px-12 py-6 border border-neon-red-light rounded-2xl text-neon-red-light text-xl font-brand">
          Danger zone
        </h2>
        <button class="mt-6 py-3 px-6 bg-backroom-black text-neon-red-light font-semibold border border-neon-red-light rounded-xl hover:bg-neon-red-light/5">
          Delete account
        </button>
      </div>
    </section>
    """
  end

  def handle_event("validate", %{"user" => params}, socket) do
    cs =
      params
      |> preview_user_password_changeset()
      |> Map.put(:action, :validate)

    dirty? = cs.changes != %{}
    {:noreply, assign(socket, form: to_form(cs, as: "user"), dirty: dirty?)}
  end

  def handle_event("save", %{"user" => %{"current_password" => current} = params}, socket) do
    case Account.update_user_password(socket.assigns.current_user, current, params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(form: to_form(preview_user_password_changeset(%{}), as: "user"), dirty: false)
         |> put_flash(:info, "Password updated")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs, as: "user"), dirty: cs.changes != %{})}
    end
  end

  defp preview_user_password_changeset(attrs) do
    types = %{current_password: :string, password: :string, password_confirmation: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(attrs, Map.keys(types))
    |> TimesinkWeb.Utils.trim_fields([:current_password, :password, :password_confirmation])
    |> maybe_validate_min_length(:password, 8)
    |> Ecto.Changeset.validate_confirmation(:password, required: false, message: "does not match")
  end

  defp maybe_validate_min_length(cs, field, min) do
    case Ecto.Changeset.get_change(cs, field) do
      nil ->
        cs

      "" ->
        cs

      _ ->
        Ecto.Changeset.validate_length(cs, field,
          min: min,
          message: "must be at least #{min} characters"
        )
    end
  end
end
