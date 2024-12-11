defmodule Timesink.AccountsTest do
  use Timesink.DataCase
  import Timesink.Factory
  alias Timesink.Accounts
  alias Timesink.Accounts.User

  describe "query_users/1" do
    test "accept a function hook" do
      %{id: uid} = insert(:user)

      assert {:ok, [%User{id: ^uid}]} = Accounts.query_users(fn q -> q end)
    end
  end
end
