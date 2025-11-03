defmodule Timesink.Waitlist do
  @moduledoc """
  The Waitlist context.
  """

  alias Timesink.Waitlist.Applicant
  alias Timesink.Waitlist.Mail
  alias Timesink.Repo
  alias Timesink.Waitlist.Applicant
  alias Timesink.Waitlist.InviteScheduler
  import Ecto.Query, only: [from: 2]

  @max_wave_size 8

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

    spots_remaining = max(0, @max_wave_size - pending_applicants)
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
        position in 1..2 -> "It looks like you're next. Expect an invite very soon."
        position in 3..20 -> "You're among the next on the list. Stay tuned for your invite."
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
      position <= 10 -> "less than 1 hour"
      position <= 50 -> "less than 24 hours"
      true -> "in 3-5 days"
    end
  end

  @doc """
  Adds a new applicant to the waitlist, or reactivates an existing one if eligible.

  This function handles the following cases:

    * **New applicant** – Creates a new waitlist record and sends a confirmation email.
    * **Existing applicant with `:pending` status** – Returns an error on the `:email` field indicating the applicant is already on the waitlist.
    * **Existing applicant with `:invited` status and an expired token** – Deletes the expired invite token, reactivates the applicant by setting their status back to `:pending`, updates their name fields if needed, and sends a new confirmation email.
    * **Existing applicant with `:invited` status and a valid token** – Returns an error on the `:email` field indicating the applicant has an active invite.
    * **Existing applicant with `:completed` status** – Returns an error on the `:email` field indicating the applicant has already joined.

  ## Examples

      iex> join(%{
      ...>   "first_name" => "Jose",
      ...>   "last_name" => "Val Del Omar",
      ...>   "email" => "valdelomar@gmail.com"
      ...> })
      {:ok, %Timesink.Waitlist.Applicant{}}

      iex> join(%{"email" => "already@waiting.com"})
      {:error, #Ecto.Changeset<action: nil, errors: [email: {"This email is already on the waitlist.", []}]>}

      iex> join(%{"email" => "already@joined.com"})
      {:error, #Ecto.Changeset<action: nil, errors: [email: {"This email has already joined.", []}]>}
  """
  @spec join(map()) :: {:ok, Applicant.t()} | {:error, Ecto.Changeset.t()}
  def join(params) do
    email = Map.get(params, "email")
    first_name = Map.get(params, "first_name")
    last_name = Map.get(params, "last_name")

    with {:ok, existing} <- Applicant.get_by(email: email) do
      status = existing.status

      cond do
        status == :pending ->
          changeset =
            Applicant.changeset(existing, params)
            |> Ecto.Changeset.add_error(:email, "This email is already on the waitlist.")

          {:error, changeset}

        status == :invited ->
          with {:ok, token} <- Timesink.Token.get_by(waitlist_id: existing.id) do
            if Timesink.Token.is_expired?(token) do
              {:ok, _token} = Timesink.Token.delete(token)

              with {:ok, applicant} <-
                     Applicant.update(existing, %{
                       status: :pending,
                       first_name: first_name,
                       last_name: last_name
                     }) do
                # Mail.send_waitlist_confirmation(applicant.email, applicant.first_name)
                InviteScheduler.schedule_invite(applicant.id)

                {:ok, applicant}
              else
                {:error, changeset} ->
                  {:error, changeset}
              end
            else
              changeset =
                Applicant.changeset(existing, params)
                |> Ecto.Changeset.add_error(:email, "This email has an active invite.")

              {:error, changeset}
            end
          else
            _ ->
              {:error, :not_found}
          end

        status == :completed ->
          changeset =
            Applicant.changeset(existing, params)
            |> Ecto.Changeset.add_error(:email, "This email has already joined.")

          {:error, changeset}
      end
    else
      _ ->
        with {:ok, applicant} <- Applicant.create(params) do
          # Mail.send_waitlist_confirmation(applicant.email, applicant.first_name)
          InviteScheduler.schedule_invite(applicant.id)

          {:ok, applicant}
        else
          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  def set_status(applicant, status) do
    Applicant.update(applicant, %{status: status})
  end

  @spec get_applicant_by_invite_token(Timesink.Token.t()) ::
          {:ok, Timesink.Waitlist.Applicant.t()} | {:not_applicant, :not_found}
  def get_applicant_by_invite_token(%Timesink.Token{waitlist_id: nil}),
    do: {:not_applicant, :not_found}

  @spec get_applicant_by_invite_token(Timesink.Token.t()) ::
          {:ok, Timesink.Waitlist.Applicant.t()} | {:not_applicant, :not_found}
  def get_applicant_by_invite_token(%Timesink.Token{waitlist_id: id} = _token) do
    with {:ok, applicant} <- Applicant.get_by(%{id: id}) do
      {:ok, applicant}
    else
      {:error, :not_found} -> {:not_applicant, :not_found}
    end
  end
end
