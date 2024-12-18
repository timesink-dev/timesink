defmodule TimesinkWeb.Router do
  import Backpex.Router
  use TimesinkWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TimesinkWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TimesinkWeb do
    pipe_through :browser
    live "/", HomepageLive
    live "/now-playing", Cinema.ShowcaseLive
    live "/now-playing/:theater_slug", Cinema.TheaterLive

    live "/join", WaitlistLive
    live "/signin", SignInLive

    live "/me", Accounts.AccountLive
    live "/submit", FilmSubmissionLive

    # Static pages
    get "/info", PageController, :info
    get "/blog", BlogController, :index
    get "/archives", ShowcaseController, :archives
    get "/upcoming", ShowcaseController, :upcoming

    live "/:profile_username", Accounts.ProfileLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", TimesinkWeb do
  #   pipe_through :api
  # end

  scope "/admin", TimesinkWeb do
    pipe_through :browser

    backpex_routes()

    live_session :default, on_mount: Backpex.InitAssigns do
      live_resources "/showcases", Admin.ShowcaseLive
      live_resources "/waitlist", Admin.WaitlistLive
      live_resources "/films", Admin.FilmLive
      live_resources "/exhibitions", Admin.ExhibitionLive
      live_resources "/theaters", Admin.TheaterLive
      live_resources "/genres", Admin.GenreLive
      live_resources "/members", Admin.UserLive
      live_resources "/creatives", Admin.CreativeLive
      live_resources "/film_creatives", Admin.FilmCreativeLive
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:timesink, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TimesinkWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
