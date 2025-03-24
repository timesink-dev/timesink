defmodule Timesink.Locations.Result do
  @moduledoc """
  Struct that wraps backend autocomplete results.
  """

  defstruct backend: nil, locations: []

  @type t :: %__MODULE__{
          backend: module(),
          locations: list(map())
        }
end
