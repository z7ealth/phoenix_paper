defmodule PhoenixPaper.AccordionActions do
  @moduledoc """
  An optional row of right-aligned buttons at the end of an expanded
  `PhoenixPaper.Accordion` (`pp_accordion_actions/1`) — shown only while
  expanded, the same as `PhoenixPaper.AccordionDetails`. See
  `PhoenixPaper.Accordion`'s moduledoc for a full example.

      <.pp_accordion_actions id="acc1">
        <.pp_button variant="text">Cancel</.pp_button>
        <.pp_button variant="text">Save</.pp_button>
      </.pp_accordion_actions>
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:id, :string, required: true, doc: "the same id passed to the parent pp_accordion/1")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders an accordion's action row. See the module doc."
  def pp_accordion_actions(assigns) do
    ~H"""
    <div
      data-pp-component="accordion-actions"
      class={Helpers.classes(@paperize, "hidden items-center justify-end gap-2 border-t border-pp-outline/20 px-2 py-2 peer-checked:flex", @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
