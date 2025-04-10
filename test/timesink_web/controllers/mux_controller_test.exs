defmodule TimesinkWeb.MuxControllerTest do
  use TimesinkWeb.ConnCase
  import Timesink.Factory
  alias Timesink.Storage.Blob
  alias Timesink.Storage.MuxUpload

  @webhook_key "MUX_WEBHOOK_KEY/DEV"

  describe "POST /webhooks/mux.com/:webhook_key" do
    test "requires a valid webhook key", %{conn: conn} do
      params = %{
        "type" => "video.asset.created",
        "data" => %{
          "id" => Ecto.UUID.generate()
        }
      }

      conn = post(conn, ~p"/api/webhooks/mux.com/#{Ecto.UUID.generate()}", params)

      assert %Plug.Conn{status: 403} = conn
    end

    test "creates a new Blob on 'video.asset.created'", %{conn: conn} do
      asset_id = Ecto.UUID.generate()

      params = %{
        "type" => "video.asset.created",
        "data" => %{
          "id" => asset_id
        }
      }

      conn = post(conn, ~p"/api/webhooks/mux.com/#{@webhook_key}", params)

      assert %Plug.Conn{status: 200} = conn
      assert {:ok, %Blob{uri: ^asset_id}} = Blob.get_by(uri: asset_id)
    end

    test "updates MuxUpload status on 'video.upload.errored', 'video.upload.cancelled'", %{
      conn: conn
    } do
      for {status, event_type} <- [
            errored: "video.upload.errored",
            cancelled: "video.upload.cancelled"
          ] do
        up = insert(:mux_upload, mux_id: Ecto.UUID.generate())

        params = %{
          "type" => event_type,
          "data" => %{
            "id" => up.mux_id
          }
        }

        resp_conn = post(conn, ~p"/api/webhooks/mux.com/#{@webhook_key}", params)

        assert %Plug.Conn{status: 200} = resp_conn
        assert {:ok, %{status: ^status}} = MuxUpload.get_by(mux_id: up.mux_id)
      end
    end
  end
end
