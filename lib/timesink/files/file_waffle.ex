defmodule Timesink.FileWaffle do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:original]

  def storage_dir(_version, {_file, _scope}), do: "public"
end
