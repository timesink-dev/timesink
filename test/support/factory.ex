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

  @genres [
    "Action",
    "Adventure",
    "Animation",
    "Biographical",
    "Comedy",
    "Crime",
    "Documental",
    "Drama",
    "Family",
    "Fantasy",
    "Historical",
    "Horror",
    "Musical",
    "Mystery",
    "Romance",
    "Sci-Fi",
    "Sports",
    "Thriller",
    "War",
    "Western"
  ]

  def genre_factory do
    %Timesink.Cinema.Genre{
      name: @genres |> Enum.random(),
      description: Faker.Lorem.paragraph(1..2)
    }
  end

  def creative_factory do
    %Timesink.Cinema.Creative{
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name()
    }
  end
end
