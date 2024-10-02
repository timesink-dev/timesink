defmodule Timesink.Factory do
  use ExMachina.Ecto, repo: Timesink.Repo

  def applicant_factory do
    %Timesink.Waitlist.Applicant{
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      email: Faker.Internet.email()
    }
  end
end
