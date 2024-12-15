defmodule Timesink.Factory do
  use ExMachina.Ecto, repo: Timesink.Repo

  def applicant_factory do
    %Timesink.Waitlist.Applicant{
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      email: Faker.Internet.email(),
      status: Timesink.Waitlist.Applicant.statuses() |> Enum.random()
    }
  end

  def user_factory do
    %Timesink.Accounts.User{
      email: Faker.Internet.email(),
      password_hash: Ecto.UUID.generate(),
      username: Faker.Internet.user_name(),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      profile: build(:profile)
    }
  end

  def location_factory do
    %Timesink.Accounts.Location{
      locality: Faker.Address.city(),
      country: Enum.random(Timesink.Accounts.Location.iso3166_countries()),
      lat: Faker.Address.latitude(),
      lng: Faker.Address.longitude()
    }
  end

  def profile_factory do
    %Timesink.Accounts.Profile{
      bio: Faker.Lorem.sentence(),
      avatar_url: Faker.Internet.url(),
      location: build(:location),
      birthdate: Faker.Date.date_of_birth(),
      org_name: Faker.Company.name(),
      org_position: Faker.Company.buzzword()
    }
  end

  # Cinema

  def genre_factory do
    %Timesink.Cinema.Genre{
      name: Faker.Lorem.word(),
      description: Faker.Lorem.paragraph(1..2)
    }
  end

  def creative_factory do
    %Timesink.Cinema.Creative{
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name()
    }
  end

  def film_creative_factory(params) do
    for field <- [:film, :creative] do
      case params |> Map.get(field) do
        item when is_map(item) -> item
        item when is_nil(item) -> insert(item)
      end
    end

    %Timesink.Cinema.FilmCreative{
      role: Timesink.Cinema.FilmCreative.roles() |> Enum.random()
    }
  end

  def film_factory(params) do
    genres =
      case params |> Map.get(:genres) do
        genres when is_list(genres) -> genres
        genre when is_nil(genre) -> [insert(:genre)]
      end

    %Timesink.Cinema.Film{
      title: Faker.Lorem.sentence(1..4),
      year: 1900..2024 |> Enum.random(),
      duration: 10..180 |> Enum.random(),
      color: Timesink.Cinema.Film.colors() |> Enum.random(),
      aspect_ratio: "4:3",
      format: Timesink.Cinema.Film.formats() |> Enum.random(),
      synopsis: Faker.Lorem.paragraph(),
      genres: genres
    }
  end

  def theater_factory do
    %Timesink.Cinema.Theater{
      name: Faker.Cat.name(),
      description: Faker.Lorem.sentence()
    }
  end
end
