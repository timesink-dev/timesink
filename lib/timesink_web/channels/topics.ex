defmodule TimesinkWeb.PubSubTopics do
  def scheduler_topic(theater_id), do: "scheduler:#{theater_id}"
  def presence_topic(theater_id), do: "presence:theater:#{theater_id}"
end
