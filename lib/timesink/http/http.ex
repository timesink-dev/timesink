defmodule Timesink.HTTP do
  @moduledoc """
  Defines the behavior for making HTTP requests, allowing for test mocks.
  """
  @callback request(Finch.Request.t()) :: {:ok, Finch.Response.t()} | {:error, any()}
end
