defmodule Timesink.Locations.HereMaps do
  @moduledoc """
  A location autocomplete provider powered by the HERE Maps API.

  This module implements the `Timesink.Locations.Provider` behaviour and is designed
  to integrate seamlessly with the broader `Timesink.Locations` infrastructure.

  It provides two main features:

  * `compute/2` — Autocomplete suggestions for city-level searches
  * `lookup/1` — Detailed lookup using `place_id` to fetch precise latitude and longitude

  Each call is normalized into `%Timesink.Locations.Result{}` structs,
  and is compatible with the caching and backend dispatch system in `Timesink.Locations`.

  ## Configuration

  You must configure your HERE Maps API key and HTTP client module (for testability):
  """

  @behaviour Timesink.Locations.Provider
  alias Timesink.Locations.Result

  @suggest_endpoint "https://autocomplete.search.hereapi.com/v1/autocomplete"
  @lookup_endpoint "https://lookup.search.hereapi.com/v1/lookup"
  @http Application.compile_env!(:timesink, :http_client)

  @impl true
  def name, do: "here_maps"

  @impl true
  def compute(query, _opts \\ []) do
    query_params =
      URI.encode_query(%{
        q: query,
        apiKey: api_key(),
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

  @spec lookup(any()) ::
          {:error, :invalid_response | :request_failed} | {:ok, %{lat: any(), lng: any()}}
  def lookup(place_id) do
    query_params =
      URI.encode_query(%{
        id: place_id,
        apiKey: api_key()
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

  defp api_key, do: Application.fetch_env!(:timesink, :here_maps_api_key)
end
