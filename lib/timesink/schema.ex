defmodule Timesink.Schema do
  @moduledoc """
  TimeSink-specific schema customizations.
  """

  defmacro __using__(_opts) do
    quote do
      import Ecto.Query, only: [from: 1, select: 3]
      alias Timesink.Repo

      @spec query(f :: (Ecto.Query.t() -> Ecto.Query.t())) ::
              {:ok, list(struct())} | {:error, term()}
      def query(f) do
        query =
          from(s in __MODULE__)
          |> select([s], s)
          |> then(f)

        {:ok, Repo.all(query)}
      rescue
        error -> {:error, error}
      end
    end
  end
end
