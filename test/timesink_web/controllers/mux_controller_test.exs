defmodule TimesinkWeb.MuxControllerTest do
  use TimesinkWeb.ConnCase
  alias Timesink.Storage.Blob

  describe "POST /webhooks/mux.com" do
    test "creates a new Blob from webhook 'video.asset.created'", %{conn: conn} do
      asset_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/webhooks/mux.com", %{
          "type" => "video.asset.created",
          "data" => %{
            "id" => asset_id
          }
        })

      assert %Plug.Conn{status: 200} = conn
      assert {:ok, %Blob{uri: ^asset_id}} = Blob.get_by(uri: asset_id)
    end
  end
end
