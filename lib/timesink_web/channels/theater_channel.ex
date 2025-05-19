# defmodule TimesinkWeb.TheaterChannel do
#   use TimesinkWeb, :channel
#   alias TimesinkWeb.Presence

#   @impl true
#   def join("theater:" <> _id = topic, payload, socket) do
#     if authorized?(payload) do
#       {:ok, socket}
#     else
#       {:error, %{reason: "unauthorized"}}
#     end
#   end

#   # Channels can be used in a request/response fashion
#   # by sending replies to requests from the client
#   @impl true
#   def handle_in("ping", payload, socket) do
#     {:reply, {:ok, payload}, socket}
#   end

#   # It is also common to receive messages from the client and
#   # broadcast to everyone in the current topic (theater:lobby or theater:{id}).
#   @impl true
#   def handle_in("shout", payload, socket) do
#     broadcast(socket, "shout", payload)
#     {:noreply, socket}
#   end

#   def handle_info(:after_join, socket) do
#     # Track this user/socket in presence with optional metadata
#     {:ok, _} =
#       Presence.track(socket, socket.assigns.topic, socket.id, %{
#         online_at: inspect(System.system_time(:second))
#       })

#     # Push the full presence state to the client
#     push(socket, "presence_state", Presence.list(socket.assigns.topic))
#     {:noreply, socket}
#   end

#   # Add authorization logic here as required.
#   defp authorized?(_payload) do
#     true
#   end
# end
