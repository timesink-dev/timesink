defmodule Timesink.WaitlistTest do
  use Timesink.DataCase
  import Timesink.Factory
  alias Timesink.Waitlist
  alias Timesink.Waitlist.Applicant

  describe "join/1" do
    for field <- [:first_name, :last_name, :email] do
      test "requires a param #{field}" do
        params = params_for(:applicant) |> Map.delete(unquote(field))

        assert {:error, %Ecto.Changeset{errors: e}} = Waitlist.join(params)
        assert {"can't be blank", _} = Keyword.get(e, unquote(field))
      end
    end

    test "requires a valid email" do
      params = params_for(:applicant) |> Map.put(:email, "invalid.email")

      assert {:error, %Ecto.Changeset{errors: e}} = Waitlist.join(params)
      assert {"has invalid format", _} = Keyword.get(e, :email)
    end

    test "joins an applicant to the waitlist" do
      params = params_for(:applicant)

      assert {:ok, %Applicant{} = applicant} = Waitlist.join(params)
      assert applicant.first_name == params.first_name
      assert applicant.last_name == params.last_name
      assert applicant.email == params.email
    end
  end
end
