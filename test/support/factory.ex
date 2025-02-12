defmodule Timesink.Factory do
  use ExMachina.Ecto, repo: Timesink.Repo
  alias Timesink.Storage

  # Blobs and Attachments

  def plug_upload_factory do
    tmpdir = "/tmp/timesink-tmp-#{Ecto.UUID.generate()}"
    filename = "#{Ecto.UUID.generate()}.txt"
    filepath = "#{tmpdir}/#{filename}"
    content = Faker.Lorem.sentences() |> Enum.join(" ")

    File.mkdir_p!(tmpdir)
    File.write!(filepath, content)

    %Plug.Upload{
      content_type: "text/plain",
      path: filepath,
      filename: filename
    }
  end

  def blob_factory do
    config = Storage.config()

    upload = build(:plug_upload)
    path = Path.join([config.prefix, upload.filename])

    {:ok, %{status_code: 200}} = Storage.S3.put(upload, path)

    %Timesink.Storage.Blob{
      path: path,
      size: File.stat!(upload.path).size
    }
  end

  def attachment_factory do
    blob = insert(:blob)

    target_schema = Ecto.Enum.values(Storage.Attachment, :target_schema) |> Enum.random()
    target_id = Ecto.UUID.generate()

    %Timesink.Storage.Attachment{
      blob_id: blob.id,
      target_schema: target_schema,
      target_id: target_id,
      name: "test_attachment"
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
      password: Argon2.hash_pwd_salt("password"),
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
      country_code: Enum.random(Timesink.Accounts.Location.iso3166_countries()),
      state_code: Faker.Address.state_abbr(),
      label: "#{Faker.Address.city()}, #{Faker.Address.state_abbr()}, #{Faker.Address.country()}",
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

  # Timesink.Mux

  def mux_upload_factory do
    %Timesink.Storage.MuxUpload{
      upload_id: Ecto.UUID.generate(),
      asset_id: Ecto.UUID.generate(),
      playback_id: Ecto.UUID.generate()
    }
  end
end
