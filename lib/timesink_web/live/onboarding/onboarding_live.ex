defmodule TimesinkWeb.OnboardingLive do
  use TimesinkWeb, :live_view

  alias Timesink.Account
  alias Timesink.Token
  alias Timesink.Auth, as: CoreAuth
  alias TimesinkWeb.Components.Stepper
  alias Timesink.Waitlist
  alias Timesink.Repo

  alias TimesinkWeb.Onboarding.{
    # StepEmailComponent,
    # StepVerifyEmailComponent,
    # StepNameComponent,
    StepBirthdateComponent,
    StepLocationComponent,
    StepUsernameComponent,
    StepPasswordComponent
  }

  @step_order [:location, :birthdate, :username, :password]
  @steps %{
    location: StepLocationComponent,
    birthdate: StepBirthdateComponent,
    username: StepUsernameComponent,
    password: StepPasswordComponent
  }

  def mount(_params, session, socket) do
    invite_token = session["invite_token"]
    applicant = session["applicant"] || nil

    # Extract user info from applicant if present
    {invite_email, first_name, last_name} =
      case applicant do
        %{email: email, first_name: fname, last_name: lname}
        when is_binary(email) and is_binary(fname) and is_binary(lname) ->
          {email, fname, lname}

        %{email: email} when is_binary(email) ->
          {email, "", ""}

        _ ->
          {session["email"], "", ""}
      end

    socket =
      socket
      # Seed user_data with info from applicant/session
      |> assign_new(:user_data, fn ->
        initial_user_data(invite_email, first_name, last_name)
      end)
      # Mark verified if we have an invite email
      |> assign_new(:verified_email, fn -> not is_nil(invite_email) and invite_email != "" end)
      |> assign(:invite_token, invite_token)
      |> assign(:applicant, applicant)
      |> assign(:steps, @steps)
      # Start at the first *kept* step
      |> assign(:step, hd(@step_order))

    {:ok, socket, layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={Stepper}
      id="stepper"
      steps={@steps}
      current_step={@step}
      data={@user_data}
    />
    """
  end

  def handle_params(params, _uri, socket) do
    invite_token = socket.assigns.invite_token

    # Only validate token now; do NOT gate on "missing email"
    with true <- Token.is_valid?(invite_token),
         step <- get_step_from_params(params) do
      {:noreply, assign(socket, step: step)}
    else
      false ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Invalid or expired invite token. Please check the link and try again."
         )
         |> redirect(to: "/")}
    end
  end

  def handle_info({:go_to_step, direction}, socket) do
    new_step = determine_step(socket.assigns.step, direction, socket.assigns.verified_email)
    {:noreply, assign(socket, step: new_step) |> push_patch(to: "/onboarding?step=#{new_step}")}
  end

  def handle_info({:update_user_data, %{params: params}}, socket) do
    {:noreply, assign(socket, user_data: Map.merge(socket.assigns.user_data, params))}
  end

  def handle_info(:email_verified, socket) do
    {:noreply, assign(socket, verified_email: true)}
  end

  def handle_info({:complete_onboarding, %{params: user_create_params}}, socket) do
    result =
      Repo.transaction(fn ->
        user =
          case Account.create_user(user_create_params) do
            {:ok, user} -> user
            {:error, cs} -> Repo.rollback({:user_error, cs})
          end

        case Token.invalidate_token(socket.assigns.invite_token) do
          {:ok, _tok} -> :ok
          {:error, :already_used} -> Repo.rollback(:invite_already_used)
          {:error, :not_found} -> Repo.rollback(:invite_not_found)
          {:error, cs} -> Repo.rollback({:token_error, cs})
          other -> Repo.rollback({:token_error, other})
        end

        case maybe_mark_applicant_completed(socket.assigns.applicant) do
          {:ok, _} -> :ok
          {:error, cs} -> Repo.rollback({:waitlist_error, cs})
        end

        user
      end)

    case result do
      {:ok, user} ->
        token = CoreAuth.generate_token(user)
        {:noreply, push_navigate(socket, to: ~p"/auth/complete_onboarding?token=#{token}")}

      {:error, :invite_already_used} ->
        {:noreply, put_flash(socket, :error, "This invite has already been used.")}

      {:error, :invite_not_found} ->
        {:noreply, put_flash(socket, :error, "Invite not found or invalid.")}

      {:error, {:user_error, _cs}} ->
        {:noreply, put_flash(socket, :error, "Could not create your account. Please try again.")}

      {:error, {:token_error, _reason}} ->
        {:noreply, put_flash(socket, :error, "Could not validate your invite. Please try again.")}

      {:error, {:waitlist_error, _cs}} ->
        {:noreply,
         put_flash(socket, :error, "We couldn't finalize onboarding. Please try again.")}
    end
  end

  defp maybe_mark_applicant_completed(nil), do: {:ok, :noop}
  defp maybe_mark_applicant_completed(applicant), do: Waitlist.set_status(applicant, :completed)

  # Keep this if you might re-enable verify later; otherwise it’s harmless.
  defp determine_step(current_step, :next, verified_email) do
    next_step_index = Enum.find_index(@step_order, &(&1 == current_step)) + 1

    case Enum.at(@step_order, next_step_index) do
      :verify_email when verified_email -> Enum.at(@step_order, next_step_index + 1)
      step when not is_nil(step) -> step
      _ -> current_step
    end
  end

  defp determine_step(current_step, :back, _verified_email) do
    prev_step_index = Enum.find_index(@step_order, &(&1 == current_step)) - 1
    Enum.at(@step_order, max(prev_step_index, 0))
  end

  defp determine_step(_, step, _), do: String.to_existing_atom(step)

  # --- Step resolution: default to :location (first step) ---
  defp get_step_from_params(%{"step" => step}), do: String.to_existing_atom(step)
  defp get_step_from_params(_params), do: :location

  # --- Seed helpers ---

  # Prefill user data from the invite session/applicant.
  defp initial_user_data(invite_email, first_name, last_name) do
    %{
      "email" => invite_email || "",
      "password" => "",
      "first_name" => first_name || "",
      "last_name" => last_name || "",
      "username" => "",
      "profile" => %{
        "bio" => nil,
        "org_name" => nil,
        "org_position" => nil,
        "birthdate" => nil,
        "location" => %{
          "locality" => "",
          "country_code" => "",
          "state_code" => "",
          "label" => "",
          "country" => "",
          "lat" => "",
          "lng" => ""
        }
      }
    }
  end
end
