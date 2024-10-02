defmodule Timesink.Waitlist do
  @moduledoc """
  The Waitlist context.
  """
  alias Timesink.Waitlist.Applicant
  alias Timesink.Repo

  @doc """
  Creates a new applicant and adds them to the waitlist.

  ## Examples

      iex> join(%{first_name: "Jose", last_name: "Val Del Omar", email: "valdelomar@gmail.com"})
      {:ok, %Timesink.Waitlist.Applicant{…}}


      iex > join(%{first_name: "Jose", last_name: "Val Del Omar", email: "josevaldelomar"})
      {:error, %Ecto.Changeset{…}}
  """

  def join(params) do
    %Applicant{}
    |> Applicant.changeset(params)
    |> Repo.insert()
  end
end
