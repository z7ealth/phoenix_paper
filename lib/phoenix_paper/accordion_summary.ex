defmodule PhoenixPaper.AccordionSummary do
  @moduledoc """
  The clickable header of a `PhoenixPaper.Accordion` (`pp_accordion_summary/1`)
  — a `<label>` pointing at the accordion's hidden checkbox/radio, with a
  trailing expand icon that rotates via `peer-checked:`. See
  `PhoenixPaper.Accordion`'s moduledoc for a full example.

  `id` must be the *same* id passed to the parent `pp_accordion/1` — it's
  how this label finds the right checkbox to point `for=` at.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.Accordion, only: [toggle_id: 1]

  attr(:id, :string, required: true, doc: "the same id passed to the parent pp_accordion/1")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders an accordion summary/header. See the module doc."
  def pp_accordion_summary(assigns) do
    ~H"""
    <label
      for={toggle_id(@id)}
      data-pp-component="accordion-summary"
      class={Helpers.classes(@paperize, paper_classes(), @class)}
      {@rest}
    >
      <div class="min-w-0 flex-1">{render_slot(@inner_block)}</div>
      <span class="pp-accordion-icon shrink-0 transition-transform">▾</span>
    </label>
    """
  end

  defp paper_classes do
    "flex cursor-pointer items-center gap-2 px-4 py-3 select-none hover:bg-pp-on-surface/5 peer-disabled:cursor-not-allowed peer-disabled:opacity-40 peer-checked:[&_.pp-accordion-icon]:rotate-180"
  end
end
