defmodule PhoenixPaper.Fab do
  @moduledoc """
  An MD3 floating action button (`pp_fab/1`), with the M3 Expressive sizes
  and the extended FAB.

      <.pp_fab icon="hero-pencil" label="Compose" position="fixed" class="bottom-4 right-4" />
      <.pp_fab icon="hero-pencil" label="Compose" extended />

  The icon is the `icon` attr (a `hero-*` name) or the inner block for
  custom markup. `label` is required: it's the accessible name of an
  icon-only FAB, and the visible text of an `extended` one.

  ## Size (Expressive)

  | `size` | MD3 name | box | corners | icon |
  |--------|----------|-----|---------|------|
  | `default` | FAB | 56dp | 16dp | 24dp |
  | `medium` | medium FAB | 80dp | 20dp | 28dp |
  | `large` | large FAB | 96dp | 28dp | 36dp |

  MD3's small (40dp) FAB is deprecated in Expressive and not offered. An
  `extended` FAB keeps the size's height and corners and grows to fit the
  label (title-medium, title-large and headline-small type).

  ## Color

  `color` is `primary-container` (default), `secondary-container` or
  `tertiary-container` — the tonal FABs — or `primary`, `secondary`,
  `tertiary` — Expressive's higher-contrast FABs — or `surface`
  (`surface-container-high` with a `primary` icon). `lowered` drops the
  resting shadow from level 3 to level 1, for a FAB that sits on a
  surface rather than over content.

  ## Positioning

  Anchor it with `position` plus offsets in `class` — not `class="fixed"`,
  which would lose to the ripple's `relative` (see AGENTS.md).

  For a FAB that opens a menu of actions, see `PhoenixPaper.FabMenu`.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers, Icon, Ripple}

  attr(:icon, :string, default: nil, doc: "a hero-* icon name; or use the inner block")
  attr(:label, :string, required: true, doc: "accessible name; the visible text when extended")
  attr(:extended, :boolean, default: false, doc: "show the label next to the icon")
  attr(:size, :string, default: "default", values: ~w(default medium large))

  attr(:color, :string,
    default: "primary-container",
    values:
      ~w(primary-container secondary-container tertiary-container primary secondary tertiary surface)
  )

  attr(:lowered, :boolean, default: false, doc: "level-1 resting shadow instead of level 3")
  attr(:ripple, :boolean, default: true)

  attr(:position, :string,
    default: "relative",
    values: ~w(relative fixed absolute sticky),
    doc: "the root's CSS position; set it here, not via class"
  )

  attr(:disabled, :boolean, default: false)
  attr(:type, :string, default: "button", values: ~w(button submit reset))
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form name value))

  slot(:inner_block, doc: "custom icon markup, instead of the icon attr")

  @doc "Renders a floating action button. See the module doc."
  def pp_fab(assigns) do
    assigns = assign(assigns, :ripple?, assigns.ripple and assigns.paperize)

    ~H"""
    <button
      type={@type}
      disabled={@disabled}
      aria-label={!@extended && @label}
      data-pp-component="fab"
      data-pp-size={@size}
      class={Helpers.classes(@paperize, paper_classes(assigns), @class)}
      onclick={Ripple.on_click(@ripple?)}
      {@rest}
    >
      <Icon.pp_icon :if={@icon} name={@icon} size="none" class="size-[1em] shrink-0" />
      {render_slot(@inner_block)}
      <span :if={@extended} class={label_classes(@size)}>{@label}</span>
    </button>
    """
  end

  defp paper_classes(assigns) do
    [
      "inline-flex shrink-0 items-center justify-center cursor-pointer select-none pp-state-layer pp-focus-ring pp-motion-spatial-fast disabled:cursor-default disabled:pointer-events-none disabled:bg-pp-on-surface/10 disabled:text-pp-on-surface/38 disabled:shadow-none",
      size_classes(assigns.size, assigns.extended),
      color_classes(assigns.color),
      elevation_classes(assigns.lowered),
      Ripple.container_classes(true, assigns.position)
    ]
  end

  defp size_classes("default", false), do: "size-14 rounded-pp-lg text-[24px]"
  defp size_classes("medium", false), do: "size-20 rounded-pp-lg-increased text-[28px]"
  defp size_classes("large", false), do: "size-24 rounded-pp-xl text-[36px]"
  defp size_classes("default", true), do: "h-14 min-w-20 gap-3 px-4 rounded-pp-lg text-[24px]"

  defp size_classes("medium", true),
    do: "h-20 min-w-20 gap-3 px-6 rounded-pp-lg-increased text-[28px]"

  defp size_classes("large", true), do: "h-24 min-w-24 gap-4 px-7 rounded-pp-xl text-[36px]"

  defp label_classes("default"), do: "pp-title-medium whitespace-nowrap"
  defp label_classes("medium"), do: "pp-title-large whitespace-nowrap"
  defp label_classes("large"), do: "pp-headline-small whitespace-nowrap"

  defp color_classes("primary-container"),
    do: "bg-pp-primary-container text-pp-on-primary-container"

  defp color_classes("secondary-container"),
    do: "bg-pp-secondary-container text-pp-on-secondary-container"

  defp color_classes("tertiary-container"),
    do: "bg-pp-tertiary-container text-pp-on-tertiary-container"

  defp color_classes("primary"), do: "bg-pp-primary text-pp-on-primary"
  defp color_classes("secondary"), do: "bg-pp-secondary text-pp-on-secondary"
  defp color_classes("tertiary"), do: "bg-pp-tertiary text-pp-on-tertiary"
  defp color_classes("surface"), do: "bg-pp-surface-container-high text-pp-primary"

  defp elevation_classes(false), do: [Elevation.class(3), Elevation.hover_class(4)]
  defp elevation_classes(true), do: [Elevation.class(1), Elevation.hover_class(2)]
end
