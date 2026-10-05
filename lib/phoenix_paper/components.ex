defmodule PhoenixPaper.Components do
  @moduledoc """
  `use PhoenixPaper.Components` imports every PhoenixPaper component
  (`pp_button/1`, `pp_card/1`, `pp_icon/1`, `pp_checkbox/1`, ...) at once.

  Add it next to your app's own `core_components` import, typically in the
  `html_helpers` block of `lib/my_app_web.ex`:

      defp html_helpers do
        quote do
          use PhoenixPaper.Components
          # ... existing imports ...
        end
      end

  Every function is prefixed `pp_` so it never collides with Phoenix's
  generated `core_components.ex` (`button/1`, `input/1`, `icon/1`, ...) or
  with daisyUI class names.

  `PhoenixPaper.DatePicker` and `PhoenixPaper.TimePicker` need
  interactive state, so they're `Phoenix.LiveComponent`s instead of
  function components — use them directly with
  `<.live_component module={...} />`, they aren't imported here.
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixPaper.Badge, only: [pp_badge: 1]
      import PhoenixPaper.BottomSheet, only: [pp_bottom_sheet: 1]
      import PhoenixPaper.Button, only: [pp_button: 1]
      import PhoenixPaper.ButtonGroup, only: [pp_button_group: 1]
      import PhoenixPaper.Card, only: [pp_card: 1]
      import PhoenixPaper.Carousel, only: [pp_carousel: 1]
      import PhoenixPaper.Checkbox, only: [pp_checkbox: 1]
      import PhoenixPaper.Chip, only: [pp_chip: 1]
      import PhoenixPaper.Dialog, only: [pp_dialog: 1]
      import PhoenixPaper.Divider, only: [pp_divider: 1]
      import PhoenixPaper.Fab, only: [pp_fab: 1]
      import PhoenixPaper.FabMenu, only: [pp_fab_menu: 1]
      import PhoenixPaper.Flash, only: [pp_flash_group: 1, pp_flash: 1]
      import PhoenixPaper.Icon, only: [pp_icon: 1]
      import PhoenixPaper.IconButton, only: [pp_icon_button: 1]
      import PhoenixPaper.List, only: [pp_list: 1]
      import PhoenixPaper.ListItem, only: [pp_list_item: 1]
      import PhoenixPaper.LoadingIndicator, only: [pp_loading_indicator: 1]
      import PhoenixPaper.Menu, only: [pp_menu: 1, pp_menu_item: 1, pp_submenu: 1]

      import PhoenixPaper.NavigationBar,
        only: [pp_navigation_bar: 1, pp_navigation_bar_item: 1]

      import PhoenixPaper.NavigationRail,
        only: [pp_navigation_rail: 1, pp_navigation_rail_item: 1, pp_navigation_rail_toggle: 1]

      import PhoenixPaper.Progress, only: [pp_progress: 1]
      import PhoenixPaper.RadioGroup, only: [pp_radio_group: 1]
      import PhoenixPaper.SearchBar, only: [pp_search_bar: 1]
      import PhoenixPaper.Select, only: [pp_select: 1]
      import PhoenixPaper.SideSheet, only: [pp_side_sheet: 1]
      import PhoenixPaper.Slider, only: [pp_slider: 1]
      import PhoenixPaper.Snackbar, only: [pp_snackbar: 1]
      import PhoenixPaper.SplitButton, only: [pp_split_button: 1]
      import PhoenixPaper.Switch, only: [pp_switch: 1]
      import PhoenixPaper.Tab, only: [pp_tab: 1]
      import PhoenixPaper.TabPanel, only: [pp_tab_panel: 1]
      import PhoenixPaper.Tabs, only: [pp_tabs: 1]
      import PhoenixPaper.TextField, only: [pp_text_field: 1]
      import PhoenixPaper.ThemeToggle, only: [pp_theme_toggle: 1]
      import PhoenixPaper.Toolbar, only: [pp_toolbar: 1]
      import PhoenixPaper.Tooltip, only: [pp_tooltip: 1]
      import PhoenixPaper.TopAppBar, only: [pp_top_app_bar: 1]
      import PhoenixPaper.Typography, only: [pp_typography: 1]
    end
  end
end
