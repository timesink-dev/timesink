defmodule Timesink.Locations.Result do
  @moduledoc """
  Struct that wraps provider autocomplete results.
  """

  defstruct provider: nil, locations: []

  @type t :: %__MODULE__{
          provider: module(),
          locations: list(map())
        }
end
