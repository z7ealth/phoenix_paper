defmodule PhoenixPaper.ThemeToggle do
  @moduledoc """
  A light/dark mode toggle (`pp_theme_toggle/1`) — a thin, named wrapper
  around `PhoenixPaper.Switch` wired to flip `data-theme="dark"` on
  `<html>` (the same attribute daisyUI and Phoenix 1.8's generated
  `app.css` already use — see AGENTS.md, "Theming"), so it plugs straight
  into a dark-mode toggle that may already exist elsewhere on the page.

      <.pp_theme_toggle />

      <.pp_theme_toggle label="Dark mode" default_checked={@dark_mode?} />

  Pure `Phoenix.LiveView.JS`, no server round-trip: `JS.toggle_attribute/1,2`
  reads the target element's *current* attribute at click time and flips
  it, so this needs no state of its own to know which way to go next — the
  same reasoning `PhoenixPaper.Tabs.select/3` and `PhoenixPaper.Dialog`'s
  show/hide already rely on. That also means, like every other
  uncontrolled toggle in this library (`Accordion`'s `default_expanded`,
  `Drawer`'s mobile checkbox), the switch's own visual on/off state and the
  page's actual current theme are two independent things that just happen
  to start in sync when `default_checked` matches reality — there's no
  built-in way for a stateless function component to know the current
  theme on first render (e.g. from a cookie, or the `prefers-color-scheme`
  media query) and set `default_checked` accordingly; that's the caller's
  job if it matters for their app (read it server-side at mount, pass it
  down as `default_checked={@dark_mode?}`).

  `target` (default `"html"`) is a plain CSS selector, so a toggle that
  should only affect a scoped preview area instead of the whole page works
  too: `target="#preview"`.

  `on_toggle` (default `%JS{}`) runs *before* the built-in
  `data-theme` flip, for a caller that also wants to persist the choice
  server-side, e.g. `on_toggle={JS.push("save_theme_preference")}` — the
  same composable-JS-command convention `PhoenixPaper.Dialog`'s
  `on_cancel` already uses.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import PhoenixPaper.Switch, only: [pp_switch: 1]

  attr(:id, :any, default: nil)
  attr(:label, :string, default: "Dark mode")

  attr(:default_checked, :boolean,
    default: false,
    doc:
      "initial visual state — set it from your own known theme, if you track one, for an accurate first paint"
  )

  attr(:target, :string,
    default: "html",
    doc: "CSS selector for the element to toggle data-theme on"
  )

  attr(:on_toggle, JS,
    default: %JS{},
    doc: "extra JS commands run before the built-in data-theme flip"
  )

  attr(:ripple, :boolean,
    default: true,
    doc:
      "the Material ripple effect on click/tap — off whenever paperize is false, see PhoenixPaper.Ripple"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  @doc "Renders a light/dark mode toggle. See the module doc."
  def pp_theme_toggle(assigns) do
    ~H"""
    <.pp_switch
      id={@id}
      label={@label}
      checked={@default_checked}
      ripple={@ripple}
      paperize={@paperize}
      class={@class}
      phx-click={JS.toggle_attribute(@on_toggle, {"data-theme", "dark"}, to: @target)}
    />
    """
  end
end
