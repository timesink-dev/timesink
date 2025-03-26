defmodule Timesink.HTTP.FinchClient do
  @moduledoc """
  The default HTTP implementation using Finch.
  """

  @behaviour Timesink.HTTP

  @impl true
  def request(request) do
    Finch.request(request, Timesink.Finch)
  end
end
