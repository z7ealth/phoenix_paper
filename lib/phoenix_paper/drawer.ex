defmodule PhoenixPaper.Drawer do
  @moduledoc """
  A Material Design navigation drawer (`pp_drawer/1`) — a vertical panel,
  persistent on large screens (`lg:` and up) and toggled by a mobile drawer
  below that breakpoint. Compose it with `PhoenixPaper.List` /
  `PhoenixPaper.ListItem` for its contents.

  The mobile toggle is pure CSS, no JS/LiveView required: `pp_drawer/1`
  renders a visually hidden checkbox, and both the drawer panel and its
  backdrop react to it via `peer-checked:`. `pp_drawer_toggle/1` is just a
  `<label for={...}>` pointing at that same checkbox — clicking any label
  wired to a checkbox's id checks it natively, so the toggle button and the
  drawer don't need to be DOM siblings, unlike most of this library's other
  `peer-*`/`has-[:checked]:` tricks (see AGENTS.md).

      <.pp_navbar>
        <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
        My App
      </.pp_navbar>

      <.pp_drawer id="app-drawer">
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
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers}

  attr(:id, :string,
    required: true,
    doc: ~s(builds the mobile toggle checkbox's id as "\#{id}-toggle")
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
      class={Helpers.classes(@paperize, paper_classes(), @class)}
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

  defp paper_classes do
    [
      "fixed inset-y-0 left-0 z-40 w-64 -translate-x-full overflow-y-auto bg-pp-surface text-pp-on-surface transition-transform peer-checked:translate-x-0 lg:static lg:z-auto lg:w-64 lg:shrink-0 lg:translate-x-0",
      Elevation.class(2)
    ]
  end
end
