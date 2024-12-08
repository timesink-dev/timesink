defmodule Timesink.Accounts do
  alias Timesink.Accounts.User

  @moduledoc """
  The Accounts context.
  """

  def get_user_by!(fields), do: User.get_by(fields)
end
