defmodule Timesink.Presence do
  use Phoenix.Presence,
    otp_app: :timesink,
    pubsub_server: Timesink.PubSub
end
