defmodule PhoenixPaper.Tooltip do
  @moduledoc """
  A short text label shown on hover/focus (`pp_tooltip/1`), in the spirit
  of MUI's `Tooltip`.

      <.pp_tooltip title="Delete">
        <.pp_button variant="icon"><.pp_icon name="hero-trash" /></.pp_button>
      </.pp_tooltip>

      <.pp_tooltip title="Add to favorites" placement="right" arrow>
        <.pp_icon name="hero-star" />
      </.pp_tooltip>

  Pure CSS — Tailwind's `group`/`group-hover:`/`group-focus-within:`, no
  JS/LiveView/hook at all, not even a small vanilla snippet like
  `PhoenixPaper.Ripple`'s. `group-focus-within:` (not just `group-hover:`)
  means a keyboard user tabbing to a focusable trigger (a button, a link)
  sees the tooltip too, not just a mouse user hovering it.

  Two real simplifications versus MUI's `Tooltip`, both because there's no
  JS here to do better:

  - **`placement` is one of the 4 cardinal directions** (`top` — the
    default — `bottom`, `left`, `right`), not MUI's full 12-way
    `top-start`/`top-end`/etc. matrix.
  - **No collision detection/auto-flip.** MUI's `Tooltip` is built on
    Popper/Floating UI, which repositions the tooltip on the fly if the
    chosen `placement` would overflow the viewport. This is a fixed
    `position: absolute` offset picked once at render time — if a
    `placement="top"` tooltip is near the top edge of the viewport, it'll
    render off-screen the same way a plain CSS-only tooltip anywhere else
    would. Pick a `placement` that fits where the trigger actually sits on
    the page.

  `title` (matching MUI's prop name exactly) disables the tooltip the same
  way MUI's does: `nil` or `""` renders the trigger with no tooltip
  wrapper at all, no empty bubble that would otherwise pop up on hover.

  The trigger wrapper's `group relative inline-flex` is not gated by
  `paperize` — like `PhoenixPaper.Badge`'s wrapper, it's the minimum
  structure the tooltip needs to position itself at all, not part of the
  "paper" skin. `paperize={false}` still drops every class from the bubble
  itself (position, color, the hover-reveal transition, everything), same
  all-or-nothing contract as everywhere else.

  Always an inverted surface (`bg-pp-on-surface`/`text-pp-surface`)
  regardless of the current theme, the same deliberate choice
  `PhoenixPaper.Snackbar` makes and for the same reason: Material's spec
  tooltip is a dark chip on a light theme and a light chip on a dark theme,
  not a themed surface.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:title, :any,
    default: nil,
    doc: "the tooltip text — nil or \"\" disables the tooltip (renders just the trigger)"
  )

  attr(:placement, :string, default: "top", values: ~w(top bottom left right))
  attr(:arrow, :boolean, default: false, doc: "a small triangle pointing at the trigger")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true, doc: "the trigger element")

  @doc "Renders a tooltip. See the module doc."
  def pp_tooltip(assigns) do
    ~H"""
    <span data-pp-component="tooltip" class="group relative inline-flex" {@rest}>
      {render_slot(@inner_block)}
      <span
        :if={@title not in [nil, ""]}
        role="tooltip"
        data-pp-component="tooltip-bubble"
        data-pp-placement={@placement}
        class={Helpers.classes(@paperize, bubble_classes(@placement), @class)}
      >
        {@title}
        <span :if={@arrow} class={Helpers.classes(@paperize, arrow_classes(@placement), nil)} />
      </span>
    </span>
    """
  end

  defp bubble_classes(placement) do
    [
      "pointer-events-none absolute z-20 whitespace-nowrap rounded bg-pp-on-surface px-2 py-1 text-xs font-medium text-pp-surface opacity-0 shadow-md transition-opacity duration-150 group-hover:opacity-100 group-focus-within:opacity-100",
      placement_classes(placement)
    ]
  end

  defp placement_classes("top"), do: "bottom-full left-1/2 mb-2 -translate-x-1/2"
  defp placement_classes("bottom"), do: "top-full left-1/2 mt-2 -translate-x-1/2"
  defp placement_classes("left"), do: "right-full top-1/2 mr-2 -translate-y-1/2"
  defp placement_classes("right"), do: "left-full top-1/2 ml-2 -translate-y-1/2"

  defp arrow_classes("top"),
    do: "absolute -bottom-1 left-1/2 size-2 -translate-x-1/2 rotate-45 bg-pp-on-surface"

  defp arrow_classes("bottom"),
    do: "absolute -top-1 left-1/2 size-2 -translate-x-1/2 rotate-45 bg-pp-on-surface"

  defp arrow_classes("left"),
    do: "absolute -right-1 top-1/2 size-2 -translate-y-1/2 rotate-45 bg-pp-on-surface"

  defp arrow_classes("right"),
    do: "absolute -left-1 top-1/2 size-2 -translate-y-1/2 rotate-45 bg-pp-on-surface"
end
