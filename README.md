<p align="center">
  <img src="priv/static/images/logo/phoenixpaper-lockup-card.svg" alt="PhoenixPaper" width="320">
</p>

# PhoenixPaper

[![Hex.pm](https://img.shields.io/hexpm/v/phoenix_paper.svg)](https://hex.pm/packages/phoenix_paper)
[![Hexdocs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/phoenix_paper)
[![License](https://img.shields.io/hexpm/l/phoenix_paper.svg)](https://github.com/z7ealth/phoenix_paper/blob/master/LICENSE)

A Material Design component library for Phoenix, in the spirit of
[ember-paper](https://github.com/miguelcobain/ember-paper), styled with
Tailwind CSS. Most individual components follow the API and behavior of
[MUI](https://mui.com/material-ui/) (Material-UI for React), adapted to
Phoenix's server-rendered, stateless-function-component model.

See [`AGENTS.md`](AGENTS.md) for the framework's ground rules: the
`paperize` escape hatch every component supports, theming, elevation/spacing
helpers, and the icon strategy (reusing the heroicons every `mix phx.new`
app already vendors, no extra dependency).

## Try it live

No app, no asset pipeline needed:

```
elixir dev.exs
```

This boots a real Phoenix + LiveView server on <http://localhost:4000> with
a full catalog of every component: a navigation drawer on the left, and
for each component a live example, its options, and the HEEx snippet that
produced it.

## Installation

Add `phoenix_paper` to your `mix.exs` deps:

```elixir
def deps do
  [
    {:phoenix_paper, "~> 0.2.0"}
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
@source "../../deps/phoenix_paper/lib";
```

## Usage

```heex
<.pp_app_bar position="sticky">
  <:leading><.pp_drawer_toggle for="app-drawer" /></:leading>
  My App
</.pp_app_bar>

<.pp_drawer id="app-drawer">
  <:header>My App</:header>
  <.pp_list>
    <.pp_list_subheader>Main</.pp_list_subheader>
    <.pp_list_item href="/" active={@current_path == "/"}>
      <:leading><.pp_icon name="hero-home" /></:leading>
      Home
    </.pp_list_item>
    <.pp_divider />
    <.pp_list_subheader>Account</.pp_list_subheader>
    <.pp_list_item href="/settings" active={@current_path == "/settings"}>
      <:leading><.pp_icon name="hero-cog-6-tooth" /></:leading>
      Settings
    </.pp_list_item>
  </.pp_list>
</.pp_drawer>

<.pp_container max_width="lg">
  <.pp_grid>
    <.pp_grid_item span={12} md={4}>Sidebar</.pp_grid_item>
    <.pp_grid_item span={12} md={8}>Content</.pp_grid_item>
  </.pp_grid>
</.pp_container>

<.pp_stack direction="row" spacing={:sm}>
  <.pp_button>Save</.pp_button>
  <.pp_button variant="outlined">Cancel</.pp_button>
</.pp_stack>

<.pp_image_list cols={3}>
  <.pp_image_list_item src="/images/1.jpg" title="Breakfast" />
  <.pp_image_list_item src="/images/2.jpg" title="Burger" subtitle="Restaurant" />
</.pp_image_list>

<.pp_button color="primary">Save</.pp_button>
<.pp_button color="primary" ripple={false}>No ripple</.pp_button>
<.pp_button href={~p"/issues"} variant="text">Issues</.pp_button>
<%!-- href/navigate/patch render an <a>, so a "button" that navigates
      never nests <button> inside <a> --%>

<.pp_card>
  <:title>Account</:title>
  You have no pending invoices.
  <:actions>
    <.pp_button variant="text">Dismiss</.pp_button>
  </:actions>
</.pp_card>

<.pp_avatar src="/images/1.jpg" alt="Remy Sharp" />
<.pp_avatar>OP</.pp_avatar>

<.pp_badge content={4}>
  <.pp_icon name="hero-bell" />
</.pp_badge>

<.pp_chip>Basic</.pp_chip>
<.pp_chip deletable on_delete={JS.push("remove_tag")}>React</.pp_chip>

<.pp_tooltip title="Delete">
  <.pp_button variant="icon"><.pp_icon name="hero-trash" /></.pp_button>
</.pp_tooltip>

<.pp_paper elevation={2} class="p-4">A raised surface (Card is built on this).</.pp_paper>
<.pp_typography variant="h4">Account settings</.pp_typography>
<.pp_typography variant="caption">Last updated 2 minutes ago</.pp_typography>

<.pp_input field={@form[:email]} label="Email" />
<.pp_select field={@form[:country]} label="Country" options={["Canada", "Mexico"]} />

<%!-- hide_label: dense, unwrapped variant for an inline filter toolbar --%>
<.pp_input hide_label label="Search" name="q" size="small" />
<.pp_select hide_label label="Status" name="status" prompt="Any" options={["Active", "Archived"]} />
<.pp_number_field field={@form[:quantity]} label="Quantity" min={0} max={10} />

<.pp_checkbox field={@form[:accept]} label="I agree to the terms" />
<.pp_switch field={@form[:notifications]} label="Notifications" />
<.pp_radio_group field={@form[:size]} label="Size" options={[{"Small", "sm"}, {"Large", "lg"}]} />

<.pp_slider name="volume" label="Volume" value={60} />
<.pp_rating id="stars" name="stars" value={3} />

<.pp_button_group>
  <.pp_button variant="outlined">Day</.pp_button>
  <.pp_button variant="outlined">Week</.pp_button>
</.pp_button_group>
<.pp_fab>+</.pp_fab>

<.pp_icon name="hero-check" />

<%!-- Phoenix flash (@flash) as Material snackbars — drop once in the root
      layout, where a generated <.flash_group> would go --%>
<.pp_flash_group flash={@flash} />
<.pp_flash_group flash={@flash} auto_hide_duration={4000} />

<%!-- Autocomplete and TransferList need interactive state, so they're
      Phoenix.LiveComponents (LiveView only) instead of pp_* functions --%>
<.live_component module={PhoenixPaper.Autocomplete} id="country" name="country" label="Country" options={["Canada", "Mexico"]} />
<.live_component module={PhoenixPaper.TransferList} id="permissions" items={["Read", "Write", "Admin"]} />
```

Every component accepts `paperize={false}` to drop PhoenixPaper's classes
entirely and render with only your own `class`; see `AGENTS.md` for the
full contract.

`Button`, `Fab`, `ToggleButton`, and a linked `ListItem` ripple on
click/tap by default (the classic Material feedback effect); pass
`ripple={false}` to turn it off. No JS hook or asset pipeline involved; see
`PhoenixPaper.Ripple`.
