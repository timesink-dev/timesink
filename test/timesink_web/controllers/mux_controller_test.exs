defmodule TimesinkWeb.MuxControllerTest do
  use TimesinkWeb.ConnCase
  import Timesink.Factory
  import Ecto.Query
  alias Timesink.Storage.Blob
  alias Timesink.Storage.Attachment
  alias Timesink.Storage.MuxUpload

  @webhook_key System.get_env("TIMESINK_TEST_MUX_WEBHOOK_KEY", "MUX_WEBHOOK_KEY_TEST")

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

    test "attaches the video Blob on the Film on 'video.asset.ready'", %{conn: conn} do
      film = insert(:film)

      upload_id = Ecto.UUID.generate()
      asset_id = Ecto.UUID.generate()
      blob_url = "https://test.video.url/#{asset_id}"

      insert(:mux_upload, %{
        upload_id: upload_id,
        url: blob_url,
        meta: %{"film_id" => film.id}
      })

      params = %{
        "type" => "video.asset.ready",
        "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "data" => %{
          "id" => asset_id,
          "upload_id" => upload_id,
          "playback_ids" => ["mock_playback_id"],
          "meta" => %{"title" => "Test Video"}
        }
      }

      conn = post(conn, ~p"/api/webhooks/mux.com/#{@webhook_key}", params)
      assert %Plug.Conn{status: 200} = conn

      assert {:ok, blob} =
               Blob.get_by(uri: blob_url)

      assert blob.metadata["mux_asset"]["asset_id"] == asset_id
      assert blob.metadata["film_title"] == film.title

      blob_id = blob.id
      film_id = film.id

      assert [%Attachment{blob_id: ^blob_id, assoc_id: ^film_id, name: "video"}] =
               Timesink.Repo.all(
                 from(a in {"film_attachment", Attachment},
                   where: a.blob_id == ^blob_id and a.assoc_id == ^film_id and a.name == "video"
                 )
               )
    end

    test "deletes the video attachment and Blob on a Film if mux asset is deleted on 'video.asset.deleted'",
         %{conn: conn} do
      film = insert(:film)
      asset_id = Ecto.UUID.generate()

      blob =
        insert(:blob,
          service: :mux,
          checksum: "dummy-checksum",
          uri: "https://test.video.url/#{asset_id}",
          metadata: %{
            "mux_asset" => %{
              "asset_id" => asset_id,
              "upload_id" => "dummy-upload",
              "playback_id" => ["fake"],
              "upload_title" => "test",
              "uploaded_at" => DateTime.utc_now() |> DateTime.to_iso8601()
            },
            "film_title" => film.title
          }
        )

      {:ok, _attachment} = Timesink.Cinema.Film.attach_video(film, blob)

      # Confirm setup: Blob exists and one film attachment exists
      assert Timesink.Repo.get!(Timesink.Storage.Blob, blob.id)

      blob_id = blob.id
      film_id = film.id

      assert Timesink.Repo.aggregate(
               from(a in {"film_attachment", Attachment},
                 where: a.blob_id == ^blob_id and a.assoc_id == ^film_id and a.name == "video"
               ),
               :count,
               :id
             ) == 1

      params = %{
        "type" => "video.asset.deleted",
        "data" => %{"id" => asset_id}
      }

      conn = post(conn, "/api/webhooks/mux.com/#{@webhook_key}", params)
      assert conn.status == 200

      # Blob should be removed
      assert {:error, :not_found} = Timesink.Storage.Blob.get(blob.id)

      # Attachment should be renoved
      assert Timesink.Repo.aggregate(
               from(a in {"film_attachment", Attachment},
                 where: a.blob_id == ^blob_id and a.assoc_id == ^film_id and a.name == "video"
               ),
               :count,
               :id
             ) == 0
    end

    test "updates MuxUpload status on 'video.upload.errored', 'video.upload.cancelled'", %{
      conn: conn
    } do
      for {status, event_type} <- [
            errored: "video.upload.errored",
            cancelled: "video.upload.cancelled"
          ] do
        up = insert(:mux_upload, upload_id: Ecto.UUID.generate())

        params = %{
          "type" => event_type,
          "data" => %{
            "id" => up.upload_id
          }
        }

        resp_conn = post(conn, ~p"/api/webhooks/mux.com/#{@webhook_key}", params)

        assert %Plug.Conn{status: 200} = resp_conn
        assert {:ok, %{status: ^status}} = MuxUpload.get_by(upload_id: up.upload_id)
      end
    end
  end
end
