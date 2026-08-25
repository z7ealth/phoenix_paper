defmodule PhoenixPaper.Accordion do
  @moduledoc """
  A collapsible panel (`pp_accordion/1`), in the spirit of MUI's
  `Accordion` — composed with `PhoenixPaper.AccordionSummary` (the
  clickable header), `PhoenixPaper.AccordionDetails` (the collapsible
  content), and optionally `PhoenixPaper.AccordionActions` (a button row
  shown only while expanded):

      <.pp_accordion id="acc1">
        <.pp_accordion_summary id="acc1">What is Material Design?</.pp_accordion_summary>
        <.pp_accordion_details id="acc1">
          A design system by Google...
        </.pp_accordion_details>
      </.pp_accordion>

  Pure CSS, no JS/LiveView — the same hidden-checkbox-plus-`peer-checked:`
  trick as `PhoenixPaper.Drawer`/`PhoenixPaper.Rating`. `pp_accordion/1`
  renders the (visually hidden) checkbox as the *first* child inside its own
  `PhoenixPaper.Paper` surface; `AccordionSummary`/`AccordionDetails`/
  `AccordionActions` are written as its `inner_block`, making them flat
  siblings *after* the checkbox — required for `peer-checked:` to reach them
  (see AGENTS.md, "CSS-only interactive state"). All three sub-components
  need the *same* `id` as `pp_accordion/1` itself, to build the matching
  `for={"\#{id}-toggle"}`/`peer-checked:` wiring — there's no implicit way
  for sibling components to discover it otherwise.

  ## Exclusive groups (only one open at a time)

  Give every accordion in the group the same `name` and each renders a
  `type="radio"` instead of a checkbox — same-named radios are mutually
  exclusive natively, no JS or LiveView state needed:

      <.pp_accordion id="acc1" name="faq">...</.pp_accordion>
      <.pp_accordion id="acc2" name="faq">...</.pp_accordion>

  This is a narrower version of MUI's controlled exclusive-accordion
  pattern: a checked radio can't be *unchecked* by clicking it again (a real
  HTML limitation, not a choice), so once one panel is open in the group,
  one always stays open — there's no "all collapsed" state to return to,
  unlike MUI's JS-driven version.

  `default_expanded` sets the checkbox/radio's initial `checked` — like
  `PhoenixPaper.Drawer`'s toggle, this is a plain, uncontrolled HTML
  checkbox with no `checked={@some_assign}` wiring back to the server, so
  there's nothing for a later, unrelated LiveView re-render to fight with
  over who owns the "true" expanded state.

  There's no `square` prop like MUI's — use `shape={:none}` (the same attr
  every other component's corner radius goes through) instead of a
  redundant, Accordion-only boolean.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  import PhoenixPaper.Paper, only: [pp_paper: 1]

  attr(:id, :string, required: true, doc: "shared with AccordionSummary/Details/Actions")

  attr(:name, :string,
    default: nil,
    doc: "shared across accordions for an exclusive group (radio instead of checkbox)"
  )

  attr(:default_expanded, :boolean, default: false)
  attr(:disabled, :boolean, default: false)

  attr(:disable_gutters, :boolean,
    default: false,
    doc: "skip the extra margin an expanded accordion normally gets"
  )

  attr(:paperize, :boolean, default: true)
  attr(:elevation, :integer, default: 1)

  attr(:shape, :atom,
    default: :md,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders an accordion panel. See the module doc."
  def pp_accordion(assigns) do
    ~H"""
    <.pp_paper
      elevation={@elevation}
      shape={@shape}
      paperize={@paperize}
      component="accordion"
      class={Helpers.classes(@paperize, gutters_classes(@disable_gutters), @class)}
      {@rest}
    >
      <input
        type={if @name, do: "radio", else: "checkbox"}
        id={toggle_id(@id)}
        name={@name}
        checked={@default_expanded}
        disabled={@disabled}
        class="peer sr-only"
      />
      {render_slot(@inner_block)}
    </.pp_paper>
    """
  end

  @doc false
  def toggle_id(id), do: "#{id}-toggle"

  # The checkbox is a *descendant* of this Paper root (rendered as its own
  # first child), not a sibling — `peer-checked:` only reaches later
  # siblings of the peer, so reacting to "my own descendant checkbox is
  # checked" needs `has-[:checked]:` instead, unlike every other
  # peer-checked usage in this file (which all target true siblings).
  defp gutters_classes(false), do: "has-[:checked]:my-2"
  defp gutters_classes(true), do: ""
end
