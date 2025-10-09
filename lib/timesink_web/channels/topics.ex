defmodule TimesinkWeb.PubSubTopics do
  def scheduler_topic(theater_id), do: "scheduler:theater:#{theater_id}"
  def presence_topic(theater_id), do: "presence:theater:#{theater_id}"
  def phase_change_topic(theater_id), do: "phase_change:theater:#{theater_id}"
  def profile_update_topic(user_id), do: "user:#{user_id}:profile"
end
