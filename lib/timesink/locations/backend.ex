# defmodule Timesink.Locations.Backend do
#   @callback name() :: String.t()
#   @callback compute(query :: String.t(), point :: String.t(), opts :: Keyword.t()) :: [
#               %Timesink.Locations.Result{}
#             ]
# end
