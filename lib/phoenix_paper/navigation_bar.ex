defmodule PhoenixPaper.NavigationBar do
  @moduledoc """
  An M3 Expressive (flexible) navigation bar (`pp_navigation_bar/1`) —
  the bottom bar for switching between 3–5 top-level destinations on
  small screens.

      <.pp_navigation_bar position="fixed" class="md:hidden">
        <.pp_navigation_bar_item icon="hero-home" active_icon="hero-home-solid" label="Home" navigate={~p"/"} active />
        <.pp_navigation_bar_item icon="hero-magnifying-glass" label="Search" navigate={~p"/search"} />
        <.pp_navigation_bar_item icon="hero-bell" label="Alerts" navigate={~p"/alerts"} badge={3} />
      </.pp_navigation_bar>

  64dp tall on `surface-container`. Each item is an icon in a
  `secondary-container` active indicator with its label — under the icon
  (`item_layout="vertical"`), or beside it inside the indicator
  (`"horizontal"`, Expressive's layout for medium windows).
  `"responsive"` (default) is vertical on small screens and horizontal
  from `sm` up.

  `position="fixed"` pins it to the bottom of the viewport (`z-20`, and
  `pb-[env(safe-area-inset-bottom)]` for phones with a home indicator);
  leave room for it with bottom padding on your content. Pair it with a
  `PhoenixPaper.NavigationRail` on larger screens: `class="md:hidden"`
  here, the rail's `responsive` variant there.

  Items take the same attrs as `pp_navigation_rail_item/1`: `icon`,
  `active_icon`, `label`, `active` (sets `aria-current`), `badge` and
  link attrs.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Icon, Ripple}

  attr(:item_layout, :string, default: "responsive", values: ~w(responsive vertical horizontal))
  attr(:position, :string, default: "static", values: ~w(static fixed sticky))
  attr(:label, :string, default: "Main navigation", doc: "the nav landmark's aria-label")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true, doc: "the pp_navigation_bar_item/1 destinations")

  @doc "Renders a navigation bar. See the module doc."
  def pp_navigation_bar(assigns) do
    ~H"""
    <nav
      aria-label={@label}
      data-pp-component="navigation-bar"
      data-pp-layout={@item_layout}
      class={Helpers.classes(@paperize, paper_classes(@position), @class)}
      {@rest}
    >
      <div class="mx-auto flex h-16 w-full max-w-screen-md items-stretch justify-around">
        {render_slot(@inner_block)}
      </div>
    </nav>
    """
  end

  attr(:icon, :string, required: true)
  attr(:active_icon, :string, default: nil)
  attr(:label, :string, required: true)
  attr(:active, :boolean, default: false)
  attr(:badge, :any, default: nil, doc: "true for a dot, or a count")
  attr(:href, :any, default: nil)
  attr(:navigate, :any, default: nil)
  attr(:patch, :any, default: nil)
  attr(:ripple, :boolean, default: true)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(method download target rel replace))

  @doc "A destination in a `pp_navigation_bar/1`. See the module doc."
  def pp_navigation_bar_item(assigns) do
    assigns = assign(assigns, :ripple?, assigns.ripple and assigns.paperize)

    ~H"""
    <.link
      href={@href}
      navigate={@navigate}
      patch={@patch}
      aria-current={@active && "page"}
      data-pp-component="navigation-bar-item"
      class={Helpers.classes(@paperize, item_classes(), @class)}
      {@rest}
    >
      <span
        onclick={Ripple.on_click(@ripple?)}
        class={Helpers.classes(@paperize, indicator_classes(@active), nil)}
      >
        <span class="relative inline-flex">
          <Icon.pp_icon name={(@active && @active_icon) || @icon} />
          <span
            :if={@badge == true}
            class="absolute -right-0.5 -top-0.5 size-1.5 rounded-full bg-pp-error"
          />
          <span
            :if={@badge not in [nil, false, true]}
            class="absolute -right-2 -top-1.5 inline-flex h-4 min-w-4 items-center justify-center rounded-full bg-pp-error px-1 pp-label-small text-pp-on-error"
          >
            {@badge}
          </span>
        </span>
        <span class={horizontal_label_classes()}>{@label}</span>
      </span>
      <span class={Helpers.classes(@paperize, vertical_label_classes(@active), nil)}>
        {@label}
      </span>
    </.link>
    """
  end

  defp paper_classes("static"), do: "group/bar bg-pp-surface-container text-pp-on-surface"

  defp paper_classes("fixed"),
    do:
      "group/bar fixed inset-x-0 bottom-0 z-20 bg-pp-surface-container pb-[env(safe-area-inset-bottom)] text-pp-on-surface"

  defp paper_classes("sticky"),
    do:
      "group/bar sticky bottom-0 z-20 bg-pp-surface-container pb-[env(safe-area-inset-bottom)] text-pp-on-surface"

  # Horizontal layout: forced by item_layout="horizontal", or from `sm` up
  # for "responsive".
  defp item_classes do
    [
      "flex min-w-0 flex-1 cursor-pointer select-none flex-col items-center justify-center gap-1 pp-focus-ring",
      "group-data-[pp-layout=horizontal]/bar:flex-row",
      "sm:group-data-[pp-layout=responsive]/bar:flex-row"
    ]
  end

  defp indicator_classes(active) do
    [
      "relative inline-flex h-8 w-14 items-center justify-center gap-1 overflow-hidden rounded-pp-full pp-state-layer pp-motion-spatial-default",
      "group-data-[pp-layout=horizontal]/bar:h-10 group-data-[pp-layout=horizontal]/bar:w-auto group-data-[pp-layout=horizontal]/bar:px-4",
      "sm:group-data-[pp-layout=responsive]/bar:h-10 sm:group-data-[pp-layout=responsive]/bar:w-auto sm:group-data-[pp-layout=responsive]/bar:px-4",
      if(active,
        do: "bg-pp-secondary-container text-pp-on-secondary-container",
        else: "text-pp-on-surface-variant"
      )
    ]
  end

  defp horizontal_label_classes do
    [
      "hidden truncate pp-label-medium",
      "group-data-[pp-layout=horizontal]/bar:inline",
      "sm:group-data-[pp-layout=responsive]/bar:inline"
    ]
  end

  defp vertical_label_classes(active) do
    [
      "max-w-full truncate px-1 pp-label-medium",
      if(active, do: "text-pp-secondary", else: "text-pp-on-surface-variant"),
      "group-data-[pp-layout=horizontal]/bar:hidden",
      "sm:group-data-[pp-layout=responsive]/bar:hidden"
    ]
  end
end
