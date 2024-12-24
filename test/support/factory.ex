defmodule Timesink.Factory do
  use ExMachina.Ecto, repo: Timesink.Repo

  # Files

  def file_factory do
    filename = Faker.File.file_name()
    content = Faker.Lorem.sentences() |> Enum.join(" ")
    size = Timesink.File.size(content)
    hash = Timesink.File.hash(content)

    %Timesink.File{
      name: filename,
      size: size,
      content_type: "text/plain",
      content_hash: hash,
      content: content
    }
  end

  # Accounts

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
      name: "#{Faker.Lorem.word()} #{Enum.random(1_000..9_999)}",
      description: Faker.Lorem.paragraph(1..2)
    }
  end

  def creative_factory do
    %Timesink.Cinema.Creative{
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name()
    }
  end

  def theater_factory do
    %Timesink.Cinema.Theater{
      name: Faker.Cat.name(),
      description: Faker.Lorem.sentence()
    }
  end

  def film_factory(params) do
    genres =
      case params |> Map.get(:genres) do
        item when is_list(item) -> item
        item when is_nil(item) -> [insert(:genre)]
      end

    %Timesink.Cinema.Film{
      title: Faker.Lorem.sentence(),
      year: 1900..2024 |> Enum.random(),
      duration: 10..180 |> Enum.random(),
      color: Timesink.Cinema.Film.colors() |> Enum.random(),
      aspect_ratio: "4:3",
      format: Timesink.Cinema.Film.formats() |> Enum.random(),
      synopsis: Faker.Lorem.paragraph(),
      genres: genres
    }
  end

  def film_creative_factory(params) do
    [film, creative] =
      for field <- [:film, :creative] do
        case params |> Map.get(field |> dbg) |> dbg do
          item when is_struct(item) -> item
          item when is_nil(item) -> insert(field)
        end
      end

    %Timesink.Cinema.FilmCreative{
      film: film,
      creative: creative,
      role: Timesink.Cinema.FilmCreative.roles() |> Enum.random()
    }
  end

  def director_factory(params), do: build(:film_creative, params) |> Map.put(:role, :director)
  def producer_factory(params), do: build(:film_creative, params) |> Map.put(:role, :producer)
  def writer_factory(params), do: build(:film_creative, params) |> Map.put(:role, :writer)
  def cast_factory(params), do: build(:film_creative, params) |> Map.put(:role, :cast)
  def crew_factory(params), do: build(:film_creative, params) |> Map.put(:role, :crew)

  def showcase_factory(params) do
    exhibitions =
      case params |> Map.get(:exhibitions) do
        exhibitions when is_list(exhibitions) -> exhibitions
        exhibitions when is_nil(exhibitions) -> [insert(:exhibition)]
      end

    %Timesink.Cinema.Showcase{
      title: Faker.Lorem.sentence(3..5),
      description: Faker.Lorem.sentence(),
      start_at: NaiveDateTime.utc_now() |> NaiveDateTime.add(-1, :day),
      end_at: NaiveDateTime.utc_now() |> NaiveDateTime.add(1, :day),
      exhibitions: exhibitions
    }
  end

  def exhibition_factory(params) do
    [film, showcase, theater] =
      for key <- [:film, :showcase, :theater] do
        case params |> Map.get(key) do
          item when is_struct(item) -> item
          item when is_nil(item) -> insert(key)
        end
      end

    %Timesink.Cinema.Exhibition{
      film: film,
      showcase: showcase,
      theater: theater
    }
  end
end
