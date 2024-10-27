defmodule TimesinkWeb.Live.ResponsiveHelpers do
  use Phoenix.LiveView

  # This function is called in the on_mount to set a default device_type.
  def assign_device_type(socket) do
    # Use the device_type if already assigned, or default to "desktop"
    device_type = Map.get(socket.assigns, :device_type, "desktop")
    assign(socket, :device_type, device_type)
  end

  # This function processes the `device_type` event from the JavaScript hook.
  def handle_event("update_breakpoint", %{"device_type" => device_type}, socket) do
    # Assign the new device_type from the event payload
    IO.puts(device_type)
    {:noreply, assign(socket, :device_type, device_type)}
  end

  # Function to determine classes based on device type (called in the render function)
  def responsive_class(classes, device_type) do
    # Merge the common classes with the device-specific classes
    new_key = String.to_atom(device_type)
    Enum.join([classes[:common], classes[new_key]], " ")
  end
end
