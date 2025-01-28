defmodule TimesinkWeb.Router do
  import Backpex.Router
  use TimesinkWeb, :router

  import TimesinkWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TimesinkWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticate_user do
    plug TimesinkWeb.Plugs.AuthenticateUser
  end

  pipeline :authenticate_admin do
    plug TimesinkWeb.Plugs.AuthenticateAdmin
  end

  scope "/", TimesinkWeb do
    pipe_through :browser
    live "/", HomepageLive
    live "/now-playing", Cinema.ShowcaseLive
    live "/now-playing/:theater_slug", Cinema.TheaterLive

    live "/join", WaitlistLive
    live "/sign_in", SignInLive

    live "/submit", FilmSubmissionLive

    live "/archives", ArchiveLive
    live "/blog", BlogLive
    live "/upcoming", UpcomingLive

    # Static pages
    get "/info", PageController, :info

    live "/me", Accounts.MeLive
    live "/me/profile", Accounts.ProfileSettingsLive
    live "/me/security", Accounts.SecuritySettingsLive

    live "/:profile_username", Accounts.ProfileLive

    post "/sign_in", AuthController, :sign_in
    post "/sign_out", AuthController, :sign_out
  end

  # Authenticated user routes
  # scope "/", TimesinkWeb do
  #   # pipe_through [:browser, :authenticate_user]

  #   live "/me", Accounts.MeLive
  #   live "/me/profile", Accounts.ProfileSettingsLive
  #   live "/me/security", Accounts.SecuritySettingsLive
  # end

  # Other scopes may use custom stacks.
  # scope "/api", TimesinkWeb do
  #   pipe_through :api
  # end

  # live_session :admin do
  scope "/admin", TimesinkWeb do
    # pipe_through [:http_auth_admin]

    pipe_through :browser

    backpex_routes()

    get "/", RedirectController, :redirect_to_showcases

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

  ## Authentication routes

  scope "/", TimesinkWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{TimesinkWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", TimesinkWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{TimesinkWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", TimesinkWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{TimesinkWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
