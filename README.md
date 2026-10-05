<p align="center">
  <img src="priv/static/images/logo/phoenixpaper-lockup-card.svg" alt="PhoenixPaper" width="320">
</p>

# PhoenixPaper

[![Hex.pm](https://img.shields.io/hexpm/v/phoenix_paper.svg)](https://hex.pm/packages/phoenix_paper)
[![Hexdocs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/phoenix_paper)
[![License](https://img.shields.io/hexpm/l/phoenix_paper.svg)](https://github.com/z7ealth/phoenix_paper/blob/master/LICENSE)

A [Material Design 3](https://m3.material.io/) component library for
Phoenix — including **M3 Expressive** (springs, shape morphing, the new
button sizes, button groups, FAB menu, loading indicator, toolbars,
navigation rail) — styled with Tailwind CSS. It started in the spirit of
[ember-paper](https://github.com/miguelcobain/ember-paper); since 0.4.0 it
follows the MD3 spec, with MUI-style APIs where MD3 doesn't specify a
component (tables, pagination, autocomplete), adapted to Phoenix's
server-rendered, stateless-function-component model.

See [`AGENTS.md`](AGENTS.md) for the framework's ground rules: the
`paperize` escape hatch every component supports, the MD3 token layer
(color roles, type scale, shape, elevation, state layers, motion), and the
icon strategy (reusing the heroicons every `mix phx.new`
app already vendors, no extra dependency).

## Status

> [!WARNING]
> PhoenixPaper is in active development. Bugs are expected, and component
> APIs may change between `0.x` releases (breaking changes are always
> called out in the [CHANGELOG](CHANGELOG.md)). The goal is a stable,
> semver-guaranteed API at **1.0.0**. Until then, pin a minor version
> (e.g. `~> 0.4.0`) and please
> [report issues](https://github.com/z7ealth/phoenix_paper/issues) you run into.

## Installation

Add `phoenix_paper` to your `mix.exs` deps:

```elixir
def deps do
  [
    {:phoenix_paper, "~> 0.4.0"}
  ]
end
```

Then, in `lib/my_app_web.ex`, import the components next to your existing
`core_components`:

```elixir
defp html_helpers do
  quote do
    use PhoenixPaper.Components
    # ...
  end
end
```

And wire up the Tailwind theme in `assets/css/app.css`:

```css
@import "tailwindcss";
@import "../../deps/phoenix_paper/priv/static/phoenix_paper.css";
```

The stylesheet carries its own `@source` for PhoenixPaper's `lib/`, so there's no separate `@source` line to add.

MD3's typeface is Roboto Flex. PhoenixPaper doesn't load fonts; add it to
your root layout (or override `--font-pp-brand`/`--font-pp-plain`):

```html
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Roboto+Flex:opsz,wght@8..144,400;8..144,500;8..144,700&display=swap">
```

### Theming

One scheme ships: the MD3 baseline (seed `#6750A4`), light and dark
(`data-theme="dark"`, or the OS preference when `data-theme` isn't set).
For your brand, generate a full MD3 scheme from one seed color:

```sh
mix phoenix_paper.gen.theme --seed "#0b57d0"
```

It writes `assets/css/phoenix_paper_theme.css` (every color role, light
and dark) using Material's HCT color science; import it after
`phoenix_paper.css`. `--scheme` picks the variant (`tonal_spot`, the
default, `neutral`, `vibrant`, `expressive`, `fidelity`, `monochrome`) and
`--secondary`/`--tertiary`/`--neutral`/`--error` pin core colors. A scheme
exported from
[Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)
works too: paste its roles as `--color-pp-*` overrides.

### Optional: the JS hook

Everything works without JavaScript beyond Phoenix's own. One optional
LiveView hook adds what CSS can't do everywhere: the sliding tab
indicator, drag-to-dismiss bottom sheets, the scrolled top app bar and
carousel masking in Firefox, and the loading indicator's morph in Safari.

```js
// assets/js/app.js
import PhoenixPaperHooks from "phoenix_paper"
const liveSocket = new LiveSocket("/live", Socket, {hooks: {...PhoenixPaperHooks}, ...})
```

```elixir
# config/config.exs
config :phoenix_paper, hook: true
```

## Usage

```heex
<div class="flex">
  <%!-- Expressive navigation rail: modal on phones, collapsed/expandable
        from md up. It replaces 0.3's Drawer. --%>
  <.pp_navigation_rail id="app-rail">
    <:fab icon="hero-pencil" label="Compose" navigate={~p"/compose"} />
    <.pp_navigation_rail_item icon="hero-inbox" active_icon="hero-inbox-solid" label="Inbox" navigate={~p"/"} active badge={4} />
    <.pp_navigation_rail_item icon="hero-paper-airplane" label="Sent" navigate={~p"/sent"} />
  </.pp_navigation_rail>

  <main class="flex-1">
    <.pp_top_app_bar position="sticky">
      <:leading><.pp_navigation_rail_toggle for="app-rail" modal_only /></:leading>
      Inbox
      <:actions>
        <.pp_icon_button icon="hero-magnifying-glass" label="Search" />
        <.pp_theme_toggle />
      </:actions>
    </.pp_top_app_bar>
    ...
  </main>
</div>

<%!-- Buttons: filled / tonal / elevated / outlined / text, Expressive sizes
      xs..xl, round or square, shape morphing on press --%>
<.pp_button>Save</.pp_button>
<.pp_button variant="tonal" size="md" shape="square">
  <:start_icon><.pp_icon name="hero-plus" /></:start_icon>
  New
</.pp_button>
<.pp_button href={~p"/issues"} variant="text">Issues</.pp_button>

<%!-- Toggle buttons and connected button groups, client-side, no handler --%>
<.pp_button_group variant="connected" aria-label="View">
  <.pp_button variant="tonal" group="view" selected>Day</.pp_button>
  <.pp_button variant="tonal" group="view" selected={false}>Week</.pp_button>
</.pp_button_group>

<.pp_icon_button icon="hero-star" selected_icon="hero-star-solid" label="Star" variant="tonal" toggle selected={false} />

<.pp_split_button id="send" phx-click="send">
  Send
  <:menu><.pp_menu_item icon="hero-clock" phx-click="schedule">Schedule</.pp_menu_item></:menu>
</.pp_split_button>

<.pp_fab icon="hero-pencil" label="Compose" position="fixed" class="bottom-4 right-4" />
<.pp_fab_menu id="create" label="Create" position="fixed" class="bottom-4 right-4">
  <:item icon="hero-document" label="Document" navigate={~p"/docs/new"} />
  <:item icon="hero-photo" label="Photo" on_click={JS.push("upload")} />
</.pp_fab_menu>

<.pp_card variant="filled">
  <:title>Account</:title>
  <:subhead>Pro plan</:subhead>
  You have no pending invoices.
  <:actions><.pp_button variant="text">Dismiss</.pp_button></:actions>
</.pp_card>

<.pp_typography variant="headline-medium">Release notes</.pp_typography>
<.pp_typography variant="body-medium" color="on-surface-variant">Last updated today</.pp_typography>

<.pp_chip variant="filter" toggle selected={false}>Unread</.pp_chip>
<.pp_chip variant="input" deletable on_delete={JS.push("remove_tag")}>elixir</.pp_chip>

<.pp_tooltip title="Delete">
  <.pp_icon_button icon="hero-trash" label="Delete" title={false} />
</.pp_tooltip>

<.pp_menu id="more" trigger_icon="hero-ellipsis-vertical" trigger_label="More">
  <.pp_menu_item icon="hero-pencil" trailing_text="⌘E" phx-click="edit">Edit</.pp_menu_item>
  <.pp_menu_item icon="hero-trash" phx-click="delete">Delete</.pp_menu_item>
</.pp_menu>

<.pp_tabs id="media">
  <.pp_tab id="media" value="photos" default_selected>Photos</.pp_tab>
  <.pp_tab id="media" value="videos">Videos</.pp_tab>
</.pp_tabs>

<%!-- Forms --%>
<.pp_form for={@form} phx-change="validate" phx-submit="save">
  <.pp_text_field field={@form[:email]} label="Email" supporting_text="We never share it" />
  <.pp_select field={@form[:country]} label="Country" options={["Canada", "Mexico"]} />
  <.live_component module={PhoenixPaper.DatePicker} id="due" field={@form[:due_on]} label="Due date" />
  <.live_component module={PhoenixPaper.TimePicker} id="at" field={@form[:starts_at]} label="Start time" />
  <.pp_checkbox field={@form[:accept]} label="I agree to the terms" />
  <.pp_switch field={@form[:notifications]} label="Notifications" icons />
  <.pp_slider field={@form[:volume]} label="Volume" value_indicator />
  <:actions><.pp_button type="submit">Save</.pp_button></:actions>
</.pp_form>

<.pp_search_bar name="q" placeholder="Search mail">
  <:results><.pp_list>...</.pp_list></:results>
</.pp_search_bar>

<%!-- Feedback --%>
<.pp_progress value={60} />
<.pp_progress wavy />
<.pp_loading_indicator />
<.pp_flash_group flash={@flash} auto_hide_duration={4000} connection_notices />

<.pp_button phx-click={PhoenixPaper.Dialog.show("confirm")}>Delete</.pp_button>
<.pp_dialog id="confirm" icon="hero-trash">
  <:title>Delete this item?</:title>
  This can't be undone.
  <:actions>
    <.pp_button variant="text" phx-click={PhoenixPaper.Dialog.hide("confirm")}>Cancel</.pp_button>
    <.pp_button variant="text" phx-click="delete">Delete</.pp_button>
  </:actions>
</.pp_dialog>

<.pp_bottom_sheet id="share">...</.pp_bottom_sheet>
<.pp_side_sheet id="filters"><:title>Filters</:title>...</.pp_side_sheet>

<.pp_carousel label="Featured">
  <:item :for={p <- @places} label={p.name}><img src={p.photo} alt="" class="size-full object-cover" /></:item>
</.pp_carousel>

<%!-- Bottom navigation on phones, toolbars for page actions --%>
<.pp_navigation_bar position="fixed" class="md:hidden">
  <.pp_navigation_bar_item icon="hero-home" label="Home" navigate={~p"/"} active />
</.pp_navigation_bar>
<.pp_toolbar variant="floating" color="vibrant">
  <.pp_icon_button icon="hero-bold" label="Bold" color="inherit" />
</.pp_toolbar>

<%!-- Tables, pagination, layout and the LiveComponents (Autocomplete,
      PowerSelect, TransferList) are unchanged in shape; see their docs --%>
<.pp_pagination page={@page} count={@total_pages} path={&~p"/users?page=#{&1}"} />
```

Upgrading from 0.3? The [CHANGELOG](CHANGELOG.md) has the full
migration table: every renamed component, attr and value.

Every component accepts `paperize={false}` to drop PhoenixPaper's classes
entirely and render with only your own `class`; see `AGENTS.md` for the
full contract.

Interactive components show MD3's state layers (hover/focus/press tints)
and the focus ring, and `Button`, `IconButton`, `Fab` and linked items
also ripple on click; pass `ripple={false}` to turn the ripple off. No JS
hook involved; see `PhoenixPaper.Ripple`.
