defmodule PhoenixPaper.ThemeToggle do
  @moduledoc """
  A light/dark mode toggle (`pp_theme_toggle/1`) with a sun/moon icon in
  its thumb, wired to flip `data-theme="dark"` on `<html>` (the same
  attribute daisyUI and Phoenix 1.8's generated `app.css` already use —
  see AGENTS.md, "Theming"), so it plugs straight into a dark-mode toggle
  that may already exist elsewhere on the page.

      <.pp_theme_toggle />

      <.pp_theme_toggle label="Dark mode" target="#preview" />

  A vanilla `onclick` **computes the current effective theme itself**
  (`data-theme="dark"`, or — if `data-theme` is unset — whatever
  `matchMedia('(prefers-color-scheme: dark)')` currently says) and sets
  `data-theme` to the *opposite*, as a literal `"dark"`/`"light"` string —
  it deliberately does not trust the checkbox's own `checked` property to
  know which way to go. Two real bugs, both found from an actual dark-OS
  system reproducing them, led here:

  1. An earlier version used `Phoenix.LiveView.JS.toggle_attribute/2`'s
     2-argument "set-or-remove" form. That looked equivalent (and passed
     every existing test, since none of them exercised a system-dark OS
     preference) but broke once `priv/static/phoenix_paper.css` gained its
     "system" `prefers-color-scheme` fallback: *removing* `data-theme`
     doesn't mean "light" anymore, it means "system" — for a user whose OS
     is already dark, unchecking the switch would remove
     `data-theme="dark"`, and the page would immediately fall right back
     to dark via the system media query, making the toggle look stuck.
  2. Fixing *that* by reading `this.checked` to decide `"dark"`/`"light"`
     still wasn't enough: a stateless function component can't know the
     client's OS preference at *server* render time, so the checkbox's
     `checked` *attribute* always starts from `default_checked` (`false`).
     An inline `<script>` that set the `checked` *property* to match
     `matchMedia` on mount (matching the "small vanilla snippet"
     approach `PhoenixPaper.Ripple`/`NumberField` use) looked like the
     fix — but Phoenix LiveView's own connected-mount hydration re-renders
     and morphdom-patches the page shortly after the dead-rendered first
     paint, and that patch can replace the checkbox element with a fresh
     one built from the *server's* render (which still has
     `default_checked`), silently undoing the script's mutation. The
     visible symptom: a dark-OS user sees a correctly-dark page next to a
     toggle that *looks* off/light — and the first click, since it read
     the (wrongly-reset) `checked` property, just reasserted "dark" (a
     no-op the user couldn't see), so it took *two* clicks to actually
     reach light. Computing the effective theme directly in the click
     handler sidesteps the whole race: it never matters whether the
     checkbox's own property is stale, because the decision is never based
     on it.

  ## Defaults to "system"

  Before the first click, this doesn't force `data-theme` to anything —
  `priv/static/phoenix_paper.css`'s theme CSS already falls back to the
  OS/browser's own `prefers-color-scheme` when `data-theme` is unset, so
  the page itself already renders correctly with zero clicks, and (per the
  bug above) reliably syncing the *toggle's own* first-paint appearance to
  that same preference needs to happen in CSS too, immune to the same
  hydration race — see `priv/static/phoenix_paper.css`'s
  `[data-pp-component="theme-toggle"]` system-preference block. Once
  clicked, "system" is gone for that session (there's no way back to it
  without reloading with `data-theme` cleared some other way — the same
  one-way-door trade-off `Accordion`'s exclusive-radio-group mode and
  `Breadcrumbs`'s expand-once ellipsis already accept for a pure-CSS/
  vanilla-JS toggle with no server state).

  `target` (default `"html"`) is a plain CSS selector, so a toggle that
  should only affect a scoped preview area instead of the whole page works
  too: `target="#preview"`.

  `on_toggle` (default `%JS{}`) is wired as a plain `phx-click`, running
  independently alongside the `onclick` above — for a caller that also
  wants to persist the choice server-side, e.g.
  `on_toggle={JS.push("save_theme_preference")}`.

  Built with its own markup rather than composing `PhoenixPaper.Switch` (an
  earlier version did) — the sun/moon icons live *inside* the sliding
  thumb, swapped via a `peer-checked:` compound selector reaching into the
  thumb's own children (`Switch` has no attr for that, and doesn't need
  one for its own use cases).

  Deliberately **not** colored with any `pp-*` brand token (`Switch`'s own
  thumb/track go `pp-primary` when checked) — a theme toggle's single most
  common home is an `AppBar`/header, which is itself very often colored
  `pp-primary` by default. A `bg-pp-primary` thumb sitting on a
  `bg-pp-primary` app bar is the exact "same color layered on itself"
  invisibility bug already documented for `Drawer`'s colored variants and
  for buttons dropped into a colored `AppBar` (see AGENTS.md) — rather than
  fix that per-placement with a `class` override (`Switch`'s architecture
  doesn't expose its internal track/thumb for one anyway), this component
  just never uses a background color that could plausibly match its own
  container: the thumb is fixed white, the track a neutral translucent
  gray, and the sun/moon icon color is what actually carries the on/off
  state — all three read clearly against light backgrounds, dark
  backgrounds, and colored chrome alike.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Helpers, Ripple}
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:id, :any, default: nil)

  attr(:label, :any,
    default: "Dark mode",
    doc: "text next to the switch — pass nil for icon-only"
  )

  attr(:default_checked, :boolean,
    default: false,
    doc:
      "initial checkbox attribute — mostly cosmetic with JS enabled (CSS handles the real first-paint sync), matters if JS is disabled"
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
    assigns = assign(assigns, :ripple?, assigns.ripple and assigns.paperize)

    ~H"""
    <label data-pp-component="theme-toggle" class={Helpers.toggle_label_classes(if @paperize, do: @class)}>
      <span class={Helpers.classes(@paperize, track_classes(), nil)}>
        <input
          type="checkbox"
          id={@id}
          checked={@default_checked}
          class={Helpers.classes(@paperize, input_classes(), nil)}
          onclick={onclick_script(@ripple?, @target)}
          phx-click={@on_toggle}
        />
        <span class={Helpers.classes(@paperize, thumb_classes(), nil)}>
          <span class="absolute inset-0 flex items-center justify-center text-amber-500 opacity-100 transition-opacity">
            <.pp_icon name="hero-sun-mini" class="!size-3" />
          </span>
          <span class="absolute inset-0 flex items-center justify-center text-slate-700 opacity-0 transition-opacity">
            <.pp_icon name="hero-moon-mini" class="!size-3" />
          </span>
        </span>
      </span>
      <span :if={@label}>{@label}</span>
    </label>
    """
  end

  defp onclick_script(ripple?, target) do
    toggle = """
    (function(cb){\
    var isDark=document.documentElement.getAttribute('data-theme')==='dark'||(!document.documentElement.hasAttribute('data-theme')&&window.matchMedia('(prefers-color-scheme: dark)').matches);\
    var next=isDark?'light':'dark';\
    document.querySelector(#{inspect(target)}).setAttribute('data-theme',next);\
    cb.checked=(next==='dark');\
    })(this);\
    """

    case Ripple.on_click_centered(ripple?) do
      nil -> toggle
      ripple_js -> ripple_js <> ";" <> toggle
    end
  end

  defp track_classes do
    "has-[:checked]:bg-gray-500/70 relative inline-flex h-6 w-10 shrink-0 items-center rounded-full bg-gray-500/40 transition-colors"
  end

  defp input_classes do
    "peer absolute inset-0 m-0 cursor-pointer opacity-0"
  end

  defp thumb_classes do
    "pointer-events-none absolute left-0.5 flex size-5 items-center justify-center rounded-full bg-white shadow transition-transform peer-checked:translate-x-4 peer-checked:[&>span:first-child]:opacity-0 peer-checked:[&>span:last-child]:opacity-100"
  end
end
