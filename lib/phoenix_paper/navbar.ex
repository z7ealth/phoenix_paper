defmodule PhoenixPaper.Navbar do
  @moduledoc """
  A Material Design app bar (`pp_navbar/1`) — a horizontal header bar with a
  `leading` slot (e.g. `PhoenixPaper.Drawer.pp_drawer_toggle/1` on
  mobile), a title (the default slot), and trailing `actions`.

      <.pp_navbar position="sticky">
        <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
        My App
        <:actions>
          <.pp_button variant="icon"><.pp_icon name="hero-bell" /></.pp_button>
        </:actions>
      </.pp_navbar>
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers}

  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary surface))

  attr(:elevation, :integer,
    default: 4,
    doc: "resting elevation (0-24), see PhoenixPaper.Elevation"
  )

  attr(:position, :string, default: "static", values: ~w(static sticky fixed))
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:leading)
  slot(:actions)
  slot(:inner_block, required: true)

  @doc "Renders an app bar. See the module doc."
  def pp_navbar(assigns) do
    ~H"""
    <header
      data-pp-component="navbar"
      class={Helpers.classes(@paperize, paper_classes(@color, @elevation, @position), @class)}
      {@rest}
    >
      <div class="flex h-16 items-center gap-4 px-4">
        <div :if={@leading != []} class="flex items-center">{render_slot(@leading)}</div>
        <div class="flex-1 truncate text-lg font-medium">{render_slot(@inner_block)}</div>
        <div :if={@actions != []} class="flex items-center gap-1">{render_slot(@actions)}</div>
      </div>
    </header>
    """
  end

  defp paper_classes(color, elevation, position) do
    [color_classes(color), Elevation.class(elevation), position_classes(position)]
  end

  defp color_classes("primary"), do: "bg-pp-primary text-pp-on-primary"
  defp color_classes("secondary"), do: "bg-pp-secondary text-pp-on-secondary"
  defp color_classes("tertiary"), do: "bg-pp-tertiary text-pp-on-tertiary"
  defp color_classes("surface"), do: "bg-pp-surface text-pp-on-surface"

  defp position_classes("static"), do: "static"
  defp position_classes("sticky"), do: "sticky top-0 z-20"
  defp position_classes("fixed"), do: "fixed inset-x-0 top-0 z-20"
end
