defmodule TimesinkWeb.OnboardingLive do
  use TimesinkWeb, :live_view

  alias TimesinkWeb.Onboarding.{
    StepEmailComponent,
    StepVerifyEmailComponent,
    StepNameComponent,
    StepLocationComponent,
    StepUsernameComponent
  }

  def mount(params, _session, socket) do
    step_from_url = Map.get(params, "step", "email") |> String.to_existing_atom()

    {:ok, assign(socket, step: step_from_url, verified_email: false, user_data: %{}),
     layout: {TimesinkWeb.Layouts, :empty}}
  end

  def render(assigns) do
    ~H"""
    <div class="onboarding-container">
      <%= case @step do %>
        <% :email -> %>
          <.live_component module={StepEmailComponent} id="email_step" user_data={@user_data} />
        <% :verify_email -> %>
          <.live_component
            module={StepVerifyEmailComponent}
            id="verify_email_step"
            user_data={@user_data}
          />
        <% :name -> %>
          <.live_component module={StepNameComponent} id="name_step" user_data={@user_data} />
        <% :location -> %>
          <.live_component module={StepLocationComponent} id="location_step" user_data={@user_data} />
        <% :avatar -> %>
          <.live_component module={StepAvatarComponent} id="avatar_step" user_data={@user_data} />
        <% :username -> %>
          <.live_component module={StepUsernameComponent} id="username_step" user_data={@user_data} />
      <% end %>
    </div>
    """
  end

  def handle_info({:go_to_step, step}, socket) do
    step_atom = String.to_existing_atom(step)

    {:noreply,
     socket
     |> assign(step: step_atom)
     |> push_patch(to: "/onboarding?step=#{step}")}
  end

  def handle_info({:email_verified}, socket) do
    socket = assign(socket, verified_email: true)
    {:noreply, socket}
  end

  def handle_info({:update_user_data, user_data}, socket) do
    {:noreply, assign(socket, user_data: user_data)}
  end

  def handle_params(params, _uri, socket) do
    step_from_url =
      params["step"]
      |> case do
        nil -> :email
        step -> String.to_existing_atom(step)
      end

    # ✅ Prevent users from going back to verify_email if they are already verified
    if step_from_url == :verify_email and socket.assigns.verified_email do
      socket = assign(socket, step: :name)
      {:noreply, push_patch(socket, to: "/onboarding?step=name")}
    else
      {:noreply,
       assign(socket,
         step: enforce_step_progression(step_from_url, socket.assigns.verified_email)
       )}
    end
  end

  # ✅ No need for `get_session/2` inside this function
  defp enforce_step_progression(:email, _verified), do: :email
  defp enforce_step_progression(:verify_email, _), do: :verify_email
  defp enforce_step_progression(:verify_email, true), do: :name
  defp enforce_step_progression(:name, false), do: :email
  defp enforce_step_progression(:name, true), do: :name
  defp enforce_step_progression(:location, _), do: :location
  defp enforce_step_progression(:avatar, _), do: :avatar
  defp enforce_step_progression(:username, _), do: :username
  # Default to email if unknown
  defp enforce_step_progression(_, _), do: :email
end
