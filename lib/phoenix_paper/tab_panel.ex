defmodule PhoenixPaper.TabPanel do
  @moduledoc """
  The content shown for one `PhoenixPaper.Tab` (`pp_tab_panel/1`) — hidden
  until its matching tab is selected. See `PhoenixPaper.Tabs`'s moduledoc
  for the full composition example and why switching needs real
  per-element JS targeting rather than a CSS-only trick.

  `id`/`value` must match the corresponding `pp_tab/1` exactly — that's how
  `PhoenixPaper.Tabs.select/2,3` finds this panel to show/hide it.

  Unlike MUI's `TabPanel` (which unmounts inactive panels from the React
  tree by default), every panel here always stays in the DOM, just
  `display: none` — the same trade-off `PhoenixPaper.Dialog`/
  `PhoenixPaper.Drawer` make, and for the same reason: pure CSS/JS
  visibility toggling needs the element to exist in order to toggle it.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  import PhoenixPaper.Tabs, only: [tab_id: 2, panel_id: 2]

  attr(:id, :string, required: true, doc: "the same id passed to the parent pp_tabs/1")
  attr(:value, :string, required: true, doc: "matches the corresponding pp_tab/1's value")
  attr(:default_selected, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders tab panel content. See the module doc."
  def pp_tab_panel(assigns) do
    ~H"""
    <div
      id={panel_id(@id, @value)}
      role="tabpanel"
      aria-labelledby={tab_id(@id, @value)}
      data-pp-component="tab-panel"
      data-pp-tab-panel-group={@id}
      class={Helpers.classes(@paperize, visibility_classes(@default_selected), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp visibility_classes(true), do: "block p-4"
  defp visibility_classes(false), do: "hidden p-4"
end
