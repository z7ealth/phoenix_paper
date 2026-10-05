defmodule PhoenixPaper.TopAppBar do
  @moduledoc """
  An MD3 top app bar (`pp_top_app_bar/1`), with the M3 Expressive
  flexible medium/large layouts and subtitles. Renamed from 0.3's
  `AppBar` (`pp_app_bar/1`).

      <.pp_top_app_bar position="sticky">
        <:leading><.pp_navigation_rail_toggle for="app-rail" /></:leading>
        Inbox
        <:actions>
          <.pp_icon_button icon="hero-magnifying-glass" label="Search" />
          <.pp_icon_button icon="hero-ellipsis-vertical" label="More" />
        </:actions>
      </.pp_top_app_bar>

  ## Variants

  | `variant` | layout |
  |-----------|--------|
  | `small` (default) | 64dp, title (title-large) after the leading icon |
  | `center_aligned` | 64dp, title centered between leading and actions |
  | `medium` | Expressive medium flexible: icons on top, headline-medium title below |
  | `large` | Expressive large flexible: icons on top, display-small title below |

  `subtitle` adds a second line under the title (Expressive).

  ## Color and scrolling

  MD3 top app bars are **surface-colored**, not primary: the bar sits on
  `surface` and turns `surface-container` once content scrolls under it.
  That color change is CSS: a scroll-driven animation
  (`animation-timeline: scroll()`) on the nearest scroll container, in
  browsers that support it. With the PhoenixPaper JS hook and an `id`, the
  bar instead gets `data-pp-scrolled` from a scroll listener, which also
  covers Firefox. `scrolled` forces the scrolled color from the server.

  `color="transparent"` drops the background entirely (a bar over a hero
  image). 0.3's `primary`/`secondary` colors are gone; a colored bar is
  `class="!bg-pp-primary-container"`, but MD3 puts color in the
  `PhoenixPaper.Toolbar` instead.

  Icon buttons inside need no `color`: the bar's text color is
  `on-surface`, and `pp_icon_button`'s standard variant is
  `on-surface-variant`, MD3's own pairing.

  ## Layout

  The row layout stays on under `paperize={false}` — there's no inner
  `class` to rebuild it with (see AGENTS.md).

  ## Stacking

  `sticky`/`fixed`/`absolute` positions are `z-20`; the navigation rail's
  modal panel sits above at `z-40`. See AGENTS.md, "stacking order".
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:variant, :string, default: "small", values: ~w(small center_aligned medium large))
  attr(:subtitle, :string, default: nil, doc: "a second line under the title (Expressive)")
  attr(:color, :string, default: "surface", values: ~w(surface transparent))
  attr(:scrolled, :boolean, default: false, doc: "force the scrolled-under color")

  attr(:position, :string,
    default: "static",
    values: ~w(static relative sticky fixed absolute)
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:leading, doc: "the navigation icon (menu/back)")
  slot(:actions, doc: "trailing icon buttons")
  slot(:inner_block, required: true, doc: "the title")

  @doc "Renders a top app bar. See the module doc."
  def pp_top_app_bar(assigns) do
    ~H"""
    <header
      data-pp-component="top-app-bar"
      data-pp-variant={@variant}
      data-pp-scrolled={@scrolled}
      phx-hook={Helpers.hook(@rest[:id])}
      class={Helpers.classes(@paperize, paper_classes(@color, @position), @class)}
      {@rest}
    >
      <div
        :if={@variant in ~w(small center_aligned)}
        class={[row_classes(@variant), "px-1"]}
      >
        <div class="flex min-w-0 items-center justify-start">{render_slot(@leading)}</div>
        <div class={title_wrapper_classes(@variant)}>
          <div class={Helpers.classes(@paperize, "truncate pp-title-large", nil)}>
            {render_slot(@inner_block)}
          </div>
          <div
            :if={@subtitle}
            class={Helpers.classes(@paperize, "truncate pp-label-medium text-pp-on-surface-variant", nil)}
          >
            {@subtitle}
          </div>
        </div>
        <div class="flex items-center justify-end gap-0.5">{render_slot(@actions)}</div>
      </div>

      <div
        :if={@variant in ~w(medium large)}
        class={["flex flex-col", "px-1"]}
      >
        <div class="flex h-16 items-center gap-1">
          <div class="flex items-center">{render_slot(@leading)}</div>
          <div class="flex-1" />
          <div class="flex items-center gap-0.5">{render_slot(@actions)}</div>
        </div>
        <div class={flexible_title_classes(@variant)}>
          <div class={Helpers.classes(@paperize, flexible_title_type(@variant), nil)}>
            {render_slot(@inner_block)}
          </div>
          <div
            :if={@subtitle}
            class={Helpers.classes(@paperize, "pp-title-medium text-pp-on-surface-variant", nil)}
          >
            {@subtitle}
          </div>
        </div>
      </div>
    </header>
    """
  end

  defp paper_classes("transparent", position),
    do: ["text-pp-on-surface", position_classes(position)]

  defp paper_classes("surface", position) do
    [
      "bg-pp-surface text-pp-on-surface pp-top-app-bar-scroll pp-motion-effects-default data-pp-scrolled:bg-pp-surface-container",
      position_classes(position)
    ]
  end

  defp position_classes("static"), do: "static"
  defp position_classes("relative"), do: "relative"
  defp position_classes("sticky"), do: "sticky top-0 z-20"
  defp position_classes("fixed"), do: "fixed inset-x-0 top-0 z-20"
  defp position_classes("absolute"), do: "absolute inset-x-0 top-0 z-20"

  # Structural, unconditional (see the moduledoc's Layout section).
  defp row_classes("small"), do: "grid h-16 grid-cols-[auto_1fr_auto] items-center gap-1"
  defp row_classes("center_aligned"), do: "grid h-16 grid-cols-[1fr_auto_1fr] items-center gap-1"

  defp title_wrapper_classes("small"), do: "flex min-w-0 flex-col px-3"

  defp title_wrapper_classes("center_aligned"),
    do: "flex min-w-0 flex-col items-center px-3 text-center"

  defp flexible_title_classes("medium"), do: "flex flex-col gap-1 px-3 pb-6"
  defp flexible_title_classes("large"), do: "flex flex-col gap-1 px-3 pb-7 pt-4"

  defp flexible_title_type("medium"), do: "pp-headline-medium"
  defp flexible_title_type("large"), do: "pp-display-small"
end
