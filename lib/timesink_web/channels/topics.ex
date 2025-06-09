defmodule TimesinkWeb.PubSubTopics do
  def scheduler_topic(theater_id), do: "scheduler:theater:#{theater_id}"
  def presence_topic(theater_id), do: "presence:theater:#{theater_id}"
  def phase_change_topic(theater_id), do: "phase_change:theater:#{theater_id}"
end
