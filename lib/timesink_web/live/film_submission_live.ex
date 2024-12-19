defmodule TimesinkWeb.FilmSubmissionLive do
  use TimesinkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="film-submission">
      <div id="film-submission-section">
        Film Submission
      </div>
    </div>
    """
  end
end
