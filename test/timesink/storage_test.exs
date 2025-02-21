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
               S3.head_object(config.bucket, blob.path) |> ExAws.request()

      obj_content_length =
        headers
        |> Enum.find(fn {h, _} -> String.downcase(h) == "content-length" end)
        |> elem(1)

      assert "#{upload_stat.size}" == "#{obj_content_length}"
    end

    test "accept an opt `user_id`", %{user: %{id: uid}, upload: upload} do
      assert {:ok, %{user_id: ^uid}} = Storage.create_blob(upload, user_id: uid)
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
      params = params_for(:attachment) |> Map.take([:target_schema, :target_id, :name])

      assert {:ok, %Attachment{}} = Storage.create_attachment(upload, params)
    end
  end
end
