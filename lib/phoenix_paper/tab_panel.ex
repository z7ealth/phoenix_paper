defmodule PhoenixPaper.TabPanel do
  @moduledoc """
  The content for one `PhoenixPaper.Tab` (`pp_tab_panel/1`) — see
  `PhoenixPaper.Tabs` for composition.

  Pass the group's `id` and the matching tab's `value`; mark the panel of
  the `default_selected` tab `default_selected` too. Only that panel is
  visible on first paint; `PhoenixPaper.Tabs.select/2` shows/hides them
  afterwards. Hidden panels use the `hidden` *class*, unconditionally (even
  under `paperize={false}`), not the `hidden` attribute: Tailwind's
  preflight makes `[hidden]` `display: none !important`, which
  `JS.show`'s inline `display` can't beat. The panel itself has no padding beyond `py-4` — MD3 doesn't
  style tab content.
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
      tabindex="0"
      aria-labelledby={tab_id(@id, @value)}
      data-pp-component="tab-panel"
      data-pp-tab-panel-group={@id}
      class={[
        !@default_selected && "hidden",
        Helpers.classes(@paperize, "py-4 focus-visible:outline-none", @class)
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
