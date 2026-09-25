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

  ## Colors and styles

  The same styling attrs as `PhoenixPaper.Button`/`PhoenixPaper.Tooltip`,
  set once on `pp_accordion/1` and reaching the summary/details/actions
  inside it:

  - `variant` — `"raised"` (default: a `Paper` surface at `elevation`,
    unchanged from before), `"flat"` (the same surface with no shadow) or
    `"outlined"` (no shadow, a 1px border — MUI's `variant="outlined"`).
  - `color` — `"default"` (the neutral surface, unchanged) or
    `"primary"`/`"secondary"`/`"accent"`/`"error"`. On `raised`/`flat` a
    brand color fills the whole panel (`bg-pp-primary
    text-pp-on-primary`, with the details/actions dividers switched to a
    matching `on-*` tint); on `outlined` it colors the border and the
    summary text instead, on the normal surface.

        <.pp_accordion id="faq1" color="primary">...</.pp_accordion>
        <.pp_accordion id="faq2" variant="outlined" color="accent">...</.pp_accordion>

  A `pp_button` inside a filled accordion's actions needs
  `color="inherit"`, or its brand-colored text disappears into the
  same-colored panel (the AppBar pitfall in AGENTS.md).

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

  attr(:elevation, :integer,
    default: 1,
    doc: "resting elevation for variant=raised (flat and outlined have none)"
  )

  attr(:variant, :string, default: "raised", values: ~w(raised flat outlined))

  attr(:color, :string,
    default: "default",
    values: ~w(default primary secondary accent error),
    doc: "fills the panel (raised/flat) or colors border + summary (outlined)"
  )

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
      elevation={if @variant == "raised", do: @elevation, else: 0}
      shape={@shape}
      color={paper_color(@variant, @color)}
      paperize={@paperize}
      component="accordion"
      data-pp-variant={@variant}
      class={
        Helpers.classes(
          @paperize,
          [gutters_classes(@disable_gutters), style_classes(@variant, @color)],
          @class
        )
      }
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

  # Filled variants take their background from Paper's own `color` (so
  # there's no `bg-pp-surface` left to fight); outlined stays on the
  # surface and colors its border instead.
  defp paper_color("outlined", _color), do: "surface"
  defp paper_color(_filled, "default"), do: "surface"
  defp paper_color(_filled, color), do: color

  # Filled brand colors switch the details/actions dividers to an `on-*`
  # tint (the default `border-pp-outline/20` barely shows on a brand
  # fill); outlined colors reach the summary text. Both via
  # `data-pp-component` child selectors, since the parts are separate
  # components with no color attr of their own.
  defp style_classes("outlined", "default"), do: "border border-pp-outline"

  defp style_classes("outlined", "primary"),
    do: "border border-pp-primary [&>[data-pp-component=accordion-summary]]:text-pp-primary"

  defp style_classes("outlined", "secondary"),
    do: "border border-pp-secondary [&>[data-pp-component=accordion-summary]]:text-pp-secondary"

  defp style_classes("outlined", "accent"),
    do: "border border-pp-accent [&>[data-pp-component=accordion-summary]]:text-pp-accent"

  defp style_classes("outlined", "error"),
    do: "border border-pp-error [&>[data-pp-component=accordion-summary]]:text-pp-error"

  defp style_classes(_filled, "default"), do: ""

  defp style_classes(_filled, "primary"),
    do:
      "[&>[data-pp-component=accordion-details]]:border-pp-on-primary/20 [&>[data-pp-component=accordion-actions]]:border-pp-on-primary/20"

  defp style_classes(_filled, "secondary"),
    do:
      "[&>[data-pp-component=accordion-details]]:border-pp-on-secondary/20 [&>[data-pp-component=accordion-actions]]:border-pp-on-secondary/20"

  defp style_classes(_filled, "accent"),
    do:
      "[&>[data-pp-component=accordion-details]]:border-pp-on-accent/20 [&>[data-pp-component=accordion-actions]]:border-pp-on-accent/20"

  defp style_classes(_filled, "error"),
    do:
      "[&>[data-pp-component=accordion-details]]:border-pp-on-error/20 [&>[data-pp-component=accordion-actions]]:border-pp-on-error/20"
end
