defmodule PhoenixPaper.AccordionDetails do
  @moduledoc """
  The collapsible content of a `PhoenixPaper.Accordion`
  (`pp_accordion_details/1`) — hidden until the accordion's checkbox/radio
  is checked, via `peer-checked:`. See `PhoenixPaper.Accordion`'s moduledoc
  for a full example.

  `id` isn't actually used for anything here (unlike `PhoenixPaper.AccordionSummary`,
  which needs it to build `for=`) — it's still required, so every
  `pp_accordion_*` component shares the same simple contract and a typo in
  one place (passing the wrong id to just one of the three) is at least
  visible in the markup rather than silently accepted.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:id, :string, required: true, doc: "the same id passed to the parent pp_accordion/1")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders accordion content. See the module doc."
  def pp_accordion_details(assigns) do
    ~H"""
    <div
      data-pp-component="accordion-details"
      class={Helpers.classes(@paperize, "hidden border-t border-pp-outline/20 px-4 py-3 text-sm peer-checked:block", @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
