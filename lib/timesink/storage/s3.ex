defmodule Timesink.Storage.S3 do
  @moduledoc """
  S3-centric storage functions.

  This module provides pre-configured, config-overwritable friendly functions to
  perform basic CRUD ops in S3 objects.
  """

  alias Timesink.Storage

  @spec head(
          path :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, term()} | {:error, term()}
  def head(path, opts \\ []) do
    config = merge_configs([Storage.config(), opts])

    with op <- ExAws.S3.head_object(config.bucket, path),
         {:ok, %{status_code: 200} = response} <- ExAws.request(op) do
      {:ok, response}
    else
      error -> {:error, if(not match?({:error, _}, error), do: error, else: error |> elem(1))}
    end
  end

  @spec get(
          path :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, term()} | {:error, term()}
  def get(obj_path, opts \\ []) do
    config = merge_configs([Storage.config(), opts])

    with op <- ExAws.S3.get_object(config.bucket, obj_path),
         {:ok, %{status_code: 200} = response} <- ExAws.request(op) do
      {:ok, response}
    else
      error -> {:error, if(not match?({:error, _}, error), do: error, else: error |> elem(1))}
    end
  end

  @spec put(
          upload :: Plug.Upload.t(),
          path :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, term()} | {:error, term()}
  def put(%Plug.Upload{} = upload, obj_path, opts \\ []) do
    config = merge_configs([Storage.config(), opts])
    meta = opts |> Keyword.get(:meta, [])

    obj_meta =
      meta
      |> Keyword.put(:uploaded_at, System.os_time(:second))
      |> Enum.filter(fn {_key, val} -> not is_nil(val) end)

    with {:ok, obj_body} <- File.read(upload.path),
         op <- ExAws.S3.put_object(config.bucket, obj_path, obj_body, meta: obj_meta),
         {:ok, %{status_code: 200} = response} <- ExAws.request(op) do
      {:ok, response}
    else
      error -> {:error, if(not match?({:error, _}, error), do: error, else: error |> elem(1))}
    end
  end

  @spec stream(
          upload :: Plug.Upload.t(),
          path :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, term()} | {:error, term()}
  def stream(%Plug.Upload{} = upload, obj_path, opts \\ []) do
    config = merge_configs([Storage.config(), opts])
    meta = opts |> Keyword.get(:meta, [])

    obj_meta =
      meta
      |> Keyword.put(:uploaded_at, System.os_time(:second))
      |> Enum.filter(fn {_key, val} -> not is_nil(val) end)

    with stream <- ExAws.S3.Upload.stream_file(upload.path),
         op <- ExAws.S3.upload(stream, config.bucket, obj_path, meta: obj_meta),
         {:ok, %{status_code: 200} = response} <- ExAws.request(op) do
      {:ok, response}
    else
      error -> {:error, if(not match?({:error, _}, error), do: error, else: error |> elem(1))}
    end
  end

  @spec delete(
          path :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, term()} | {:error, term()}
  def delete(path, opts \\ []) do
    config = merge_configs([Storage.config(), opts])

    with op <- ExAws.S3.delete_object(config.bucket, path),
         {:ok, %{status_code: 204} = response} <- ExAws.request(op) do
      {:ok, response}
    else
      error -> {:error, if(not match?({:error, _}, error), do: error, else: error |> elem(1))}
    end
  end

  defp merge_configs(configs) when is_list(configs) do
    configs
    |> Enum.reduce(%{}, fn item, acc -> Enum.into(item, acc) end)
  end

  @spec public_url(String.t()) :: String.t()
  def public_url(path) do
    config = Storage.config()
    "#{config.host}/#{config.bucket}/#{path}"
  end
end
