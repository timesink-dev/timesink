defmodule Timesink.Accounts do
  alias Timesink.Repo
  alias Timesink.Accounts.User

  @moduledoc """
  The Accounts context.
  """

  def get_user_by!(fields), do: Repo.get_by!(User, fields)
end
