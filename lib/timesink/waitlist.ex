defmodule Timesink.Waitlist do
  @moduledoc """
  The Waitlist context.
  """

  import Ecto.Changeset
  alias Timesink.Waitlist.Applicant

  @doc """
  Creates a new applicant and adds them to the waitlist.

  ## Examples

      iex> join(%{"first_name" => "Jose", "last_name" => "Val Del Omar", "email": "valdelomar@gmail.com"})
      {:ok, %Timesink.Waitlist.Applicant{…}}
  """
  @spec join(params :: map()) ::
          {:ok, Applicant.t()} | {:error, Ecto.Changeset.t()}
  def join(params) do
    params_schema = %{
      first_name: :string,
      last_name: :string,
      email: :string
    }

    changeset =
      {%{}, params_schema}
      |> cast(params, Map.keys(params_schema))
      |> validate_required([:first_name, :last_name, :email])

    with {:ok, params} <- apply_action(changeset, :join),
         {:ok, user} <- Applicant.create(params) do
      {:ok, user}
    end
  end
end
