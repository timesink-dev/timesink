defmodule Timesink.Cinema.DirectorCommentaryTest do
  use Timesink.DataCase, async: true

  import Timesink.Factory

  alias Timesink.Cinema.DirectorCommentary
  alias Timesink.Repo

  # Helpers

  defp verified_director(film) do
    user = insert(:user)
    creative = claim_creative(user)
    insert(:director, film: film, creative: creative)
    user
  end

  defp verified_creative_with_role(film, role) do
    user = insert(:user)
    creative = claim_creative(user)
    insert(role, film: film, creative: creative)
    user
  end

  defp claim_creative(user) do
    insert(:creative)
    |> Ecto.Changeset.change(user_id: user.id)
    |> Repo.update!()
  end

  describe "director_of_film?/2" do
    test "returns true when user is a verified director of the film" do
      film = insert(:film)
      user = verified_director(film)

      assert DirectorCommentary.director_of_film?(user, film.id)
    end

    test "returns true for each director when film has multiple directors" do
      film = insert(:film)
      user1 = verified_director(film)
      user2 = verified_director(film)

      assert DirectorCommentary.director_of_film?(user1, film.id)
      assert DirectorCommentary.director_of_film?(user2, film.id)
    end

    test "returns false when user has no creative profile" do
      film = insert(:film)
      user = insert(:user)

      refute DirectorCommentary.director_of_film?(user, film.id)
    end

    test "returns false when user has a creative profile not linked to this film" do
      film = insert(:film)
      other_film = insert(:film)
      user = verified_director(other_film)

      refute DirectorCommentary.director_of_film?(user, film.id)
    end

    test "returns false when user is linked to the film as producer" do
      film = insert(:film)
      user = verified_creative_with_role(film, :producer)

      refute DirectorCommentary.director_of_film?(user, film.id)
    end

    test "returns false when user is linked to the film as writer" do
      film = insert(:film)
      user = verified_creative_with_role(film, :writer)

      refute DirectorCommentary.director_of_film?(user, film.id)
    end

    test "returns false when user is linked to the film as cast" do
      film = insert(:film)
      user = verified_creative_with_role(film, :cast)

      refute DirectorCommentary.director_of_film?(user, film.id)
    end

    test "returns false when user is linked to the film as crew" do
      film = insert(:film)
      user = verified_creative_with_role(film, :crew)

      refute DirectorCommentary.director_of_film?(user, film.id)
    end

    test "returns false when creative is not linked to a user (unclaimed profile)" do
      film = insert(:film)
      creative = insert(:creative)
      insert(:director, film: film, creative: creative)

      unrelated_user = insert(:user)

      refute DirectorCommentary.director_of_film?(unrelated_user, film.id)
    end

    test "returns false when user's creative is claimed but belongs to a different user" do
      film = insert(:film)
      other_user = insert(:user)
      creative = claim_creative(other_user)
      insert(:director, film: film, creative: creative)

      different_user = insert(:user)

      refute DirectorCommentary.director_of_film?(different_user, film.id)
    end
  end

  describe "list_director_films/1" do
    test "returns all films where user is a verified director" do
      user = insert(:user)
      creative = claim_creative(user)

      film1 = insert(:film)
      film2 = insert(:film)
      insert(:director, film: film1, creative: creative)
      insert(:director, film: film2, creative: creative)

      films = DirectorCommentary.list_director_films(user)
      film_ids = Enum.map(films, & &1.id)

      assert film1.id in film_ids
      assert film2.id in film_ids
    end

    test "does not include films where user has a non-director role" do
      user = insert(:user)
      creative = claim_creative(user)
      film = insert(:film)
      insert(:producer, film: film, creative: creative)

      assert DirectorCommentary.list_director_films(user) == []
    end

    test "returns empty list when user has no creative profile" do
      user = insert(:user)

      assert DirectorCommentary.list_director_films(user) == []
    end

    test "returns empty list when user has a creative profile with no film credits" do
      user = insert(:user)
      _creative = claim_creative(user)

      assert DirectorCommentary.list_director_films(user) == []
    end
  end
end
