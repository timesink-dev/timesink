defmodule Timesink.Waitlist do
  @moduledoc """
  The Waitlist context.
  """

  alias Timesink.Waitlist.Applicant
  alias Timesink.Waitlist.Mail

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
      Mail.send_invite_code(applicant.email, applicant.first_name, applicant.code)
      {:ok, applicant}
    end
  end
end
