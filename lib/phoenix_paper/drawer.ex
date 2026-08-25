defmodule PhoenixPaper.Drawer do
  @moduledoc """
  A Material Design navigation drawer (`pp_drawer/1`) — a vertical panel,
  persistent on large screens (`lg:` and up, pinned via `sticky` so it stays
  in place as the page scrolls, with its own internal scroll if its content
  is taller than the viewport) and toggled by a mobile drawer below that
  breakpoint. Compose it with `PhoenixPaper.List` / `PhoenixPaper.ListItem`
  for its contents.

  The mobile toggle is pure CSS, no JS/LiveView required: `pp_drawer/1`
  renders a visually hidden checkbox, and both the drawer panel and its
  backdrop react to it via `peer-checked:`. `pp_drawer_toggle/1` is just a
  `<label for={...}>` pointing at that same checkbox — clicking any label
  wired to a checkbox's id checks it natively, so the toggle button and the
  drawer don't need to be DOM siblings, unlike most of this library's other
  `peer-*`/`has-[:checked]:` tricks (see AGENTS.md).

      <.pp_app_bar>
        <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
        My App
      </.pp_app_bar>

      <.pp_drawer id="app-drawer" color="primary">
        <:header>My App</:header>
        <.pp_list>
          <.pp_list_item navigate={~p"/"} active={@current_path == "/"}>
            <:leading><.pp_icon name="hero-home" /></:leading>
            Home
          </.pp_list_item>
          <.pp_list_item navigate={~p"/settings"} active={@current_path == "/settings"}>
            <:leading><.pp_icon name="hero-cog-6-tooth" /></:leading>
            Settings
          </.pp_list_item>
        </.pp_list>
      </.pp_drawer>

  `pp_drawer_toggle/1` lives here rather than its own module because it only
  makes sense paired with a `pp_drawer/1` (see AGENTS.md, "Component
  conventions").

  ## `color`

  Defaults to `"surface"` (the original plain white/dark-surface look,
  unchanged from before this attr existed). `"primary"`/`"secondary"`/
  `"tertiary"` paint the whole panel that brand color — including its
  nested `PhoenixPaper.List`/`PhoenixPaper.ListItem`/
  `PhoenixPaper.ListSubheader`/`PhoenixPaper.Divider` content, which are
  normally styled for a neutral surface background. There's no prop on
  those components for "the color of my container" (same "no cascading"
  limitation `ButtonGroup`/`Tabs`/`AppBar` already document), so instead
  `pp_drawer/1` reaches into them with a handful of `[&_[data-pp-component=...]]`
  compound selectors — the same technique (and the same `data-pp-component`
  attribute) `Tabs`'s `variant="full_width"` already uses to reach its
  child `Tab`s, just applied to more targets here. This is a real,
  intentional exception to "components don't reach into each other" for
  the one specific case where getting it wrong isn't a style mismatch but
  actual illegibility: `ListItem`'s active-item highlight
  (`bg-pp-primary/10`) mixed with a `color="primary"` drawer background is
  the *exact same color layered on itself*, which is mathematically
  invisible, not just low-contrast — found and fixed by actually
  screenshotting a colored drawer with an active nav item, not by
  reasoning about it in the abstract. `ListItem`'s `active` attr sets
  `aria-current="page"` specifically so this selector has something stable
  to target (see its moduledoc) — without that attribute there'd be no way
  to tell an active item from an inactive one from CSS alone.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers}

  attr(:id, :string,
    required: true,
    doc: ~s(builds the mobile toggle checkbox's id as "\#{id}-toggle")
  )

  attr(:color, :string,
    default: "surface",
    values: ~w(primary secondary tertiary surface),
    doc:
      "surface (default) is the original plain look; the others also restyle nested List/ListItem content for contrast"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:header)
  slot(:inner_block, required: true)

  @doc "Renders a navigation drawer. See the module doc."
  def pp_drawer(assigns) do
    ~H"""
    <input type="checkbox" id={toggle_id(@id)} class="peer sr-only" />
    <label
      for={toggle_id(@id)}
      aria-hidden="true"
      class="fixed inset-0 z-30 hidden bg-black/40 peer-checked:block lg:hidden"
    />
    <aside
      id={@id}
      data-pp-component="drawer"
      class={Helpers.classes(@paperize, paper_classes(@color), @class)}
      {@rest}
    >
      <div :if={@header != []} class="flex h-16 items-center px-4 text-lg font-medium">
        {render_slot(@header)}
      </div>
      {render_slot(@inner_block)}
    </aside>
    """
  end

  attr(:for, :string, required: true, doc: "the target pp_drawer/1's id")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  @doc "A hamburger button that toggles the `pp_drawer/1` with the given `for` id."
  def pp_drawer_toggle(assigns) do
    ~H"""
    <label
      for={toggle_id(@for)}
      data-pp-component="drawer-toggle"
      class={Helpers.classes(@paperize, "inline-flex size-10 cursor-pointer flex-col items-center justify-center gap-1 rounded-full hover:bg-pp-on-surface/10 lg:hidden", @class)}
    >
      <span class="block h-0.5 w-5 bg-current" />
      <span class="block h-0.5 w-5 bg-current" />
      <span class="block h-0.5 w-5 bg-current" />
    </label>
    """
  end

  defp toggle_id(id), do: "#{id}-toggle"

  defp paper_classes(color) do
    [
      "fixed inset-y-0 left-0 z-40 w-64 -translate-x-full overflow-y-auto transition-transform peer-checked:translate-x-0 lg:sticky lg:top-0 lg:z-auto lg:h-screen lg:w-64 lg:shrink-0 lg:translate-x-0",
      color_classes(color),
      Elevation.class(2)
    ]
  end

  defp color_classes("surface"), do: "bg-pp-surface text-pp-on-surface"

  defp color_classes("primary") do
    [
      "bg-pp-primary text-pp-on-primary",
      "[&_[data-pp-component=list-subheader]]:text-pp-on-primary/70",
      "[&_[data-pp-component=divider]]:border-pp-on-primary/20",
      "[&_[data-pp-component=list-item]]:text-pp-on-primary",
      "[&_[data-pp-component=list-item]:not([aria-current=page]):hover]:bg-pp-on-primary/10",
      "[&_[data-pp-component=list-item][aria-current=page]]:bg-pp-on-primary/15",
      "[&_[data-pp-component=list-item][aria-current=page]]:text-pp-on-primary"
    ]
  end

  defp color_classes("secondary") do
    [
      "bg-pp-secondary text-pp-on-secondary",
      "[&_[data-pp-component=list-subheader]]:text-pp-on-secondary/70",
      "[&_[data-pp-component=divider]]:border-pp-on-secondary/20",
      "[&_[data-pp-component=list-item]]:text-pp-on-secondary",
      "[&_[data-pp-component=list-item]:not([aria-current=page]):hover]:bg-pp-on-secondary/10",
      "[&_[data-pp-component=list-item][aria-current=page]]:bg-pp-on-secondary/15",
      "[&_[data-pp-component=list-item][aria-current=page]]:text-pp-on-secondary"
    ]
  end

  defp color_classes("tertiary") do
    [
      "bg-pp-tertiary text-pp-on-tertiary",
      "[&_[data-pp-component=list-subheader]]:text-pp-on-tertiary/70",
      "[&_[data-pp-component=divider]]:border-pp-on-tertiary/20",
      "[&_[data-pp-component=list-item]]:text-pp-on-tertiary",
      "[&_[data-pp-component=list-item]:not([aria-current=page]):hover]:bg-pp-on-tertiary/10",
      "[&_[data-pp-component=list-item][aria-current=page]]:bg-pp-on-tertiary/15",
      "[&_[data-pp-component=list-item][aria-current=page]]:text-pp-on-tertiary"
    ]
  end
end
