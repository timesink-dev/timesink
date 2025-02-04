defmodule Timesink.Storage.S3 do
  @moduledoc """
  S3-centric storage functions.
  """

  alias Timesink.Storage

  # - [x] def put
  # - [x] def get
  # - [x] def head
  # - [ ] def del
  # - [ ] def stream

  @spec put(
          upload :: Plug.Upload.t(),
          params :: %{
            :path => String.t(),
            optional(:blob_id) => Ecto.UUID.t()
          },
          opts :: Keyword.t()
        ) ::
          {:ok, term()} | {:error, term()}
  def put(%Plug.Upload{} = upload, %{} = params, opts \\ []) do
    config = Storage.config()
    blob_id = params |> Map.get(:blob_id)

    prefix = "#{Keyword.get(opts, :prefix) || config.prefix}"
    obj_path = Path.join([prefix, params.path])

    obj_meta =
      [blob_id: blob_id, uploaded_at: System.os_time(:millisecond)]
      |> Enum.filter(fn {_key, val} -> not is_nil(val) end)

    with {:ok, obj_body} <- File.read(upload.path),
         op <- ExAws.S3.put_object(config.bucket, obj_path, obj_body, meta: obj_meta),
         {:ok, %{status_code: 200} = response} <- ExAws.request(op) do
      {:ok,
       response
       |> Map.put(:path, obj_path)
       |> Map.put(:blob_id, obj_meta |> Keyword.get(:blob_id))
       |> Map.put(:uploaded_at, obj_meta |> Keyword.get(:uploaded_at))}
    else
      error -> {:error, if(not match?({:error, _}, error), do: error, else: error |> elem(1))}
    end
  end

  @spec stream(
          upload :: Plug.Upload.t(),
          params :: %{
            :path => String.t(),
            optional(:blob_id) => Ecto.UUID.t()
          },
          opts :: Keyword.t()
        ) ::
          {:ok, term()} | {:error, term()}
  def stream(%Plug.Upload{} = upload, %{} = params, opts \\ []) do
    config = Storage.config()
    blob_id = params |> Map.get(:blob_id)

    prefix = "#{Keyword.get(opts, :prefix) || config.prefix}"
    obj_path = Path.join([prefix, params.path])

    obj_meta =
      [blob_id: blob_id, uploaded_at: System.os_time(:millisecond)]
      |> Enum.filter(fn {_key, val} -> not is_nil(val) end)

    with stream <- ExAws.S3.Upload.stream_file(upload.path),
         op <- ExAws.S3.upload(stream, config.bucket, obj_path, meta: obj_meta),
         {:ok, %{status_code: 200} = response} <- ExAws.request(op) do
      {:ok, response}
    else
      error -> {:error, if(not match?({:error, _}, error), do: error, else: error |> elem(1))}
    end
  end

  @spec head(abs_path :: String.t()) ::
          {:ok, term()} | {:error, term()}
  def head(abs_path) do
    config = Storage.config()

    with op <- ExAws.S3.head_object(config.bucket, abs_path),
         {:ok, %{status_code: 200} = response} <- ExAws.request(op) do
      {:ok, response}
    else
      error -> {:error, if(not match?({:error, _}, error), do: error, else: error |> elem(1))}
    end
  end

  @spec get(abs_path :: String.t()) ::
          {:ok, term()} | {:error, term()}
  def get(abs_path) do
    config = Storage.config()

    with op <- ExAws.S3.get_object(config.bucket, abs_path),
         {:ok, %{status_code: 200} = response} <- ExAws.request(op) do
      {:ok, response}
    else
      error -> {:error, if(not match?({:error, _}, error), do: error, else: error |> elem(1))}
    end
  end

  @spec delete(abs_path :: String.t()) ::
          {:ok, term()} | {:error, term()}
  def delete(abs_path) do
    config = Storage.config()

    with op <- ExAws.S3.delete_object(config.bucket, abs_path),
         {:ok, %{status_code: 204} = response} <- ExAws.request(op) do
      {:ok, response}
    else
      error -> {:error, if(not match?({:error, _}, error), do: error, else: error |> elem(1))}
    end
  end
end
