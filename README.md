# 🌌 TimeSink Presents

> **️🚧 Work in Progress**: This document is a living, ongoing work in progress! We're constantly improving and updating it to better reflect our evolving understanding of the platform and its features. As we build and refine TimeSink, this documentation will dynamically change, so check back often for the latest updates and improvements. Your contributions and suggestions are always welcome as we shape this exciting project together!

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
