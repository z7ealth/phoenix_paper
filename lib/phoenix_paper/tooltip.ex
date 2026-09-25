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

  ## Colors and styles

  The bubble takes the same styling attrs as `PhoenixPaper.Button`:

  - `color` — `"default"` (the default), `"primary"`, `"secondary"`,
    `"accent"`, `"error"`. `"default"` is an inverted surface
    (`bg-pp-on-surface`/`text-pp-surface`) whatever the theme, the same
    choice `PhoenixPaper.Snackbar` makes: Material's spec tooltip is a dark
    chip on a light theme and a light chip on a dark theme. The brand
    colors fill it like a raised button (`bg-pp-primary
    text-pp-on-primary`, ...).
  - `variant` — `"raised"` (default: filled, with a shadow), `"flat"`
    (filled, no shadow) or `"outlined"` (surface background with a colored
    border and text, like an outlined button; `color="default"` uses the
    neutral outline color). There's no `"text"` variant: a tooltip with no
    background would be unreadable over whatever it floats on.
  - `size` — `"small"`, `"medium"` (default), `"large"`: padding and font
    size.
  - `shape` — a `PhoenixPaper.Shape` token, default `:sm`; `:full` gives a
    pill like a button.

  The `arrow` always matches the bubble (fill, and for `outlined` the
  border on its two outer edges).

      <.pp_tooltip title="Saved" color="primary" shape={:full}>...</.pp_tooltip>
      <.pp_tooltip title="Careful" color="error" variant="outlined" arrow>...</.pp_tooltip>
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Shape}

  attr(:title, :any,
    default: nil,
    doc: "the tooltip text — nil or \"\" disables the tooltip (renders just the trigger)"
  )

  attr(:placement, :string, default: "top", values: ~w(top bottom left right))
  attr(:arrow, :boolean, default: false, doc: "a small triangle pointing at the trigger")

  attr(:color, :string,
    default: "default",
    values: ~w(default primary secondary accent error),
    doc: "default is the inverted Material tooltip; the others fill it with a brand color"
  )

  attr(:variant, :string, default: "raised", values: ~w(raised flat outlined))
  attr(:size, :string, default: "medium", values: ~w(small medium large))

  attr(:shape, :atom,
    default: :sm,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

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
        class={
          Helpers.classes(
            @paperize,
            bubble_classes(@placement, @variant, @color, @size, @shape),
            @class
          )
        }
      >
        {@title}
        <span
          :if={@arrow}
          class={
            Helpers.classes(
              @paperize,
              [arrow_classes(@placement), arrow_fill_classes(@variant, @color, @placement)],
              nil
            )
          }
        />
      </span>
    </span>
    """
  end

  defp bubble_classes(placement, variant, color, size, shape) do
    [
      "pointer-events-none absolute z-20 whitespace-nowrap font-medium opacity-0 transition-opacity duration-150 group-hover:opacity-100 group-focus-within:opacity-100",
      placement_classes(placement),
      surface_classes(variant, color),
      elevation_classes(variant),
      size_classes(size),
      Shape.class(shape)
    ]
  end

  defp placement_classes("top"), do: "bottom-full left-1/2 mb-2 -translate-x-1/2"
  defp placement_classes("bottom"), do: "top-full left-1/2 mt-2 -translate-x-1/2"
  defp placement_classes("left"), do: "right-full top-1/2 mr-2 -translate-y-1/2"
  defp placement_classes("right"), do: "left-full top-1/2 ml-2 -translate-y-1/2"

  defp surface_classes("outlined", "default"),
    do: "border border-pp-outline bg-pp-surface text-pp-on-surface"

  defp surface_classes("outlined", "primary"),
    do: "border border-pp-primary bg-pp-surface text-pp-primary"

  defp surface_classes("outlined", "secondary"),
    do: "border border-pp-secondary bg-pp-surface text-pp-secondary"

  defp surface_classes("outlined", "accent"),
    do: "border border-pp-accent bg-pp-surface text-pp-accent"

  defp surface_classes("outlined", "error"),
    do: "border border-pp-error bg-pp-surface text-pp-error"

  defp surface_classes(_filled, "default"), do: "bg-pp-on-surface text-pp-surface"
  defp surface_classes(_filled, "primary"), do: "bg-pp-primary text-pp-on-primary"
  defp surface_classes(_filled, "secondary"), do: "bg-pp-secondary text-pp-on-secondary"
  defp surface_classes(_filled, "accent"), do: "bg-pp-accent text-pp-on-accent"
  defp surface_classes(_filled, "error"), do: "bg-pp-error text-pp-on-error"

  defp elevation_classes("raised"), do: "shadow-md"
  defp elevation_classes(_flat_or_outlined), do: ""

  defp size_classes("small"), do: "px-1.5 py-0.5 text-[0.6875rem]"
  defp size_classes("medium"), do: "px-2 py-1 text-xs"
  defp size_classes("large"), do: "px-3 py-1.5 text-sm"

  defp arrow_classes("top"), do: "absolute -bottom-1 left-1/2 size-2 -translate-x-1/2 rotate-45"
  defp arrow_classes("bottom"), do: "absolute -top-1 left-1/2 size-2 -translate-x-1/2 rotate-45"
  defp arrow_classes("left"), do: "absolute -right-1 top-1/2 size-2 -translate-y-1/2 rotate-45"
  defp arrow_classes("right"), do: "absolute -left-1 top-1/2 size-2 -translate-y-1/2 rotate-45"

  # An outlined arrow is a surface-colored square with a border on only the
  # two edges that stick out of the bubble (which two depends on which side
  # of the bubble it's on), so it reads as the bubble's outline bending
  # into a point.
  defp arrow_fill_classes("outlined", color, placement),
    do: ["bg-pp-surface", arrow_border_color(color), arrow_border_edges(placement)]

  defp arrow_fill_classes(_filled, "default", _placement), do: "bg-pp-on-surface"
  defp arrow_fill_classes(_filled, "primary", _placement), do: "bg-pp-primary"
  defp arrow_fill_classes(_filled, "secondary", _placement), do: "bg-pp-secondary"
  defp arrow_fill_classes(_filled, "accent", _placement), do: "bg-pp-accent"
  defp arrow_fill_classes(_filled, "error", _placement), do: "bg-pp-error"

  defp arrow_border_color("default"), do: "border-pp-outline"
  defp arrow_border_color("primary"), do: "border-pp-primary"
  defp arrow_border_color("secondary"), do: "border-pp-secondary"
  defp arrow_border_color("accent"), do: "border-pp-accent"
  defp arrow_border_color("error"), do: "border-pp-error"

  defp arrow_border_edges("top"), do: "border-b border-r"
  defp arrow_border_edges("bottom"), do: "border-t border-l"
  defp arrow_border_edges("left"), do: "border-t border-r"
  defp arrow_border_edges("right"), do: "border-b border-l"
end
