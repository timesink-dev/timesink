defmodule Timesink.AccountTest do
  use Timesink.DataCase, async: true

  import Timesink.Factory

  alias Timesink.Account
  alias Timesink.Account.User

  describe "update_user_password/3" do
    test "happy path: updates password when current password is correct" do
      # factory sets hash for "password"
      user = insert(:user)

      assert {:ok, updated} =
               Account.update_user_password(user, "password", %{
                 "password" => "newpassword123",
                 "password_confirmation" => "newpassword123"
               })

      reloaded = User.get!(updated.id)
      assert Argon2.verify_pass("newpassword123", reloaded.password)
      refute Argon2.verify_pass("password", reloaded.password)
    end

    test "unhappy: current password wrong" do
      user = insert(:user)

      assert {:error, cs} =
               Account.update_user_password(user, "wrong-pass", %{
                 "password" => "newpassword123",
                 "password_confirmation" => "newpassword123"
               })

      errs = errors_on(cs)

      assert "Password entered does not match your current password" in (errs[:current_password] ||
                                                                           [])

      unchanged = User.get!(user.id)
      assert Argon2.verify_pass("password", unchanged.password)
    end

    test "unhappy: new password too short" do
      user = insert(:user)

      assert {:error, cs} =
               Account.update_user_password(user, "password", %{
                 "password" => "short",
                 "password_confirmation" => "short"
               })

      errs = errors_on(cs)
      assert Enum.any?(errs[:password] || [], &String.contains?(&1, "at least 8"))

      unchanged = User.get!(user.id)
      assert Argon2.verify_pass("password", unchanged.password)
    end

    test "unhappy: confirmation mismatch" do
      user = insert(:user)

      assert {:error, cs} =
               Account.update_user_password(user, "password", %{
                 "password" => "newpassword123",
                 "password_confirmation" => "different"
               })

      errs = errors_on(cs)

      assert Enum.any?(errs[:password_confirmation] || [], fn m ->
               String.contains?(m, "does not match")
             end)

      unchanged = User.get!(user.id)
      assert Argon2.verify_pass("password", unchanged.password)
    end
  end

  describe "reset password flow" do
    test "happy path: deliver link, verify token, reset, invalidate token" do
      user = insert(:user)

      Account.deliver_user_reset_password_instructions(user.email, fn token ->
        send(self(), {:reset_token, token})
        "http://example/reset/#{token}"
      end)

      assert_receive {:reset_token, token}, 200

      returned = Account.get_user_by_reset_password_token(token)
      assert %User{} = returned
      assert returned.id == user.id

      assert {:ok, updated} =
               Account.reset_user_password(user, %{
                 "password" => "resetpass123",
                 "password_confirmation" => "resetpass123"
               })

      reloaded = User.get!(updated.id)
      assert Argon2.verify_pass("resetpass123", reloaded.password)
      refute Argon2.verify_pass("password", reloaded.password)

      # token cannot be reused
      assert Account.get_user_by_reset_password_token(token) == nil
    end

    test "neutral: unknown email still returns :ok (no token delivered)" do
      assert :ok =
               Account.deliver_user_reset_password_instructions("nope@example.com", fn token ->
                 send(self(), {:should_not_happen, token})
                 "http://example/reset/#{token}"
               end)

      refute_receive {:should_not_happen, _}, 100
    end

    test "unhappy: reset rejects too-short password" do
      user = insert(:user)

      Account.deliver_user_reset_password_instructions(user.email, fn token ->
        send(self(), {:reset_token, token})
        "http://example/reset/#{token}"
      end)

      assert_receive {:reset_token, _token}, 200

      assert {:error, cs} =
               Account.reset_user_password(user, %{
                 "password" => "short",
                 "password_confirmation" => "short"
               })

      errs = errors_on(cs)
      assert Enum.any?(errs[:password] || [], &String.contains?(&1, "at least 8"))

      unchanged = User.get!(user.id)
      assert Argon2.verify_pass("password", unchanged.password)
    end

    test "unhappy: reset rejects confirmation mismatch" do
      user = insert(:user)

      Account.deliver_user_reset_password_instructions(user.email, fn token ->
        send(self(), {:reset_token, token})
        "http://example/reset/#{token}"
      end)

      assert_receive {:reset_token, _token}, 200

      assert {:error, cs} =
               Account.reset_user_password(user, %{
                 "password" => "resetpass123",
                 "password_confirmation" => "different"
               })

      errs = errors_on(cs)

      assert Enum.any?(errs[:password_confirmation] || [], fn m ->
               String.contains?(m, "does not match")
             end)

      unchanged = User.get!(user.id)
      assert Argon2.verify_pass("password", unchanged.password)
    end
  end
end
