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

  `PhoenixPaper.Autocomplete` and `PhoenixPaper.TransferList` need
  interactive state, so they're `Phoenix.LiveComponent`s instead of function
  components — use them directly with `<.live_component module={...} />`,
  they aren't imported here.
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixPaper.Accordion, only: [pp_accordion: 1]
      import PhoenixPaper.AccordionActions, only: [pp_accordion_actions: 1]
      import PhoenixPaper.AccordionDetails, only: [pp_accordion_details: 1]
      import PhoenixPaper.AccordionSummary, only: [pp_accordion_summary: 1]
      import PhoenixPaper.Alert, only: [pp_alert: 1]
      import PhoenixPaper.AppBar, only: [pp_app_bar: 1]
      import PhoenixPaper.Backdrop, only: [pp_backdrop: 1]
      import PhoenixPaper.Badge, only: [pp_badge: 1]
      import PhoenixPaper.Box, only: [pp_box: 1]
      import PhoenixPaper.Breadcrumbs, only: [pp_breadcrumbs: 1]
      import PhoenixPaper.Button, only: [pp_button: 1]
      import PhoenixPaper.ButtonGroup, only: [pp_button_group: 1]
      import PhoenixPaper.Card, only: [pp_card: 1]
      import PhoenixPaper.Checkbox, only: [pp_checkbox: 1]
      import PhoenixPaper.Chip, only: [pp_chip: 1]
      import PhoenixPaper.Container, only: [pp_container: 1]
      import PhoenixPaper.Dialog, only: [pp_dialog: 1]
      import PhoenixPaper.Divider, only: [pp_divider: 1]
      import PhoenixPaper.Drawer, only: [pp_drawer: 1, pp_drawer_toggle: 1]
      import PhoenixPaper.Fab, only: [pp_fab: 1]
      import PhoenixPaper.Grid, only: [pp_grid: 1]
      import PhoenixPaper.GridItem, only: [pp_grid_item: 1]
      import PhoenixPaper.Icon, only: [pp_icon: 1]
      import PhoenixPaper.ImageList, only: [pp_image_list: 1]
      import PhoenixPaper.ImageListItem, only: [pp_image_list_item: 1]
      import PhoenixPaper.Input, only: [pp_input: 1]
      import PhoenixPaper.List, only: [pp_list: 1]
      import PhoenixPaper.ListItem, only: [pp_list_item: 1]
      import PhoenixPaper.ListSubheader, only: [pp_list_subheader: 1]
      import PhoenixPaper.NumberField, only: [pp_number_field: 1]
      import PhoenixPaper.Paper, only: [pp_paper: 1]
      import PhoenixPaper.Progress, only: [pp_progress: 1]
      import PhoenixPaper.RadioGroup, only: [pp_radio_group: 1]
      import PhoenixPaper.Rating, only: [pp_rating: 1]
      import PhoenixPaper.Select, only: [pp_select: 1]
      import PhoenixPaper.Skeleton, only: [pp_skeleton: 1]
      import PhoenixPaper.Slider, only: [pp_slider: 1]
      import PhoenixPaper.Snackbar, only: [pp_snackbar: 1]
      import PhoenixPaper.Stack, only: [pp_stack: 1]
      import PhoenixPaper.Switch, only: [pp_switch: 1]
      import PhoenixPaper.Tab, only: [pp_tab: 1]
      import PhoenixPaper.TabPanel, only: [pp_tab_panel: 1]
      import PhoenixPaper.Tabs, only: [pp_tabs: 1]
      import PhoenixPaper.Table, only: [pp_table: 1]
      import PhoenixPaper.TableBody, only: [pp_table_body: 1]
      import PhoenixPaper.TableCell, only: [pp_table_cell: 1]
      import PhoenixPaper.TableContainer, only: [pp_table_container: 1]
      import PhoenixPaper.TableFooter, only: [pp_table_footer: 1]
      import PhoenixPaper.TableHead, only: [pp_table_head: 1]
      import PhoenixPaper.TableRow, only: [pp_table_row: 1]
      import PhoenixPaper.ThemeToggle, only: [pp_theme_toggle: 1]
      import PhoenixPaper.ToggleButton, only: [pp_toggle_button: 1]
      import PhoenixPaper.Tooltip, only: [pp_tooltip: 1]
      import PhoenixPaper.Typography, only: [pp_typography: 1]
    end
  end
end
