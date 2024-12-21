defmodule TimesinkWeb.Utils do
  def format_date(datetime) do
    datetime
    |> Timex.to_datetime("UTC")
    |> Timex.format!("{Mfull} {D}, {YYYY}")
  end
end
