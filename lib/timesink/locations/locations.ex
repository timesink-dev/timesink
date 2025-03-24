defmodule Timesink.Locations do
  @moduledoc """
  Provides geolocation autocomplete features using the HERE Maps API.
  """

  require Logger

  use Tesla,
    adapter: {Tesla.Adapter.Finch, name: Timesink.Finch}

  plug Tesla.Middleware.BaseUrl, "https://autocomplete.search.hereapi.com/v1"
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 60_000

  @api_key Application.get_env(
             :timesink,
             :here_maps_api_key,
             "NTDK8IwwPP7AbbjA44g7Tbt8ZH94rq3rnGPumxImBPM"
           )

  @doc """
  Given a partial city or location string, returns a list of suggested cities.

  ## Example:
      iex> Locations.autocomplete_city("Los Ange")
      [%{
        city: "Los Angeles",
        country: "USA",
        label: "Los Angeles, CA, United States",
        lat: 34.0522,
        lng: -118.2437
      }, ...]
  """
  def autocomplete_city(input) when is_binary(input) do
    query = [
      q: input,
      apiKey: @api_key,
      types: "city"
      # limit: 5
    ]

    IO.inspect(query, label: "Query heaaare")
    IO.inspect(@api_key, label: "API Key heaaare")

    Logger.debug("Sending request to HERE with query: #{inspect(query)}")

    case get("/autocomplete", query: query) do
      {:ok, %Tesla.Env{status: 200, body: %{"items" => items}}} ->
        IO.inspect(items, label: "Items heaaare")

        suggestions =
          Enum.map(items, fn item ->
            address = item["address"] || %{}

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
              # Keep this if you want to enrich with `/lookup` later
              place_id: item["id"],
              lat: "45.3",
              lng: "34.3"
            }
          end)

        IO.inspect(suggestions, label: "Suggestions heaaare")

        {:ok, suggestions}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("HERE API error [#{status}]: #{inspect(body)}")
        {:error, :api_error}

      {:error, reason} ->
        Logger.error("HERE API request failed: #{inspect(reason)}")
        {:error, :request_failed}
    end
  end
end
