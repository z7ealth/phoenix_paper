defmodule PhoenixPaper.AppBar do
  @moduledoc """
  A Material Design app bar (`pp_app_bar/1`), in the spirit of MUI's
  `AppBar` — a horizontal header bar with a `leading` slot (e.g.
  `PhoenixPaper.Drawer.pp_drawer_toggle/1` on mobile), a title (the default
  slot), and trailing `actions`.

      <.pp_app_bar position="sticky">
        <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
        My App
        <:actions>
          <.pp_button variant="icon"><.pp_icon name="hero-bell" /></.pp_button>
        </:actions>
      </.pp_app_bar>

  Named `AppBar` (not `Navbar`, an earlier name in this library) to match
  MUI's own naming — it's the same "toolbar" concept MUI's `AppBar`+
  `Toolbar` pair covers, just one component here since there's no reason to
  split them when this library doesn't support multiple toolbar rows inside
  one bar the way MUI's composition technically allows.

  `position` covers all five of MUI's values: `static` (normal flow),
  `relative` (normal flow, but establishes a positioning context for an
  absolutely-positioned child — e.g. a badge or a bottom-bar FAB notch you
  add yourself), `sticky`/`fixed`/`absolute` (self-explanatory, `fixed`
  pinned to the viewport, `absolute` pinned to the nearest positioned
  ancestor). There's no dedicated "bottom app bar" position value like some
  MUI examples build (`sx={{ top: 'auto', bottom: 0 }}`) — use `position="fixed"`
  with your own `class="!top-auto !bottom-0"` override instead; a real
  cut-out "notch" around a center FAB (MUI's bottom-app-bar demo) needs a
  CSS `clip-path`/mask shaped to a specific FAB size and isn't built in.

  `color="transparent"` renders no background/text-color classes at all
  (fully see-through, inheriting the caller's own text color) — used over a
  hero image or video, for example. There's no MUI `color="inherit"`
  variant here: in this library's plain-CSS-class model there's no
  meaningful difference between "inherit text color, keep default
  background" and "no color classes at all", so only `transparent` is
  offered, covering both.

  `variant="dense"` shrinks the toolbar row to MUI's dense `Toolbar` height
  (denser padding, smaller title text) — MUI's "prominent" app bar (a taller,
  two-row bar with the title below the icon row) isn't a single prop even in
  MUI itself, just a manually laid-out taller `Toolbar`; compose that
  yourself the same way, e.g. wrap the default slot's content across two
  flex rows and set `class="h-32"`.

  ## Constraining the toolbar width

  By default the toolbar row spans the full bar edge to edge. `max_width`
  caps and centres its content the way you'd wrap MUI's `Toolbar` in a
  `<Container>` — so the bar's background still bleeds to the viewport
  edges, but its icons/title/actions line up with a `pp_container` of the
  same `max_width` in the page body below:

      <.pp_app_bar position="sticky" max_width="xl">…</.pp_app_bar>
      <.pp_container max_width="xl">…page…</.pp_container>

  `disable_gutters` drops the toolbar's horizontal padding (MUI's
  `Toolbar disableGutters`) — for a bar whose children manage their own
  edge spacing. The default gutters are responsive (`px-4` rising to
  `px-6` from the `sm` breakpoint), matching MUI's own `Toolbar`.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers}

  attr(:color, :string,
    default: "primary",
    values: ~w(primary secondary tertiary surface transparent)
  )

  attr(:elevation, :integer,
    default: 4,
    doc:
      "resting elevation (0-24), see PhoenixPaper.Elevation — ignored for color=\"transparent\""
  )

  attr(:position, :string,
    default: "static",
    values: ~w(static relative sticky fixed absolute)
  )

  attr(:variant, :string,
    default: "regular",
    values: ~w(regular dense),
    doc: "dense shrinks the toolbar row height/padding/title size"
  )

  attr(:max_width, :string,
    default: "full",
    values: ~w(sm md lg xl 2xl full),
    doc: "caps and centres the toolbar content, like wrapping MUI's Toolbar in a Container"
  )

  attr(:disable_gutters, :boolean,
    default: false,
    doc: "drops the toolbar's horizontal padding (MUI's Toolbar disableGutters)"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:leading)
  slot(:actions)
  slot(:inner_block, required: true)

  @doc "Renders an app bar. See the module doc."
  def pp_app_bar(assigns) do
    ~H"""
    <header
      data-pp-component="app-bar"
      class={Helpers.classes(@paperize, paper_classes(@color, @elevation, @position), @class)}
      {@rest}
    >
      <div class={toolbar_classes(@variant, @max_width, @disable_gutters)}>
        <div :if={@leading != []} class="flex items-center">{render_slot(@leading)}</div>
        <div class={title_classes(@variant)}>{render_slot(@inner_block)}</div>
        <div :if={@actions != []} class="flex items-center gap-1">{render_slot(@actions)}</div>
      </div>
    </header>
    """
  end

  defp paper_classes("transparent", _elevation, position), do: position_classes(position)

  defp paper_classes(color, elevation, position) do
    [color_classes(color), Elevation.class(elevation), position_classes(position)]
  end

  defp color_classes("primary"), do: "bg-pp-primary text-pp-on-primary"
  defp color_classes("secondary"), do: "bg-pp-secondary text-pp-on-secondary"
  defp color_classes("tertiary"), do: "bg-pp-tertiary text-pp-on-tertiary"
  defp color_classes("surface"), do: "bg-pp-surface text-pp-on-surface"

  defp position_classes("static"), do: "static"
  defp position_classes("relative"), do: "relative"
  defp position_classes("sticky"), do: "sticky top-0 z-20"
  defp position_classes("fixed"), do: "fixed inset-x-0 top-0 z-20"
  defp position_classes("absolute"), do: "absolute inset-x-0 top-0 z-20"

  # The toolbar row's layout classes stay unconditional (not gated behind
  # `paperize`) for the reason spelled out in AGENTS.md — there's no `class`
  # attr on this inner div for a `paperize={false}` caller to rebuild the
  # three-region flex layout with. `max_width`/`disable_gutters` are part of
  # that same structural layer.
  defp toolbar_classes(variant, max_width, disable_gutters) do
    [
      row_classes(variant),
      "mx-auto w-full",
      max_width_class(max_width),
      gutter_classes(variant, disable_gutters)
    ]
  end

  defp row_classes("regular"), do: "flex h-16 items-center gap-4"
  defp row_classes("dense"), do: "flex h-12 items-center gap-3"

  defp gutter_classes(_variant, true), do: "px-0"
  defp gutter_classes("regular", false), do: "px-4 sm:px-6"
  defp gutter_classes("dense", false), do: "px-3 sm:px-4"

  defp max_width_class("sm"), do: "max-w-screen-sm"
  defp max_width_class("md"), do: "max-w-screen-md"
  defp max_width_class("lg"), do: "max-w-screen-lg"
  defp max_width_class("xl"), do: "max-w-screen-xl"
  defp max_width_class("2xl"), do: "max-w-screen-2xl"
  defp max_width_class("full"), do: "max-w-none"

  defp title_classes("regular"), do: "flex-1 truncate text-lg font-medium"
  defp title_classes("dense"), do: "flex-1 truncate text-base font-medium"
end
