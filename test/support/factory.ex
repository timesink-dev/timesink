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
    %Timesink.Account.User{
      email: Faker.Internet.email(),
      password_hash: Ecto.UUID.generate(),
      username: Faker.Internet.user_name(),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      profile: build(:profile)
    }
  end

  def location_factory do
    %Timesink.Account.Location{
      locality: Faker.Address.city(),
      country: Enum.random(Timesink.Account.Location.iso3166_countries()),
      lat: Faker.Address.latitude(),
      lng: Faker.Address.longitude()
    }
  end

  def profile_factory do
    %Timesink.Account.Profile{
      bio: Faker.Lorem.sentence(),
      avatar_url: Faker.Internet.url(),
      location: build(:location),
      birthdate: Faker.Date.date_of_birth(),
      org_name: Faker.Company.name(),
      org_position: Faker.Company.buzzword()
    }
  end
end
