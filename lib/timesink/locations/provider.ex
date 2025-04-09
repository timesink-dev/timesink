defmodule Timesink.Locations.Provider do
  @moduledoc """
  Defines the behaviour that all location autocomplete providers should implement.
  """
  @callback name() :: String.t()
  @callback compute(query :: String.t(), opts :: Keyword.t()) :: [%Timesink.Locations.Result{}]
end
