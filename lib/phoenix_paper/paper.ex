defmodule PhoenixPaper.Paper do
  @moduledoc """
  The base MD3 surface (`pp_paper/1`) — a container color, an optional
  shadow, an optional outline and a corner shape. No padding, no slots;
  `PhoenixPaper.Card`, `Dialog`, `Menu`, the sheets and others are built on
  it, and it's what to reach for when something just needs a surface.

      <.pp_paper color="surface-container-high" class="p-4">
        Anything can go here.
      </.pp_paper>

  ## Color, not shadow

  In MD3 a surface's height is mostly its **color**: the
  `surface-container-*` roles step from `lowest` to `highest`, and each
  component picks the one its spec names (cards `low`, menus `container`,
  dialogs `high`, ...). `elevation` (0-5, see `PhoenixPaper.Elevation`)
  adds a shadow on top, which MD3 reserves for a handful of components.
  Dark mode needs nothing extra: the container roles are their own dark
  tones (MD2's white elevation overlay is gone).

  `color` picks a background/foreground pair:

  | `color` | classes |
  |---------|---------|
  | `surface` | `bg-pp-surface text-pp-on-surface` |
  | `surface-container-lowest` .. `-highest` | `bg-pp-surface-container-* text-pp-on-surface` |
  | `surface-variant` | `bg-pp-surface-variant text-pp-on-surface-variant` |
  | `primary`, `secondary`, `tertiary`, `error` | `bg-pp-<c> text-pp-on-<c>` |
  | `primary-container`, ... `error-container` | `bg-pp-<c>-container text-pp-on-<c>-container` |
  | `inverse-surface` | `bg-pp-inverse-surface text-pp-inverse-on-surface` |
  | `transparent` | no background, inherited text color |

  `outlined` draws a 1px `outline-variant` border (MD3's outlined card).

  Wrappers pass `component` to mark the root with their own name
  (`<.pp_paper component="card">`), see AGENTS.md.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers, Shape}

  @colors ~w(surface surface-container-lowest surface-container-low surface-container surface-container-high surface-container-highest surface-variant primary secondary tertiary error primary-container secondary-container tertiary-container error-container inverse-surface transparent)

  @doc false
  def colors, do: @colors

  attr(:color, :string,
    default: "surface",
    values: @colors,
    doc: "container color role — how MD3 shows a surface's level"
  )

  attr(:elevation, :integer, default: 0, doc: "shadow level, 0-5")
  attr(:outlined, :boolean, default: false, doc: "1px outline-variant border")

  attr(:shape, :atom,
    default: :md,
    values: Shape.tokens(),
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  attr(:component, :string,
    default: "paper",
    doc: "overrides the data-pp-component marker, for components built on Paper"
  )

  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a surface. See the module doc."
  def pp_paper(assigns) do
    ~H"""
    <div
      data-pp-component={@component}
      class={
        Helpers.classes(@paperize, paper_classes(@color, @elevation, @outlined, @shape), @class)
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp paper_classes(color, elevation, outlined, shape) do
    [
      "block",
      color_classes(color),
      outlined && "border border-pp-outline-variant",
      Shape.class(shape),
      Elevation.class(elevation)
    ]
  end

  @doc false
  # Shared by components that need a role's background/foreground pair
  # without rendering a Paper (FAB, chips, badges).
  def color_classes("surface"), do: "bg-pp-surface text-pp-on-surface"

  def color_classes("surface-container-lowest"),
    do: "bg-pp-surface-container-lowest text-pp-on-surface"

  def color_classes("surface-container-low"),
    do: "bg-pp-surface-container-low text-pp-on-surface"

  def color_classes("surface-container"), do: "bg-pp-surface-container text-pp-on-surface"

  def color_classes("surface-container-high"),
    do: "bg-pp-surface-container-high text-pp-on-surface"

  def color_classes("surface-container-highest"),
    do: "bg-pp-surface-container-highest text-pp-on-surface"

  def color_classes("surface-variant"), do: "bg-pp-surface-variant text-pp-on-surface-variant"
  def color_classes("primary"), do: "bg-pp-primary text-pp-on-primary"
  def color_classes("secondary"), do: "bg-pp-secondary text-pp-on-secondary"
  def color_classes("tertiary"), do: "bg-pp-tertiary text-pp-on-tertiary"
  def color_classes("error"), do: "bg-pp-error text-pp-on-error"

  def color_classes("primary-container"),
    do: "bg-pp-primary-container text-pp-on-primary-container"

  def color_classes("secondary-container"),
    do: "bg-pp-secondary-container text-pp-on-secondary-container"

  def color_classes("tertiary-container"),
    do: "bg-pp-tertiary-container text-pp-on-tertiary-container"

  def color_classes("error-container"), do: "bg-pp-error-container text-pp-on-error-container"
  def color_classes("inverse-surface"), do: "bg-pp-inverse-surface text-pp-inverse-on-surface"
  def color_classes("transparent"), do: "bg-transparent"
end
