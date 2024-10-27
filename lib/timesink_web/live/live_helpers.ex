defmodule TimesinkWeb.Live.LiveHelpers do
  # import Phoenix.LiveView
  alias TimesinkWeb.Live.ResponsiveHelpers

  # Handle :assign_device_type
  def on_mount(:assign_device_type, _params, _session, socket) do
    # Call your ResponsiveHelpers function to assign the device type
    socket = ResponsiveHelpers.assign_device_type(socket)
    {:cont, socket}
  end

  # Fallback clause to handle other cases or errors gracefully
  def on_mount(_any_other, _params, _session, socket) do
    {:cont, socket}
  end
end
