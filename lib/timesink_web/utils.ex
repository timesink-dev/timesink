defmodule TimesinkWeb.Utils do
  def format_date(datetime) do
    datetime
    |> Timex.to_datetime("UTC")
    |> Timex.format!("{Mfull} {D}, {YYYY}")
  end

  def trim_fields(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, acc ->
      Ecto.Changeset.update_change(acc, field, fn val -> val |> to_string() |> String.trim() end)
    end)
  end
end
