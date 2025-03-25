defmodule Timesink.Locations.HereMaps do
  @moduledoc """
  A location autocomplete provider using the HERE Maps API.

  This module implements the `Timesink.Locations.Provider` behaviour and is responsible for:

  - Sending city-level autocomplete queries to HERE Maps.
  - Decoding and normalizing the API responses into a structured format.
  - Returning results wrapped in a `%Locations.Result{}` struct for compatibility with the broader `Locations` system.

  ## Configuration

  You must set your API key in your config (e.g. `config/dev.exs`):

      config :timesink, here_maps_api_key: "your-api-key"

  ## Example

      iex> HereMaps.compute("Los Ange")
      [%Locations.Result{provider: Timesink.Locations.HereMaps, locations: [%{city: ..., country_code: ..., ...}]}]

  Note: `lat` and `lng` are currently stubbed until full geocoding is implemented.
  """

  @behaviour Timesink.Locations.Provider
  alias Timesink.Locations.Result

  @endpoint "https://autocomplete.search.hereapi.com/v1/autocomplete"
  @api_key Application.compile_env(:timesink, :here_maps_api_key)

  def name, do: "here_maps"

  def compute(query, _opts \\ []) do
    query_params =
      URI.encode_query(%{
        q: query,
        apiKey: @api_key,
        types: "city",
        limit: 5
      })

    case Finch.build(:get, "#{@endpoint}?#{query_params}")
         |> Finch.request(Timesink.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> parse_response()

      _ ->
        []
    end
  end

  defp parse_response(%{"items" => items}) do
    locations =
      Enum.map(items, fn item ->
        address = item["address"]

        %{
          # Full formatted label
          label: address["label"],
          # City (e.g., "Los Angeles")
          city: address["city"],
          # Full state name (e.g., "California")
          state: address["state"],
          # Abbreviated (e.g., "CA")
          state_code: address["stateCode"],
          # Full country name
          country: address["countryName"],
          # ISO code (e.g., "USA")
          country_code: address["countryCode"],
          place_id: item["id"],
          lat: "34.5",
          lng: "32.3"
        }
      end)

    [%Result{provider: __MODULE__, locations: locations}]
  end

  defp parse_response(_), do: []
end
