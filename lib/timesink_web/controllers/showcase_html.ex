defmodule TimesinkWeb.ShowcaseHTML do
  @moduledoc """
  This module contains pages rendered by ShowcaseController.

  See the `showcase_html` directory for all templates available.
  """
  use TimesinkWeb, :html

  embed_templates "showcase_html/*"
end
