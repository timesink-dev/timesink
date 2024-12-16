# 🌌 TimeSink Presents

> **️🚧 Work in Progress**
>
> This document is a living, ongoing work in progress! We're constantly improving and updating it to better reflect our evolving understanding of the platform and its features. As we build and refine TimeSink, this documentation will dynamically change, so check back often for the latest updates and improvements. Your contributions and suggestions are always welcome as we shape this exciting project together!

## Overview

Check the [TimeSink Overview](OVERVIEW.md) for a proper introduction to the project and the ideas behind it. It's a good way to start if you're just onboarding!

## System dependencies

There are some system dependencies you'll need to set up before proceeding:

- **[asdf](https://asdf-vm.com)**
- **[Docker](https://www.docker.com)** and **[Docker Compose](https://docs.docker.com/compose/)**

Refer to their own websites for installation and setup instructions.

## Setup

With system dependencies in place, follow the steps below.

1. **Install asdf plugins:**

   ```
   asdf plugin add erlang
   asdf plugin add elixir
   ```

1. **Install Elixir and Erlang:**

   ```
   asdf install
   ```

1. **Launch Docker Compose services:**

   > 💡 You'll need the Docker services up and running for the next steps.

   ```
   docker compose up -d
   ```

1. **Run the Elixir setup script:**  
    It will download dependencies, create and seed the database, etc.

   ```
   mix setup
   ```

## Run

First, you'll need the Docker services up and running:

```
docker compose up -d
```

Then, start the development server with:

```
iex -S mix phx.server
```

TimeSink should be available at [localhost:4000](http://localhost:4000).

<!--
## 🏗️ Production Setup

Ready to deploy? Please consult our deployment guides for best practices and tips.
-->

## Test

Run all tests with:

```
mix test
```

There's also a static analyzer ([Dialyzer](https://www.erlang.org/doc/apps/dialyzer/dialyzer.html)) configured and available at the following command:

```
mix dialyzer
```

## Help & Discussions

Reach out at the [Discord #dev channel](https://discord.com/channels/1263447434655436861/1288870802548199434).
