defmodule Timesink.Waitlist do
  @moduledoc """
  The Waitlist context.
  """

  alias Timesink.Waitlist.Applicant
  alias Timesink.Waitlist.Mail
  alias Timesink.Repo
  alias Timesink.Waitlist.Applicant
  import Ecto.Query, only: [from: 2]

  @max_wave_size 5

  @doc """
  Returns the number of spots remaining in the current wave.

  ## Examples

      iex> get_wave_spots_remaining()
      50
  """
  @spec get_wave_spots_remaining() :: integer()
  def get_wave_spots_remaining() do
    # Estimate available spots based on pending applicants
    pending_applicants =
      Repo.aggregate(from(a in Applicant, where: a.status == ^:pending), :count, :id)

    spots_remaining = max(@max_wave_size, @max_wave_size - pending_applicants)

    spots_remaining
  end

  @doc """
  Returns the estimated wait time and message for an applicant.

  ## Examples

      iex> get_waitlist_message("
      %{
        estimated_wait_time: "Expected invite in less than a day.",
        message: "You're next in line! Expect an invite very soon."
      }
  """
  @spec get_waitlist_message(String.t()) :: map()
  def get_waitlist_message(applicant_email) do
    position = get_waitlist_position(applicant_email)

    wait_time = estimate_wait_time(position)

    message =
      cond do
        position == -1 -> nil
        position in 1..2 -> "You're next in line! Expect an invite very soon."
        position in 3..20 -> "You're in the top 10! Stay tuned for your invite."
        true -> "You're on the priority waitlist. We'll notify you when it's your turn!"
      end

    %{message: message, estimated_wait_time: wait_time}
  end

  defp get_waitlist_position(email) do
    query = from a in Applicant, where: a.status == ^:pending, order_by: a.inserted_at
    waitlist = Repo.all(query)

    case Enum.find_index(waitlist, fn a -> a.email == email end) do
      nil -> -1
      index -> index + 1
    end
  end

  defp estimate_wait_time(position) do
    cond do
      position <= 10 -> "less than a day"
      position <= 50 -> "in 2-3 days"
      true -> "in 3-5 days"
    end
  end

  @doc """
  Creates a new applicant and adds them to the waitlist.

  ## Examples

      iex> join(%{"first_name" => "Jose", "last_name" => "Val Del Omar", "email" => "valdelomar@gmail.com"})
      {:ok, %Timesink.Waitlist.Applicant{…}}
  """
  @spec join(params :: map()) ::
          {:ok, Applicant.t()} | {:error, Ecto.Changeset.t()}

  def join(params) do
    with {:ok, applicant} <-
           Applicant.create(params) do
      Mail.send_waitlist_confirmation(applicant.email, applicant.first_name)
      {:ok, applicant}
    end
  end
end
