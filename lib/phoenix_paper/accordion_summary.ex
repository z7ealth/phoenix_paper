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
      <PhoenixPaper.Icon.pp_icon name="hero-chevron-down" class="pp-accordion-icon shrink-0 text-pp-on-surface-variant pp-motion-spatial-fast" />
    </label>
    """
  end

  defp paper_classes do
    "relative flex min-h-14 cursor-pointer select-none items-center gap-4 rounded-[inherit] px-4 py-3 pp-title-medium pp-state-layer peer-focus-visible:outline-3 peer-focus-visible:-outline-offset-3 peer-focus-visible:outline-solid peer-focus-visible:outline-pp-secondary peer-disabled:pointer-events-none peer-disabled:opacity-38 peer-checked:[&_.pp-accordion-icon]:rotate-180"
  end
end
