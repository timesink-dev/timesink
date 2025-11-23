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

## Continuous Integration

We use Fly.io for deploying our backend application.

Pushing to the branches `production` and `staging` will trigger a build and deploy to the respective environments.

### Production deployment

We use feature branches for development.

When a feature is finished it can be merged into the `staging` branch for testing

After testing and review the PR can be merged into `main` which will squash and merge.
Make sure the CI passes before proceeding with the production deployment.

To deploy to production we rebase `production` from `main` and push it. Run:
```bash
git checkout production
git rebase origin/main
git push origin production
```
Monitor the CI/CD pipeline for any errors. And check the systems after deployment.

Please don't merge `main` into the `production` branch. Rather use `git rebase origin/main`. Rebasing keeps our production history linear and aligned wit main, avoiding unnecessary merge commits. This makes the commit history easier to read and simplifies troubleshooting.

### Merging on staging

You can `git merge` into the `staging` branch for feature branches / PRs to test them before merging them into `main`. We occasionally reset `staging` back to `main` to realign both branches. To do that run
```bash
git checkout staging
git reset --hard origin/main
git push --force-with-lease
```
After that others need to reset their **local** staging branches to override the loacl history with the history from remote
```bash
git checkout staging
git reset --hard origin/main
```

## Help & Discussions

Reach out at the [Discord #dev channel](https://discord.com/channels/1263447434655436861/1288870802548199434).
