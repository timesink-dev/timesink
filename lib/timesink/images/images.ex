defmodule Timesink.Images do
  @moduledoc "App-level image transforms using libvips via Vix."
  alias Vix.Vips.{Operation, Image}

  @type variant_name :: atom()
  @type variant_spec :: %{
          resize: {:fill | :limit, pos_integer(), pos_integer()},
          format: :webp | :avif | :jpeg | :png,
          quality: pos_integer()
        }

  @type spec :: %{
          accept_exts: [String.t()],
          max_bytes: pos_integer() | nil,
          variants: %{variant_name() => variant_spec()}
        }

  @spec process_variants!(Plug.Upload.t(), spec()) ::
          %{variant_name() => %{path: String.t(), content_type: String.t()}}
  def process_variants!(%Plug.Upload{} = upload, %{variants: variants} = spec) do
    validate_upload!(upload, spec)

    Enum.into(variants, %{}, fn {name, cfg} ->
      # ----- derive target + output paths -----
      {w, h, crop?} =
        case cfg.resize do
          # cover (center-crop)
          {:fill, ww, hh} -> {ww, hh, true}
          # contain (no crop)
          {:limit, ww, hh} -> {ww, hh, false}
        end

      fmt = (cfg[:format] || :webp) |> to_string()
      q = cfg[:quality] || 82
      out = "#{Path.rootname(upload.path)}-#{name}.#{fmt}"

      # ----- decode from buffer (avoid loader issues with extensionless temp files) -----
      bin = File.read!(upload.path)
      {:ok, src0} = Image.new_from_buffer(bin)

      # autorotate (extract image from return tuple shape your vix returns)
      src =
        case Operation.autorot(src0) do
          {:ok, {img, _meta}} -> img
          {:ok, img} -> img
          {:error, _} -> src0
        end

      # ----- compute scale (keep aspect) -----
      iw = Image.width(src)
      ih = Image.height(src)
      sx = w / max(iw, 1)
      sy = h / max(ih, 1)
      scale = if crop?, do: max(sx, sy), else: min(sx, sy)

      # ----- resize -----
      {:ok, resized} = Operation.resize(src, scale)

      # ----- optional center-crop to exact box for :fill -----
      final =
        if crop? do
          rw = Image.width(resized)
          rh = Image.height(resized)
          left = max(div(rw - w, 2), 0)
          top = max(div(rh - h, 2), 0)
          cw = min(w, rw)
          ch = min(h, rh)
          {:ok, cropped} = Operation.extract_area(resized, left, top, cw, ch)
          cropped
        else
          resized
        end

      # ----- write (saver inferred from extension); strip metadata; apply quality -----
      :ok = Image.write_to_file(final, out, Q: q, strip: true)

      {name, %{path: out, content_type: content_type_for(out)}}
    end)
  end

  defp validate_upload!(%Plug.Upload{filename: fnm, path: path}, %{
         accept_exts: exts,
         max_bytes: max
       }) do
    ext = String.downcase(Path.extname(fnm || ""))
    {:ok, stat} = File.stat(path)
    if max && stat.size > max, do: raise("image too large")
    if exts && ext not in exts, do: raise("bad extension")
    :ok
  end

  defp content_type_for(path) do
    case String.downcase(Path.extname(path)) do
      ".webp" -> "image/webp"
      ".avif" -> "image/avif"
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      _ -> "application/octet-stream"
    end
  end
end
