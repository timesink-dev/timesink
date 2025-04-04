defmodule Timesink.Storage.S3Test do
  use Timesink.DataCase
  import Timesink.Factory
  alias Timesink.Storage

  setup ctx do
    %{
      upload: build(:plug_upload)
    }
    |> Map.merge(ctx)
  end

  describe "head/1" do
    test "head an object", %{upload: upload} do
      {:ok, %{status_code: 200}} = Storage.S3.put(upload, upload.filename)

      assert {:ok, %{status_code: 200}} = Storage.S3.head(upload.filename)
    end
  end

  describe "get/1" do
    test "get an object", %{upload: upload} do
      {:ok, %{status_code: 200}} = Storage.S3.put(upload, upload.filename)

      assert {:ok, %{status_code: 200}} = Storage.S3.get(upload.filename)
    end
  end

  describe "put/3" do
    test "uploads a %Plug.Upload{} to S3", %{upload: upload} do
      assert {:ok, %{status_code: 200}} = Storage.S3.put(upload, upload.filename)
    end
  end

  describe "stream/3" do
    test "streams a %Plug.Upload{} to S3", %{upload: upload} do
      assert {:ok, %{status_code: 200}} = Storage.S3.stream(upload, upload.filename)
    end
  end

  describe "delete/1" do
    test "delete an object", %{upload: upload} do
      {:ok, %{status_code: 200}} = Storage.S3.put(upload, upload.filename)

      assert {:ok, %{status_code: 204}} = Storage.S3.delete(upload.filename)
    end
  end
end
