defmodule Timesink.Utils do
  @doc """
  Converts a string into a lowercase, hyphen-separated slug.

  ## Examples

      iex> Timesink.Utils.Slugger.slugify("Cinéma Français")
      "cinema-francais"

      iex> Timesink.Utils.Slugger.slugify("Theater #1!")
      "theater-1"

  """
  def slugify(nil), do: nil

  def slugify(string) when is_binary(string) do
    string
    |> String.downcase()
    # decompose accented chars
    |> String.normalize(:nfd)
    # remove diacritics
    |> String.replace(~r/[\p{Mn}]/u, "")
    # remove punctuation
    |> String.replace(~r/[^\w\s-]/u, "")
    # collapse dashes and spaces
    |> String.replace(~r/[-\s]+/u, "-")
    |> String.trim("-")
  end
end
