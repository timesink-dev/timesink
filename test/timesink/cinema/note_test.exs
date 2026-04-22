defmodule Timesink.Cinema.NoteTest do
  use Timesink.DataCase, async: true

  import Timesink.Factory

  alias Timesink.Cinema.Note

  describe "audience note changeset (backwards compat)" do
    test "is valid with exhibition_id and no film_id" do
      user = insert(:user)

      params = %{
        source: :audience,
        body: "great scene",
        offset_seconds: 120,
        user_id: user.id,
        exhibition_id: Ecto.UUID.generate()
      }

      changeset = Note.changeset(%Note{}, params)
      assert changeset.valid?
    end

    test "is invalid without exhibition_id" do
      user = insert(:user)

      params = %{
        source: :audience,
        body: "great scene",
        offset_seconds: 120,
        user_id: user.id
      }

      changeset = Note.changeset(%Note{}, params)
      refute changeset.valid?
      assert %{exhibition_id: [_ | _]} = errors_on(changeset)
    end
  end

  describe "director note changeset" do
    test "is valid with film_id and no exhibition_id" do
      user = insert(:user)
      film = insert(:film)

      params = %{
        source: :director,
        body: "I wanted the lighting to feel oppressive here",
        offset_seconds: 300,
        user_id: user.id,
        film_id: film.id
      }

      changeset = Note.changeset(%Note{}, params)
      assert changeset.valid?
    end

    test "is invalid without film_id" do
      user = insert(:user)

      params = %{
        source: :director,
        body: "some commentary",
        offset_seconds: 60,
        user_id: user.id
      }

      changeset = Note.changeset(%Note{}, params)
      refute changeset.valid?
      assert %{film_id: [_ | _]} = errors_on(changeset)
    end

    test "is invalid without body" do
      user = insert(:user)
      film = insert(:film)

      params = %{
        source: :director,
        offset_seconds: 60,
        user_id: user.id,
        film_id: film.id
      }

      changeset = Note.changeset(%Note{}, params)
      refute changeset.valid?
      assert %{body: [_ | _]} = errors_on(changeset)
    end

    test "is invalid when body is shorter than 3 characters" do
      user = insert(:user)
      film = insert(:film)

      params = %{
        source: :director,
        body: "hi",
        offset_seconds: 60,
        user_id: user.id,
        film_id: film.id
      }

      changeset = Note.changeset(%Note{}, params)
      refute changeset.valid?
      assert %{body: [_ | _]} = errors_on(changeset)
    end

    test "is invalid without user_id" do
      film = insert(:film)

      params = %{
        source: :director,
        body: "some commentary",
        offset_seconds: 60,
        film_id: film.id
      }

      changeset = Note.changeset(%Note{}, params)
      refute changeset.valid?
      assert %{user_id: [_ | _]} = errors_on(changeset)
    end

    test "is invalid without offset_seconds" do
      user = insert(:user)
      film = insert(:film)

      params = %{
        source: :director,
        body: "some commentary",
        user_id: user.id,
        film_id: film.id
      }

      changeset = Note.changeset(%Note{}, params)
      refute changeset.valid?
      assert %{offset_seconds: [_ | _]} = errors_on(changeset)
    end

    test "defaults status to :visible" do
      user = insert(:user)
      film = insert(:film)

      params = %{
        source: :director,
        body: "some commentary",
        offset_seconds: 60,
        user_id: user.id,
        film_id: film.id
      }

      changeset = Note.changeset(%Note{}, params)
      assert Ecto.Changeset.get_field(changeset, :status) == :visible
    end
  end
end
