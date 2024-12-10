# Timesink
alias Timesink.Application
alias Timesink.Mailer
alias Timesink.Repo

# Timesink.Accounts
alias Timesink.Accounts
alias Timesink.Accounts.User

# Timesink.Cinema
alias Timesink.Cinema
alias Timesink.Cinema.Creative
alias Timesink.Cinema.Exhibition
alias Timesink.Cinema.Film
alias Timesink.Cinema.FilmCreative
alias Timesink.Cinema.Genre
alias Timesink.Cinema.Showcase
alias Timesink.Cinema.Theater

# Timesink.Waitlist
alias Timesink.Waitlist
alias Timesink.Waitlist.Applicant

# TimesinkWeb
alias TimesinkWeb.Endpoint
alias TimesinkWeb.Router
alias TimesinkWeb.Temeletry

alias TimesinkWeb.ErrorJSON

alias TimesinkWeb.PageController

# ExMachina factories
#
# To manually compile ExMachina factories, run:
# iex> Code.compile_file("test/support/factory.ex")
#
# Then, import them in your IEx with:
# iex> import Timesink.Factory

# Local dot-iex file (user/environment-specific, Git-ignored)
import_file_if_available(".iex.local.exs")
