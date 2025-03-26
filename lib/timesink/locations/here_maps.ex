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
  @http Application.compile_env!(:timesink, :http_client)

  def name, do: "here_maps"

  def compute(query, _opts \\ []) do
    query_params =
      URI.encode_query(%{
        q: query,
        apiKey: @api_key,
        types: "city",
        limit: 5
      })

    url = "#{@suggest_endpoint}?#{query_params}"
    req = Finch.build(:get, url)

    case @http.request(req) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> parse_response()

      _ ->
        []
    end
  end

  def lookup(place_id) do
    query_params =
      URI.encode_query(%{
        id: place_id,
        apiKey: @api_key
      })

    url = "#{@lookup_endpoint}?#{query_params}"
    req = Finch.build(:get, url)

    case @http.request(req) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        with %{"position" => %{"lat" => lat, "lng" => lng}} <- Jason.decode!(body) do
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
          label: address["label"],
          city: address["city"],
          state_code: address["stateCode"],
          country: address["countryName"],
          country_code: address["countryCode"],
          place_id: item["id"],
          lat: nil,
          lng: nil
        }
      end)

    [%Result{provider: __MODULE__, locations: locations}]
  end

  defp parse_response(_), do: []
end
