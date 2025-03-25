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

  @suggest_endpoint "https://autocomplete.search.hereapi.com/v1/autocomplete"
  @lookup_endpoint "https://lookup.search.hereapi.com/v1/lookup"
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

    case Finch.build(:get, "#{@suggest_endpoint}?#{query_params}")
         |> Finch.request(Timesink.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> parse_response()

      _ ->
        []
    end
  end

  def lookup(place_id) do
    query =
      URI.encode_query(%{
        id: place_id,
        apiKey: @api_key
      })

    IO.inspect(query, label: "lookup query")
    IO.inspect("#{@lookup_endpoint}?#{query}", label: "lookup url")

    case Finch.build(:get, "#{@lookup_endpoint}?#{query}")
         |> Finch.request(Timesink.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        with %{"position" => %{"lat" => lat, "lng" => lng}} <- Jason.decode!(body) do
          IO.inspect({lat, lng}, label: "lat/lng")
          {:ok, %{lat: lat, lng: lng}}
        else
          _ -> {:error, :invalid_response}
        end

      _ ->
        {:error, :request_failed}
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
