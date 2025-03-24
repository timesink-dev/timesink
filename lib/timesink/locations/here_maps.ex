defmodule Timesink.Locations.HereMaps do
  @behaviour Timesink.Locations.Backend
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

    [%Result{backend: __MODULE__, locations: locations}]
  end

  defp parse_response(_), do: []
end
