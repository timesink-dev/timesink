defmodule TimesinkWeb.OnboardingLive do
  use TimesinkWeb, :live_view

  alias Timesink.Accounts
  alias Timesink.Token
  alias Timesink.Auth, as: CoreAuth
  alias TimesinkWeb.Components.Stepper

  alias TimesinkWeb.Onboarding.{
    StepEmailComponent,
    StepVerifyEmailComponent,
    StepNameComponent,
    StepLocationComponent,
    StepUsernameComponent
  }

  # Define step order and component mappings
  @step_order [:email, :verify_email, :name, :location, :username]
  @steps %{
    email: StepEmailComponent,
    verify_email: StepVerifyEmailComponent,
    name: StepNameComponent,
    location: StepLocationComponent,
    username: StepUsernameComponent
  }

  def mount(_params, session, socket) do
    invite_token = session["invite_token"]

    user_data = %{
      "email" => "",
      "password" => "",
      "first_name" => "",
      "last_name" => "",
      "username" => "",
      "profile" => %{
        "avatar_url" => nil,
        "bio" => "Film enthusiast and creator.",
        "org_name" => "Film Society",
        "org_position" => "Director",
        "birthdate" => "1990-05-14",
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

    {:ok,
     socket
     |> assign(
       invite_token: invite_token,
       step: @step_order |> hd(),
       verified_email: false,
       user_data: user_data,
       steps: @steps
     ), layout: {TimesinkWeb.Layouts, :empty}}
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

    if Token.is_valid?(invite_token) do
      step_from_url =
        params["step"]
        |> case do
          nil -> @step_order |> hd()
          step -> String.to_existing_atom(step)
        end

      # Prevent users from manually going back to verify_email if already verified
      new_step =
        case {step_from_url, socket.assigns.verified_email} do
          {:verify_email, true} -> :name
          _ -> step_from_url
        end

      {:noreply, assign(socket, step: new_step)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Invalid invite token. Please check the link and try again.")
       |> redirect(to: "/")}
    end
  end

  def handle_info({:go_to_step, direction}, socket) do
    new_step = determine_step(socket.assigns.step, direction, socket.assigns.verified_email)
    {:noreply, assign(socket, step: new_step) |> push_patch(to: "/onboarding?step=#{new_step}")}
  end

  def handle_info({:update_user_data, %{params: params}}, socket) do
    socket = assign(socket, user_data: Map.merge(socket.assigns.user_data, params))

    {:noreply, socket}
  end

  def handle_info(:email_verified, socket) do
    socket = socket |> assign(verified_email: true)
    {:noreply, socket}
  end

  def handle_info({:complete_onboarding, %{params: user_create_params}}, socket) do
    with {:ok, user} <- Accounts.create_user(user_create_params),
         {:ok, _token} <- Token.invalidate_token(socket.assigns.invite_token) do
      token = CoreAuth.generate_token(user)

      {:noreply,
       push_navigate(socket,
         to: ~p"/auth/complete_onboarding?token=#{token}"
       )}
    else
      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "❌ User Creation Error")

        {:noreply, socket |> put_flash(:error, "Something went wrong. Please try again.")}
    end
  end

  defp determine_step(current_step, :next, verified_email) do
    next_step_index = Enum.find_index(@step_order, &(&1 == current_step)) + 1

    case Enum.at(@step_order, next_step_index) do
      # Skip verify_email if already verified
      :verify_email when verified_email -> :name
      step when not is_nil(step) -> step
      # Stay on the last step if already there
      _ -> current_step
    end
  end

  defp determine_step(current_step, :back, _verified_email) do
    prev_step_index = Enum.find_index(@step_order, &(&1 == current_step)) - 1

    # Prevent stepping back before first step
    Enum.at(@step_order, max(prev_step_index, 0))
  end

  defp determine_step(_, step, _), do: String.to_existing_atom(step)
end
