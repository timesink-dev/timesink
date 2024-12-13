# 🌌 TimeSink Presents

> **️🚧 Work in Progress**: This document is a living, ongoing work in progress! We're constantly improving and updating it to better reflect our evolving understanding of the platform and its features. As we build and refine TimeSink, this documentation will dynamically change, so check back often for the latest updates and improvements. Your contributions and suggestions are always welcome as we shape this exciting project together!

## 🚰 What is TimeSink ?

**TimeSink** is more than just a cinema; it’s a place where time is not lost, but held, preserved, and waiting. In the world of film, time has a cyclical nature—each story is a sequence of moments, captured, frozen, and woven into a narrative that defies the usual flow of time. Like drops filling a well, these moments accumulate within each film, creating a timeless reservoir. The TimeSink.

When a film plays, it allows those moments to live again, inviting the audience to re-experience them as though for the first time. This is the magic of cinema: each viewing is a new encounter, bringing different meanings, emotions, and insights that only reveal themselves as they interact with the soul watching. A TimeSink exists to hold this magic, enabling audiences to step back into a film’s preserved moments, repeatedly discovering something new in the familiar.

The power of TimeSink lies in this continuity, in how each film remains alive as long as there is someone to witness it, a soul to animate the story. TimeSink captures this essence—a place where time flows and pauses, where films remain vibrant and re-watchable, and where each visit feels like a fresh discovery. It’s a reminder that time, in the hands of art, isn’t fleeting—it’s a wellspring, endlessly revisited, renewed, and re-experienced.

![AaronZomback_expressionist _with_a_film_projector_and_wheel _ma_47afc7bb-9491-4a5f-8abd-251a1b0e76ba copy](https://github.com/user-attachments/assets/f4bc42ae-0c64-4c1e-b0ac-f0765fe2b3c7)

## 🍸️ TimeSink Presents

Step into **TimeSink Presents**, a virtual cinema that feels as if it’s been nestled in a hidden corner of the world, a place that might just exist somewhere deep in the cityscape—a subterranean café, a smoky dimly lit lounge bearing the name TimeSink. Here, the air hums with the echoes of jazz and classic film scores, the walls steeped in a timeless patina where legends of cinema come alive. An intriguing crowd gathers, a cast of characters from all walks of life, each adding to the place’s ever-growing mythology. Every screening at TimeSink carries a sense of wonder, transporting viewers through eras and across genres, as if one might encounter the giants of film history in every frame, every breath.

This isn’t just a digital platform; it’s an imaginary world made real. TimeSink is a timeless theater, an ever-evolving show, drawing people together to share in the mysteries of cinema. The films are just the beginning: it’s the conversations, the creator-audience connections, the palpable community that follow which create something enduring and transformative. Here, imagination, history, and community converge, forming a cinematic experience beyond the screen, alive in the minds of its members. Here, every moment holds the potential for inspiration, sparking the creative spirit. This is a space where cinema becomes real, bridging imagination and reality — something the world needs now more than ever.

![AaronZomback_Fun_cinema_projected_lights_come_from_inside _Peop_b9320108-eaf2-4d4d-8427-c311c85ea1fa copy](https://github.com/user-attachments/assets/c0f6a6ac-cc87-43fe-88ec-23d633156202)

Dive into our setup instructions below to get your environment up and running, and see our [glossary](./OVERVIEW.md) of cinema terms to make sure we're all on the same page!

## 🚀 Getting Started

You'll need the following system dependencies:

- [asdf](https://asdf-vm.com)
- [Docker](https://www.docker.com) (with [Docker Compose](https://docs.docker.com/compose/))
- [PostgreSQL](https://www.postgresql.org)

You'll need to install the respective asdf plugins:

```
asdf plugin add erlang
asdf plugin add elixir
```

Now, install Elixir and Erlang through asdf:

```
asdf install
```

MinIO is provided through a Docker Compose setup:

```
docker compose up -d
```

To start your Phoenix server:

1. **Install and Set Up Dependencies**

   ```bash
   mix setup
   ```

2. **Run Database Migrations**

After setting up dependencies, make sure your database is up to date by running migrations:

```bash
mix ecto.migrate
```

3. **Start Phoenix Endpoint**

Run `mix phx.server` or start it inside IEx with:

```bash
iex -S mix phx.server
```

Now, you can visit `localhost:4000` in your browser.

## 🏗️ Production Setup

Ready to deploy? Please consult our deployment guides for best practices and tips.

---

## 📚 Learn More

- **Official Phoenix Framework Site**: [https://www.phoenixframework.org/](https://www.phoenixframework.org/)
- **Guides**: [https://hexdocs.pm/phoenix/overview.html](https://hexdocs.pm/phoenix/overview.html)
- **Documentation**: [https://hexdocs.pm/phoenix](https://hexdocs.pm/phoenix)
- **Forum**: [https://elixirforum.com/c/phoenix-forum](https://elixirforum.com/c/phoenix-forum)
- **Source Code**: [https://github.com/phoenixframework/phoenix](https://github.com/phoenixframework/phoenix)
