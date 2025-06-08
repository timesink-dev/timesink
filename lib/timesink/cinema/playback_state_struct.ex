defmodule Timesink.Cinema.PlaybackState do
  @moduledoc """
  Represents the real-time playback state of a theater.
  """

  @type phases :: :upcoming | :playing | :intermission
  @phases [:upcoming, :playing, :intermission]

  defstruct [
    # :upcominge | :playing | :intermission
    :phase,
    # seconds (integer), offset from phase start
    :offset,
    # optional integer, seconds until phase begins
    :countdown,
    # string or UUID
    :theater_id
  ]

  @type t :: %__MODULE__{
          phase: phases(),
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
          phase: :upcoming,
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
