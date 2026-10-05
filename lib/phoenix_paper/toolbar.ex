defmodule PhoenixPaper.Toolbar do
  @moduledoc """
  An M3 Expressive toolbar (`pp_toolbar/1`) — a row (or column) of
  actions for the current page. It replaces MD3's bottom app bar.

      <%!-- docked: full-width bar at the bottom of the screen --%>
      <.pp_toolbar position="fixed">
        <.pp_icon_button icon="hero-archive-box" label="Archive" />
        <.pp_icon_button icon="hero-trash" label="Delete" />
        <.pp_icon_button icon="hero-envelope" label="Mark unread" />
      </.pp_toolbar>

      <%!-- floating: a pill over content, optionally paired with a FAB --%>
      <.pp_toolbar variant="floating" color="vibrant" position="fixed" class="bottom-4 inset-x-0 mx-auto">
        <.pp_icon_button icon="hero-bold" label="Bold" color="inherit" />
        <.pp_icon_button icon="hero-italic" label="Italic" color="inherit" />
        <:fab><.pp_fab icon="hero-check" label="Done" color="secondary-container" /></:fab>
      </.pp_toolbar>

  ## Variants and colors

  - `docked` (default): full width, 64dp, `surface-container`. Items are
    spread evenly.
  - `floating`: a fully rounded pill with a level-3 shadow, sized to its
    items. `orientation="vertical"` stacks them (an edge-anchored tool
    palette).

  `color` is `standard` (`surface-container`) or `vibrant`
  (`primary-container`). On `vibrant`, give icon buttons `color="inherit"`
  so they follow the toolbar's `on-primary-container` text instead of
  their own `on-surface-variant` default.

  The `:fab` slot renders next to a floating toolbar (beside it, or below
  a vertical one), the Expressive "toolbar with FAB" pairing.

  `position="fixed"` anchors a docked toolbar to the viewport bottom
  (`z-20`, safe-area padding). A floating toolbar takes `fixed`/`absolute`
  plus your own offsets in `class`.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers}

  attr(:variant, :string, default: "docked", values: ~w(docked floating))
  attr(:color, :string, default: "standard", values: ~w(standard vibrant))
  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))
  attr(:position, :string, default: "static", values: ~w(static relative fixed absolute sticky))
  attr(:label, :string, default: nil, doc: "aria-label of the toolbar")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:fab, doc: "a FAB paired with a floating toolbar")
  slot(:inner_block, required: true)

  @doc "Renders a toolbar. See the module doc."
  def pp_toolbar(%{variant: "docked"} = assigns) do
    ~H"""
    <div
      role="toolbar"
      aria-label={@label}
      data-pp-component="toolbar"
      data-pp-variant="docked"
      class={Helpers.classes(@paperize, docked_classes(@color, @position), @class)}
      {@rest}
    >
      <div class="mx-auto flex h-16 w-full max-w-screen-md items-center justify-around gap-2 px-4">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  def pp_toolbar(assigns) do
    ~H"""
    <div
      data-pp-component="toolbar"
      data-pp-variant="floating"
      class={["flex w-fit items-center gap-2", @orientation == "vertical" && "flex-col", position_class(@position), @class]}
      {@rest}
    >
      <div
        role="toolbar"
        aria-label={@label}
        aria-orientation={@orientation}
        class={Helpers.classes(@paperize, floating_classes(@color, @orientation), nil)}
      >
        {render_slot(@inner_block)}
      </div>
      {render_slot(@fab)}
    </div>
    """
  end

  defp docked_classes(color, position), do: [color_classes(color), docked_position(position)]

  defp docked_position("fixed"),
    do: "fixed inset-x-0 bottom-0 z-20 pb-[env(safe-area-inset-bottom)]"

  defp docked_position("sticky"), do: "sticky bottom-0 z-20 pb-[env(safe-area-inset-bottom)]"
  defp docked_position("absolute"), do: "absolute inset-x-0 bottom-0 z-20"
  defp docked_position("relative"), do: "relative"
  defp docked_position("static"), do: nil

  # Floating layout is plumbing, like Menu's anchor wrapper: unconditional.
  defp position_class("fixed"), do: "fixed z-20"
  defp position_class("absolute"), do: "absolute z-20"
  defp position_class("sticky"), do: "sticky z-20"
  defp position_class("relative"), do: "relative"
  defp position_class("static"), do: nil

  defp floating_classes(color, orientation) do
    [
      "inline-flex items-center gap-1 rounded-pp-full",
      if(orientation == "vertical", do: "flex-col px-2 py-4", else: "h-16 px-2"),
      color_classes(color),
      Elevation.class(3)
    ]
  end

  defp color_classes("standard"), do: "bg-pp-surface-container text-pp-on-surface"

  defp color_classes("vibrant"),
    do: "bg-pp-primary-container text-pp-on-primary-container"
end
