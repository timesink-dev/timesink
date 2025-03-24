defmodule Timesink.Locations.Backend do
  @moduledoc """
  Defines the behaviour that all location autocomplete backends should implement.
  """

  @callback name() :: String.t()
  @callback compute(query :: String.t(), opts :: Keyword.t()) :: [%Timesink.Locations.Result{}]
end
