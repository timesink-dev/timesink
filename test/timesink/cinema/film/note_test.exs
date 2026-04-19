defmodule Timesink.Cinema.Film.NoteTest do
  use Timesink.DataCase, async: true

  import Timesink.Factory

  alias Timesink.Cinema.Film.Note
  alias Timesink.Cinema.Note, as: NoteSchema
  alias Timesink.Repo

  defp insert_director_note(film, user, attrs \\ %{}) do
    %NoteSchema{}
    |> NoteSchema.changeset(
      Map.merge(
        %{
          source: :director,
          body: "some commentary about this moment",
          offset_seconds: 60,
          user_id: user.id,
          film_id: film.id
        },
        attrs
      )
    )
    |> Repo.insert!()
  end

  describe "list_commentary/1" do
    test "returns all visible director notes for a film ordered by offset_seconds" do
      film = insert(:film)
      user = insert(:user)

      insert_director_note(film, user, %{offset_seconds: 300, body: "third"})
      insert_director_note(film, user, %{offset_seconds: 60, body: "first"})
      insert_director_note(film, user, %{offset_seconds: 120, body: "second"})

      results = Note.list_commentary(film.id)

      assert length(results) == 3
      assert Enum.map(results, & &1.body) == ["first", "second", "third"]
    end

    test "preloads user association" do
      film = insert(:film)
      user = insert(:user)

      insert_director_note(film, user)

      [note] = Note.list_commentary(film.id)
      assert %Timesink.Account.User{} = note.user
    end

    test "excludes hidden notes" do
      film = insert(:film)
      user = insert(:user)

      insert_director_note(film, user, %{status: :hidden})

      assert Note.list_commentary(film.id) == []
    end

    test "excludes flagged notes" do
      film = insert(:film)
      user = insert(:user)

      insert_director_note(film, user, %{status: :flagged})

      assert Note.list_commentary(film.id) == []
    end

    test "returns empty list when film has no director notes" do
      film = insert(:film)

      assert Note.list_commentary(film.id) == []
    end

    test "does not return audience notes for the same film" do
      film = insert(:film)
      user = insert(:user)
      theater = insert(:theater)
      showcase = insert(:showcase, exhibitions: [])
      exhibition = insert(:exhibition, film: film, theater: theater, showcase: showcase)

      %NoteSchema{}
      |> NoteSchema.changeset(%{
        source: :audience,
        body: "audience comment",
        offset_seconds: 60,
        user_id: user.id,
        exhibition_id: exhibition.id
      })
      |> Repo.insert!()

      assert Note.list_commentary(film.id) == []
    end

    test "does not return director notes for a different film" do
      film1 = insert(:film)
      film2 = insert(:film)
      user = insert(:user)

      insert_director_note(film2, user)

      assert Note.list_commentary(film1.id) == []
    end
  end

  describe "list_commentary/2 (offset-bounded, for theater sync)" do
    test "returns only notes at or before the given offset" do
      film = insert(:film)
      user = insert(:user)

      insert_director_note(film, user, %{offset_seconds: 30, body: "early"})
      insert_director_note(film, user, %{offset_seconds: 90, body: "mid"})
      insert_director_note(film, user, %{offset_seconds: 180, body: "late"})

      results = Note.list_commentary(film.id, 90)

      assert length(results) == 2
      assert Enum.map(results, & &1.body) == ["early", "mid"]
    end

    test "returns empty list when no notes fall within offset" do
      film = insert(:film)
      user = insert(:user)

      insert_director_note(film, user, %{offset_seconds: 300})

      assert Note.list_commentary(film.id, 60) == []
    end
  end

  describe "create_commentary/3" do
    test "creates a director note with correct source and film association" do
      film = insert(:film)
      user = insert(:user)

      assert {:ok, note} =
               Note.create_commentary(user, film.id, %{
                 body: "the framing here was intentional",
                 offset_seconds: 95
               })

      assert note.source == :director
      assert note.film_id == film.id
      assert note.user_id == user.id
      assert note.body == "the framing here was intentional"
      assert note.offset_seconds == 95
      assert note.status == :visible
      assert is_nil(note.exhibition_id)
    end

    test "returns error changeset when body is too short" do
      film = insert(:film)
      user = insert(:user)

      assert {:error, changeset} =
               Note.create_commentary(user, film.id, %{body: "hi", offset_seconds: 10})

      assert %{body: [_ | _]} = errors_on(changeset)
    end

    test "returns error changeset when body is missing" do
      film = insert(:film)
      user = insert(:user)

      assert {:error, changeset} =
               Note.create_commentary(user, film.id, %{offset_seconds: 10})

      assert %{body: [_ | _]} = errors_on(changeset)
    end

    test "returns error changeset when offset_seconds is missing" do
      film = insert(:film)
      user = insert(:user)

      assert {:error, changeset} =
               Note.create_commentary(user, film.id, %{body: "some commentary"})

      assert %{offset_seconds: [_ | _]} = errors_on(changeset)
    end
  end

  describe "update_commentary/2" do
    test "updates the body of an existing director note" do
      film = insert(:film)
      user = insert(:user)
      note = insert_director_note(film, user, %{body: "original text"})

      assert {:ok, updated} = Note.update_commentary(note, %{body: "revised text"})

      assert updated.body == "revised text"
    end

    test "returns error changeset when updated body is too short" do
      film = insert(:film)
      user = insert(:user)
      note = insert_director_note(film, user)

      assert {:error, changeset} = Note.update_commentary(note, %{body: "hi"})
      assert %{body: [_ | _]} = errors_on(changeset)
    end

    test "returns error changeset when updated body is empty" do
      film = insert(:film)
      user = insert(:user)
      note = insert_director_note(film, user)

      assert {:error, changeset} = Note.update_commentary(note, %{body: ""})
      assert %{body: [_ | _]} = errors_on(changeset)
    end

    test "does not alter source or film_id on update" do
      film = insert(:film)
      user = insert(:user)
      note = insert_director_note(film, user)

      assert {:ok, updated} = Note.update_commentary(note, %{body: "new body here"})

      assert updated.source == :director
      assert updated.film_id == film.id
    end
  end

  describe "delete_commentary/1" do
    test "removes the note from the database" do
      film = insert(:film)
      user = insert(:user)
      note = insert_director_note(film, user)

      assert {:ok, _deleted} = Note.delete_commentary(note)
      assert is_nil(Repo.get(NoteSchema, note.id))
    end

    test "deletion is retroactive — note no longer appears in list_commentary" do
      film = insert(:film)
      user = insert(:user)
      note = insert_director_note(film, user)

      Note.delete_commentary(note)

      assert Note.list_commentary(film.id) == []
    end
  end
end
