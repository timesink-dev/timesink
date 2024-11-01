defmodule Timesink.Waitlist do
  @moduledoc """
  The Waitlist context.
  """

  alias Timesink.Repo
  alias Timesink.Waitlist.Applicant

  @doc """
  Creates a new applicant and adds them to the waitlist.

  ## Examples

      iex> join(%{"first_name" => "Jose", "last_name" => "Val Del Omar", "email" => "valdelomar@gmail.com"})
      {:ok, %Timesink.Waitlist.Applicant{…}}
  """
  @spec join(params :: map()) ::
          {:ok, Applicant.t()} | {:error, Ecto.Changeset.t()}
  def join(params) do
    with changeset <- Applicant.changeset(%Applicant{}, params),
         {:ok, applicant} <- Repo.insert(changeset) do
      {:ok, applicant}
    else
      {:error, changeset} -> {:error, changeset}
    end
  end
end
