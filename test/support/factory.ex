defmodule Timesink.Factory do
  use ExMachina.Ecto, repo: Timesink.Repo

  def applicant_factory do
    %Timesink.Waitlist.Applicant{
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      email: Faker.Internet.email()
    }
  end

  def user_factory do
    %Timesink.Accounts.User{
      email: Faker.Internet.email(),
      password_hash: Argon2.hash_pwd_salt(Faker.Lorem.word()),
      username: Faker.Internet.user_name(),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      profile: build(:profile)
    }
  end

  def location_factory do
    %Timesink.Accounts.Location{
      locality: Faker.Address.city(),
      country: Faker.Address.country(),
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
end
