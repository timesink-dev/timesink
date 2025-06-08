defmodule Timesink.Cinema.PlaybackState do
  @moduledoc """
  Represents the real-time playback state of a theater.
  """

  @phases [:before, :playing, :intermission]

  defstruct [
    # :before | :playing | :intermission
    :phase,
    # true | false
    :started,
    # seconds (integer), offset from phase start
    :offset,
    # optional integer, seconds until phase begins
    :countdown,
    # string or UUID
    :theater_id
  ]

  @type t :: %__MODULE__{
          phase: atom(),
          started: boolean(),
          offset: non_neg_integer(),
          countdown: integer() | nil,
          theater_id: String.t()
        }

  @doc """
  Builds a new playback state.
  """
  def new(attrs \\ %{}) do
    struct(
      __MODULE__,
      Map.merge(
        %{
          phase: :before,
          started: false,
          offset: 0,
          countdown: nil,
          theater_id: nil
        },
        attrs
      )
    )
  end

  @doc """
  Returns true if phase is valid.
  """
  def valid_phase?(phase), do: phase in @phases
end
