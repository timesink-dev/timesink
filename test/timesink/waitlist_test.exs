defmodule Timesink.WaitlistTest do
  use Timesink.DataCase
  alias Timesink.Waitlist

  describe "applicants" do
    alias Timesink.Waitlist.Applicant

    @valid_attrs %{
      first_name: "Jose",
      last_name: "Val Del Omar",
      email: "josevaldelomar@gmail.com"
    }

    @invalid_attrs %{
      first_name: "Jose",
      last_name: "",
      email: "josevaldelomar"
    }

    test "join/1 with valid attributes creates a new applicant and adds them to the waitlist" do
      assert {:ok, %Applicant{} = applicant} = Waitlist.join(@valid_attrs)
      assert applicant.first_name == "Jose"
      assert applicant.last_name == "Val Del Omar"
      assert applicant.email == "josevaldelomar@gmail.com"
    end

    test "join/1 with invalid attributes returns an error" do
      assert {:error, _} = Waitlist.join(@invalid_attrs)
    end

    test "join/1 with invalid #email returns an error" do
      attrs = %{@valid_attrs | email: "josevaldelomar"}
      changeset = Waitlist.Applicant.changeset(%Applicant{}, attrs)
      assert %{email: ["has invalid format"]} = errors_on(changeset)
    end

    test "join/1 with #status not provided" do
      changeset = Applicant.changeset(%Applicant{}, Map.delete(@valid_attrs, :status))
      assert changeset.valid?
    end
  end
end
