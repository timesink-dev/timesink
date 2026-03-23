defmodule TimesinkWeb.Admin.Fields.RichText do
  use Backpex.Field, config_schema: []

  alias Backpex.HTML.Layout

  @impl Backpex.Field
  def render_value(assigns) do
    ~H"""
    <div class="prose prose-sm max-w-none text-zinc-300 line-clamp-3">
      {Phoenix.HTML.raw(Map.get(@item, @name))}
    </div>
    """
  end

  @impl Backpex.Field
  def render_form(assigns) do
    ~H"""
    <div>
      <Layout.field_container>
        <:label align={Backpex.Field.align_label(@field_options, assigns, :top)}>
          <Layout.input_label text={@field_options[:label]} />
        </:label>
        <div id={"trix-wrapper-#{Phoenix.HTML.Form.input_id(@form, @name)}"} phx-update="ignore">
          <input
            type="hidden"
            id={Phoenix.HTML.Form.input_id(@form, @name)}
            name={Phoenix.HTML.Form.input_name(@form, @name)}
            value={Phoenix.HTML.Form.input_value(@form, @name) || ""}
          />
          <trix-editor
            id={"trix-#{Phoenix.HTML.Form.input_id(@form, @name)}"}
            input={Phoenix.HTML.Form.input_id(@form, @name)}
            phx-hook="TrixEditor"
            data-input-id={Phoenix.HTML.Form.input_id(@form, @name)}
            class="mt-1 block w-full min-h-[220px] rounded-lg border border-zinc-700 bg-zinc-900 px-3 py-2 text-sm text-white focus:outline-none"
          >
          </trix-editor>
        </div>
      </Layout.field_container>
    </div>
    """
  end
end
