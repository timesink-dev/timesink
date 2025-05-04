defmodule Timesink.StorageTest do
  use Timesink.DataCase
  import Timesink.Factory
  alias Timesink.Storage
  alias Timesink.Storage.Blob
  alias Timesink.Storage.Attachment
  alias ExAws.S3

  describe "create_blob/2" do
    setup ctx do
      %{
        user: insert(:user),
        upload: build(:plug_upload)
      }
      |> Map.merge(ctx)
    end

    test "uploads a %Plug.Upload{} to S3", %{upload: upload} do
      config = Storage.config()
      upload_stat = File.stat!(upload.path)

      assert {:ok, %Blob{} = blob} = Storage.create_blob(upload)
      assert blob.size == upload_stat.size

      assert {:ok, %{status_code: 200, headers: headers}} =
               S3.head_object(config.bucket, blob.uri) |> ExAws.request()

      obj_content_length =
        headers
        |> Enum.find(fn {h, _} -> String.downcase(h) == "content-length" end)
        |> elem(1)

      assert "#{upload_stat.size}" == "#{obj_content_length}"
    end
  end

  describe "create_attachment/3" do
    setup ctx do
      %{
        upload: build(:plug_upload)
      }
      |> Map.merge(ctx)
    end

    test "creates an attachment out of a %Plug.Upload{}", %{upload: upload} do
      film = insert(:film)

      assert {:ok, %Attachment{} = att} = Storage.create_attachment(film, :poster, upload)
      assert att.name == "poster"
      assert att.blob_id != nil
      assert att.assoc_id == film.id
    end
  end
end
