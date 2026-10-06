defmodule PhoenixPaper.NavigationRail do
  @moduledoc """
  An M3 Expressive navigation rail (`pp_navigation_rail/1`), collapsed or
  expanded, with a modal mode for small screens. It replaces 0.3's
  `Drawer`: M3 Expressive retires the navigation drawer in favor of the
  expanded rail.

      <.pp_navigation_rail id="app-rail">
        <:fab icon="hero-pencil" label="Compose" navigate={~p"/compose"} />
        <.pp_navigation_rail_item icon="hero-inbox" active_icon="hero-inbox-solid" label="Inbox" navigate={~p"/"} active badge={4} />
        <.pp_navigation_rail_item icon="hero-paper-airplane" label="Sent" navigate={~p"/sent"} />
        <.pp_navigation_rail_item icon="hero-trash" label="Trash" navigate={~p"/trash"} />
      </.pp_navigation_rail>

  ## Variants

  | `variant` | behavior |
  |-----------|----------|
  | `responsive` (default) | below `md`: hidden, opens as a **modal** expanded rail over a scrim; from `md`: a collapsed rail that the menu button expands |
  | `collapsed` | always the 96dp collapsed rail (icons over labels) |
  | `expanded` | always expanded (icons beside labels, 280dp) |

  The menu button is `pp_navigation_rail_toggle/1`. The rail renders one
  at its top for `responsive` rails (`menu_button={false}` drops it);
  put another in your `PhoenixPaper.TopAppBar`'s `:leading` with
  `modal_only` so small screens can open the modal rail.

  A responsive rail has two independent states, each with its own
  starting value:

  - `default_expanded` — whether the docked rail starts **expanded** on
    `md` and up (280dp, labels beside icons) instead of collapsed.
  - `default_open` — whether the **modal** rail starts open on small
    screens. Leave it `false` (the default) unless the page is the menu:
    an open modal covers the content until it's dismissed.

  So `default_expanded` gives "expanded on desktop, closed on phones".
  Until 0.5.2 one checkbox held both states, so `default_expanded` also
  opened the modal on every small-screen page load.

  ## Items

  `pp_navigation_rail_item/1` takes `icon`, `label`, an optional
  `active_icon` (MD3's filled glyph for the selected destination), `active`,
  a `badge` (`true` for a small dot, or a count) and link attrs
  (`href`/`navigate`/`patch`). Collapsed, the active indicator is a 56×32
  `secondary-container` pill around the icon with the label underneath;
  expanded, the pill grows around icon and label. The width and the
  indicator animate on the Expressive spatial spring. For a labeled group
  of items, put a `pp_typography variant="title-small"` heading between
  them with `class="pp-rail-collapsed:hidden"` so it only shows when the
  rail is expanded.

  `active` sets `aria-current="page"`. Which item is active is yours to
  compute, as with `PhoenixPaper.ListItem`.

  ## FAB

  The `:fab` slot (`icon`, `label`, link attrs or `on_click`) renders the
  rail's FAB: a 56dp FAB when collapsed that morphs into an extended FAB
  when expanded.

  ## How it works

  CSS only: two hidden checkboxes — `data-pp-rail-toggle` (the modal,
  small screens) and `data-pp-rail-expand` (expanded, `md` and up) — a
  scrim `<label>` for the first, and the rail as their later sibling. The
  rail's classes react to them as named peers (`peer-checked/modal:`,
  `peer-checked/expand:`), since a plain `peer-checked:` would fire for
  either. Every layout change is a `pp-rail-expanded:` /
  `pp-rail-collapsed:` variant (defined in `phoenix_paper.css`) instead of
  three selectors per class. Render them as siblings — the component
  does — and keep the rail outside any element that would break
  `position: sticky` (an `overflow: hidden` ancestor).

  The menu button is two `<label>`s, one per checkbox, each shown only at
  its breakpoint (`md:hidden` for the modal, `max-md:hidden` for
  expanding), so the same button opens the modal on a phone and expands
  the rail on a desktop.

  Stacking: modal panel `z-40`, scrim `z-30`, the docked rail `md:z-30`;
  a sticky `TopAppBar` is `z-20`.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers, Icon, Ripple}

  attr(:id, :string, required: true)
  attr(:variant, :string, default: "responsive", values: ~w(responsive collapsed expanded))

  attr(:menu_button, :boolean,
    default: true,
    doc: "render the menu (expand/collapse) button at the top of a responsive rail"
  )

  attr(:default_expanded, :boolean,
    default: false,
    doc: "responsive rails only: start expanded on md and up"
  )

  attr(:default_open, :boolean,
    default: false,
    doc: "responsive rails only: start with the small-screen modal open"
  )

  attr(:label, :string, default: "Main navigation", doc: "the nav landmark's aria-label")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :fab, doc: "the rail's FAB, extended when the rail is" do
    attr(:icon, :string, required: true)
    attr(:label, :string, required: true)
    attr(:href, :any)
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:on_click, :any)
  end

  slot(:header, doc: "extra content at the top (a logo), under the menu button")
  slot(:footer, doc: "content pinned to the bottom (settings, account)")
  slot(:inner_block, required: true, doc: "the pp_navigation_rail_item/1 destinations")

  @doc "Renders a navigation rail. See the module doc."
  def pp_navigation_rail(assigns) do
    ~H"""
    <input
      :if={@variant == "responsive"}
      type="checkbox"
      id={toggle_id(@id)}
      checked={@default_open}
      data-pp-rail-toggle
      aria-label={@label}
      class="peer/modal sr-only"
    />
    <input
      :if={@variant == "responsive"}
      type="checkbox"
      id={expand_id(@id)}
      checked={@default_expanded}
      data-pp-rail-expand
      aria-label={@label}
      class="peer/expand sr-only"
    />
    <label
      :if={@variant == "responsive"}
      for={toggle_id(@id)}
      aria-hidden="true"
      class="fixed inset-0 z-30 hidden bg-pp-scrim/32 max-md:peer-checked/modal:block"
    />
    <nav
      id={@id}
      aria-label={@label}
      data-pp-component="navigation-rail"
      data-pp-rail={@variant}
      class={Helpers.classes(@paperize, paper_classes(@variant), @class)}
      {@rest}
    >
      <div class="flex flex-col items-center gap-1 pp-rail-expanded:items-start pp-rail-expanded:px-3">
        <.pp_navigation_rail_toggle
          :if={@variant == "responsive" and @menu_button}
          for={@id}
          paperize={@paperize}
        />
        {render_slot(@header)}
        <.rail_fab :for={fab <- @fab} fab={fab} paperize={@paperize} />
      </div>
      <div class="flex flex-1 flex-col items-stretch gap-1 overflow-y-auto pp-rail-expanded:px-3">
        {render_slot(@inner_block)}
      </div>
      <div :if={@footer != []} class="flex flex-col items-center gap-1 pp-rail-expanded:items-stretch pp-rail-expanded:px-3">
        {render_slot(@footer)}
      </div>
    </nav>
    """
  end

  attr(:for, :string, required: true, doc: "the pp_navigation_rail/1's id")
  attr(:label, :string, default: "Toggle navigation")

  attr(:modal_only, :boolean,
    default: false,
    doc: "hide from md up — for a second toggle in the top app bar"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  @doc """
  The menu button of a responsive `pp_navigation_rail/1`: it opens/closes
  the modal rail on small screens and expands/collapses the docked rail
  from `md` up. Each state has its own checkbox, so this is two `<label>`s
  styled as a standard icon button, each shown only at its breakpoint
  (`modal_only` keeps just the small-screen one). Labels work from
  anywhere on the page.
  """
  def pp_navigation_rail_toggle(assigns) do
    ~H"""
    <label
      for={toggle_id(@for)}
      aria-label={@label}
      title={@label}
      data-pp-component="navigation-rail-toggle"
      data-pp-rail-target="modal"
      class={Helpers.classes(@paperize, [toggle_classes(), "md:hidden"], @class)}
    >
      <Icon.pp_icon name="hero-bars-3" />
    </label>
    <label
      :if={!@modal_only}
      for={expand_id(@for)}
      aria-label={@label}
      title={@label}
      data-pp-component="navigation-rail-toggle"
      data-pp-rail-target="expand"
      class={Helpers.classes(@paperize, [toggle_classes(), "max-md:hidden"], @class)}
    >
      <Icon.pp_icon name="hero-bars-3" />
    </label>
    """
  end

  defp toggle_classes do
    "relative inline-flex size-12 shrink-0 cursor-pointer items-center justify-center rounded-full text-pp-on-surface-variant pp-state-layer"
  end

  attr(:icon, :string, required: true, doc: "a hero-* icon name")
  attr(:active_icon, :string, default: nil, doc: "icon shown while active (MD3's filled glyph)")
  attr(:label, :string, required: true)
  attr(:active, :boolean, default: false, doc: "the current destination; sets aria-current")
  attr(:badge, :any, default: nil, doc: "true for a dot, or a count")
  attr(:href, :any, default: nil)
  attr(:navigate, :any, default: nil)
  attr(:patch, :any, default: nil)
  attr(:ripple, :boolean, default: true)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(method download target rel replace))

  @doc "A destination in a `pp_navigation_rail/1`. See the module doc."
  def pp_navigation_rail_item(assigns) do
    assigns = assign(assigns, :ripple?, assigns.ripple and assigns.paperize)

    ~H"""
    <.link
      href={@href}
      navigate={@navigate}
      patch={@patch}
      aria-current={@active && "page"}
      data-pp-component="navigation-rail-item"
      class={Helpers.classes(@paperize, item_classes(), @class)}
      {@rest}
    >
      <span
        onclick={Ripple.on_click(@ripple?)}
        class={Helpers.classes(@paperize, indicator_classes(@active), nil)}
      >
        <span class="relative inline-flex">
          <Icon.pp_icon name={(@active && @active_icon) || @icon} />
          <.rail_badge :if={@badge not in [nil, false]} badge={@badge} />
        </span>
        <span class="hidden truncate pp-label-large pp-rail-expanded:inline">{@label}</span>
      </span>
      <span class={Helpers.classes(@paperize, label_classes(@active), nil)}>{@label}</span>
    </.link>
    """
  end

  attr(:badge, :any, required: true)

  defp rail_badge(%{badge: true} = assigns) do
    ~H"""
    <span class="absolute -right-0.5 -top-0.5 size-1.5 rounded-full bg-pp-error" />
    """
  end

  defp rail_badge(assigns) do
    ~H"""
    <span class="absolute -right-2 -top-1.5 inline-flex h-4 min-w-4 items-center justify-center rounded-full bg-pp-error px-1 pp-label-small text-pp-on-error">
      {@badge}
    </span>
    """
  end

  attr(:fab, :any, required: true)
  attr(:paperize, :boolean, required: true)

  defp rail_fab(assigns) do
    linked? =
      assigns.fab[:href] not in [nil, false] or assigns.fab[:navigate] not in [nil, false] or
        assigns.fab[:patch] not in [nil, false]

    assigns = assign(assigns, :linked?, linked?)

    ~H"""
    <.link
      :if={@linked?}
      href={@fab[:href]}
      navigate={@fab[:navigate]}
      patch={@fab[:patch]}
      aria-label={@fab.label}
      data-pp-component="fab"
      class={Helpers.classes(@paperize, fab_classes(), nil)}
    >
      <Icon.pp_icon name={@fab.icon} class="shrink-0" />
      <span class="hidden whitespace-nowrap pp-title-medium pp-rail-expanded:inline">{@fab.label}</span>
    </.link>
    <button
      :if={!@linked?}
      type="button"
      aria-label={@fab.label}
      phx-click={@fab[:on_click]}
      data-pp-component="fab"
      class={Helpers.classes(@paperize, fab_classes(), nil)}
    >
      <Icon.pp_icon name={@fab.icon} class="shrink-0" />
      <span class="hidden whitespace-nowrap pp-title-medium pp-rail-expanded:inline">{@fab.label}</span>
    </button>
    """
  end

  defp toggle_id(id), do: "#{id}-toggle"
  defp expand_id(id), do: "#{id}-expand"

  defp paper_classes("responsive") do
    [
      "flex flex-col gap-4 overflow-x-hidden py-4 pp-motion-spatial-default",
      # Small screens: a modal expanded rail, off-canvas until checked.
      "max-md:fixed max-md:inset-y-0 max-md:start-0 max-md:z-40 max-md:w-[min(360px,85vw)] max-md:-translate-x-full max-md:peer-checked/modal:translate-x-0 max-md:rounded-e-pp-lg max-md:bg-pp-surface-container-low max-md:text-pp-on-surface",
      Elevation.class(0),
      "max-md:peer-checked/modal:pp-elevation-1",
      # md+: docked; collapsed 96dp, expanded 280dp.
      "md:sticky md:top-0 md:z-30 md:h-dvh md:shrink-0 md:w-24 md:peer-checked/expand:w-[280px] md:bg-pp-surface md:text-pp-on-surface"
    ]
  end

  defp paper_classes("collapsed"),
    do:
      "sticky top-0 flex h-dvh w-24 shrink-0 flex-col gap-4 py-4 bg-pp-surface text-pp-on-surface"

  defp paper_classes("expanded"),
    do:
      "sticky top-0 flex h-dvh w-[280px] shrink-0 flex-col gap-4 py-4 bg-pp-surface text-pp-on-surface"

  defp item_classes do
    [
      "group/item flex w-full cursor-pointer select-none flex-col items-center gap-1 py-1 pp-focus-ring rounded-pp-lg",
      "pp-rail-expanded:flex-row pp-rail-expanded:py-0"
    ]
  end

  defp indicator_classes(active) do
    [
      "relative inline-flex h-8 w-14 items-center justify-center gap-3 overflow-hidden rounded-pp-full pp-state-layer pp-motion-spatial-default",
      "pp-rail-expanded:h-14 pp-rail-expanded:w-auto pp-rail-expanded:max-w-full pp-rail-expanded:justify-start pp-rail-expanded:px-4",
      if(active,
        do: "bg-pp-secondary-container text-pp-on-secondary-container",
        else: "text-pp-on-surface-variant"
      )
    ]
  end

  defp label_classes(true),
    do: "max-w-full truncate px-1 pp-label-medium text-pp-secondary pp-rail-expanded:hidden"

  defp label_classes(false),
    do:
      "max-w-full truncate px-1 pp-label-medium text-pp-on-surface-variant pp-rail-expanded:hidden"

  defp fab_classes do
    [
      "relative mb-2 mt-1 inline-flex h-14 min-w-14 shrink-0 cursor-pointer items-center justify-center gap-3 overflow-hidden rounded-pp-lg bg-pp-primary-container text-pp-on-primary-container pp-state-layer pp-focus-ring pp-motion-spatial-default",
      Elevation.class(3),
      Elevation.hover_class(4),
      "pp-rail-expanded:px-4"
    ]
  end
end
