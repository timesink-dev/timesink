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

  pipeline :put_current_user do
    plug TimesinkWeb.Plugs.PutCurrentUser
  end

  pipeline :require_authenticated_user do
    plug TimesinkWeb.Plugs.RequireAuthenticatedUser
  end

  pipeline :require_admin do
    plug TimesinkWeb.Plugs.RequireAdmin
  end

  pipeline :redirect_if_user_is_authenticated do
    plug TimesinkWeb.Plugs.RedirectIfUserIsAuthenticated
  end

  pipeline :require_invite_token do
    plug TimesinkWeb.Plugs.RequireInviteToken
  end

  scope "/", TimesinkWeb do
    pipe_through [:browser, :require_invite_token]
    live "/onboarding", OnboardingLive
end

  scope "/api", TimesinkWeb do
    pipe_through :api

    # Mux webhooks
    get "/webhooks/mux.com", MuxController, :it_works
    post "/webhooks/mux.com/:webhook_key", MuxController, :webhook
  end

  scope "/", TimesinkWeb do
    pipe_through :browser

    live "/join", WaitlistLive

    get "/invite/:token", InvitationController, :validate_invite
  end

  scope "/", TimesinkWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{TimesinkWeb.Auth, :redirect_if_user_is_authenticated}] do
      live "/sign_in", SignInLive
    end
  end

  scope "/", TimesinkWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: {TimesinkWeb.Auth, :ensure_authenticated} do
      live "/me", Accounts.MeLive
      live "/me/profile", Accounts.ProfileSettingsLive
      live "/me/security", Accounts.SecuritySettingsLive
      live "/now-playing/:theater_slug", Cinema.TheaterLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TimesinkWeb do
  #   pipe_through :api
  # end

  scope "/admin", TimesinkWeb do
    pipe_through [:browser, :require_admin]

    backpex_routes()

    get "/", RedirectController, :redirect_to_showcases

    live_session :admin, on_mount: Backpex.InitAssigns do
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

  scope "/", TimesinkWeb do
    pipe_through [:browser, :put_current_user]

    # static routes
    get "/info", PageController, :info

    get "/auth/complete_onboarding", AuthController, :complete_onboarding
    post "/sign_in", AuthController, :sign_in
    post "/sign_out", AuthController, :sign_out

    live_session :default, on_mount: {TimesinkWeb.Auth, :mount_current_user} do
      live "/", HomepageLive
      live "/submit", FilmSubmissionLive
      live "/archives", ArchiveLive
      live "/blog", BlogLive
      live "/upcoming", UpcomingLive
      live "/now-playing", Cinema.ShowcaseLive
      live "/:profile_username", Accounts.ProfileLive
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
