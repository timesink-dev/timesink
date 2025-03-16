defmodule TimesinkWeb.OnboardingLive do
  use TimesinkWeb, :live_view

  alias Timesink.Accounts

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
          "locality" => "Los Angeles",
          # Must be a valid ISO 3166 country code
          "country" => "USA",
          "lat" => "34.0522",
          "lng" => "-118.2437"
        }
      }
    }

    {:ok,
     socket
     |> assign(
       invite_token: invite_token,
       step: :email,
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
    step_from_url =
      params["step"]
      |> case do
        nil -> :email
        step -> String.to_existing_atom(step)
      end

    # Prevent users from manually going back to verify_email if already verified
    new_step =
      case {step_from_url, socket.assigns.verified_email} do
        {:verify_email, true} -> :name
        _ -> step_from_url
      end

    {:noreply, assign(socket, step: new_step)}
  end

  def handle_info({:go_to_step, direction}, socket) do
    new_step = determine_step(socket.assigns.step, direction, socket.assigns.verified_email)
    {:noreply, assign(socket, step: new_step) |> push_patch(to: "/onboarding?step=#{new_step}")}
  end

  def handle_info({:update_user_data, %{params: params}}, socket) do
    socket = assign(socket, user_data: Map.merge(socket.assigns.user_data, params))
    IO.inspect(socket.assigns.user_data, label: "Updated user_data")

    {:noreply, socket}
  end

  def handle_info(:email_verified, socket) do
    socket = socket |> assign(verified_email: true)
    {:noreply, socket}
  end

  def handle_info({:complete_onboarding, %{params: user_create_params}}, socket) do
    with {:ok, _} <- Accounts.create_user(user_create_params) do
      {:noreply, redirect(socket, to: "/")}
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
