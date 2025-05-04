defmodule Timesink.Repo.Migrations.AddMuxPlaybackIdIndexToBlob do
  use Ecto.Migration

  def change do
    execute """
    CREATE INDEX blobs_mux_public_playback_id_idx
    ON blob (
      ((metadata->'mux_asset'->'playback_id'->0->>'id'))
    )
    WHERE metadata->'mux_asset'->'playback_id' IS NOT NULL
    """
  end
end
