defmodule Timesink.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TimesinkWeb.Telemetry,
      Timesink.Repo,
      {DNSCluster, query: Application.get_env(:timesink, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Timesink.PubSub},
      TimesinkWeb.Presence,

      # Start the Finch HTTP client for sending emails
      {Finch, name: Timesink.Finch},
      # Start a worker by calling: Timesink.Worker.start_link(arg)
      # {Timesink.Worker, arg},
      {Oban, Application.fetch_env!(:timesink, Oban)},
      TimesinkWeb.Endpoint,
      {Timesink.Locations.Cache, name: Timesink.Locations.Cache},
      Timesink.Cinema.TheaterScheduler,
      Timesink.Cinema.ShowcaseCache,
      Timesink.UserCache,
      {Task.Supervisor, name: Timesink.TaskSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Timesink.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TimesinkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
