defmodule PhoenixPaper.ThemeToggle do
  @moduledoc """
  A theme picker (`pp_theme_toggle/1`) that sets `data-theme` on `<html>`
  (the same attribute daisyUI and Phoenix 1.8's generated `app.css` use —
  see AGENTS.md, "Theming"), so it plugs into whatever already keys off it.

      <.pp_theme_toggle />
      <.pp_theme_toggle variant="switch" />

  ## `variant="segmented"` (default): System / Light / Dark

  Three icon buttons (monitor, sun, moon) with a sliding white indicator
  under the selected one — the same control Phoenix 1.8's generated root
  layout ships. **System is the default**: it *removes* `data-theme`, so
  `phoenix_paper.css`'s `prefers-color-scheme` fallback follows the OS
  (and follows it live when the OS switches). Light and Dark set
  `data-theme="light"`/`"dark"` explicitly. Unlike the switch below, you
  can always get back to System.

  - **Which one is selected is pure CSS**, keyed off the nearest ancestor's
    `data-theme` (`[[data-theme=light]_&]:translate-x-7`, ...): no
    `data-theme` anywhere above → System. Nothing is stored on the
    component itself, so LiveView re-rendering or patching it can't reset
    the indicator (the hydration race described under the switch below
    can't happen), and every toggle on the page shows the same state with
    no syncing code.
  - **The choice is remembered** in `localStorage` under `"phx:theme"`
    (removed for System) when `target` is `"html"` — the key Phoenix 1.8's
    generated root layout reads on load, so in a 1.8 app the choice
    survives reloads with no extra setup. In any other app, restore it
    before first paint with this in your root layout's `<head>`:

        <script>
          (() => {
            const t = localStorage.getItem("phx:theme");
            if (t) document.documentElement.setAttribute("data-theme", t);
          })();
        </script>

  - Each button carries `phx-value-theme` (`"system"`/`"light"`/`"dark"`),
    so `on_toggle={JS.push("save_theme")}` sends
    `%{"theme" => "dark"}` to your LiveView to persist it server-side.
  - `label` is off by default here (`aria-label="Theme"` on the group,
    `aria-label`/`title` on each button). There's no `aria-pressed`: it
    would have to be set by JS on click, which a LiveView patch can undo —
    the same reason the indicator is CSS.
  - With a scoped `target` (e.g. `"#preview"`), put the toggle *inside*
    that element so its indicator reads the right `data-theme`; the
    indicator always reflects the toggle's own ancestors.

  ## `variant="switch"`: the original light/dark switch

  A sun/moon switch. It starts out following the system preference too,
  but has only two positions, so after the first click there's no way
  back to System (see "Defaults to system" below). It also remembers the
  choice under `"phx:theme"` like the segmented control.

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

  ## Defaults to "system" (switch variant)

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

  ## The switch shows `data-theme`, not its checkbox

  Once `data-theme` is set explicitly, the switch's look is keyed off it
  in CSS (`[[data-theme=dark]_&]:!translate-x-4`, ...), the same way the
  segmented control's indicator is, and ignores its own checkbox. The
  checkbox can't be trusted: the server always renders it at
  `default_checked`, so after a reload with a saved `"dark"` it showed
  "off / sun" on a dark page; and anything else that changes the theme
  (the segmented control, Phoenix 1.8's picker, your own script) never
  touches it. With the look coming from `data-theme`:

  | State on load     | Switch shows            | via |
  |-------------------|-------------------------|-----|
  | System, OS light  | off, sun                | the plain checkbox (unchecked) |
  | System, OS dark   | on, moon                | the `html:not([data-theme])` rule in `phoenix_paper.css` |
  | `data-theme="dark"`  | on, moon             | `[[data-theme=dark]_&]:!...` |
  | `data-theme="light"` | off, sun             | `[[data-theme=light]_&]:!...` |

  and it stays right through LiveView re-renders, since nothing is stored
  on the element. Clicking was already correct (it reads `data-theme` to
  decide which way to flip). Like the segmented control, it reads the
  *nearest* ancestor's `data-theme`, so with a scoped `target` put the
  switch inside that element.

  `target` (default `"html"`) is a plain CSS selector, so a toggle that
  should only affect a scoped preview area instead of the whole page works
  too: `target="#preview"`.

  ## Multiple instances stay in sync — scoped by `target`

  A page can have more than one `pp_theme_toggle` (e.g. one in an `AppBar`
  and another in a dedicated settings section) and clicking either one keeps
  them all visually in sync: alongside setting `data-theme`, the `onclick`
  also runs `document.querySelectorAll` for every
  `[data-pp-component="theme-toggle"][data-pp-target="..."]` checkbox and
  sets its `checked` property to match. This is plain DOM querying done at
  click time — no JS hooks, no PubSub, no LiveView involved — so it works
  across LiveViews on the same page just as well as within one.

  The sync is scoped to toggles sharing the *same* `target`, not every
  toggle on the page unconditionally: a toggle scoped to `target="#preview"`
  and one bound to `target="html"` represent two independent pieces of
  state (a live preview area's theme vs. the whole page's), so syncing them
  together would be wrong even though both are `pp_theme_toggle`s. Two
  toggles that both default to `target="html"` (the common case) sync with
  each other automatically, with no extra configuration needed.

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

  attr(:variant, :string,
    default: "segmented",
    values: ~w(segmented switch),
    doc: "segmented = System/Light/Dark buttons (default); switch = two-state light/dark"
  )

  attr(:label, :any,
    default: :default,
    doc:
      "visible text next to the control — defaults to none for segmented, \"Dark mode\" for switch; nil hides it"
  )

  attr(:default_checked, :boolean,
    default: false,
    doc:
      "switch only: initial checkbox attribute — mostly cosmetic with JS enabled (CSS handles the real first-paint sync), matters if JS is disabled"
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

  # Kept as one literal list (not built from `mode`) so the icon names stay
  # greppable for anyone checking which `hero-*` icons an app needs.
  @modes [
    {"system", "hero-computer-desktop-micro", "System theme"},
    {"light", "hero-sun-micro", "Light theme"},
    {"dark", "hero-moon-micro", "Dark theme"}
  ]

  @doc "Renders a theme toggle. See the module doc."
  def pp_theme_toggle(%{variant: "switch"} = assigns) do
    assigns =
      assigns
      |> assign(:ripple?, assigns.ripple and assigns.paperize)
      |> assign(:label, if(assigns.label == :default, do: "Dark mode", else: assigns.label))

    ~H"""
    <label
      data-pp-component="theme-toggle"
      data-pp-target={@target}
      class={Helpers.toggle_label_classes(if @paperize, do: @class)}
    >
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

  def pp_theme_toggle(assigns) do
    assigns =
      assigns
      |> assign(:ripple?, assigns.ripple and assigns.paperize)
      |> assign(:label, if(assigns.label == :default, do: nil, else: assigns.label))
      |> assign(:modes, @modes)

    ~H"""
    <div
      id={@id}
      data-pp-component="theme-toggle"
      data-pp-variant="segmented"
      data-pp-target={@target}
      class={Helpers.classes(@paperize, "inline-flex items-center gap-2", @class)}
    >
      <div
        role="group"
        aria-label="Theme"
        class={Helpers.classes(@paperize, segmented_track_classes(), nil)}
      >
        <span aria-hidden="true" class={Helpers.classes(@paperize, indicator_classes(), nil)} />
        <button
          :for={{mode, icon, name} <- @modes}
          type="button"
          aria-label={name}
          title={name}
          data-pp-theme={mode}
          phx-value-theme={mode}
          phx-click={@on_toggle}
          onclick={set_script(@ripple?, @target, mode)}
          class={Helpers.classes(@paperize, segment_classes(mode), nil)}
        >
          <.pp_icon name={icon} class="!size-4" />
        </button>
      </div>
      <span :if={@label}>{@label}</span>
    </div>
    """
  end

  defp set_script(ripple?, target, mode) do
    script = """
    (function(){\
    var m=#{inspect(mode)};\
    var t=document.querySelector(#{inspect(target)});if(!t){return;}\
    if(m==='system'){t.removeAttribute('data-theme');}else{t.setAttribute('data-theme',m);}\
    #{persist_js(target, "m==='system'?null:m")}\
    })();\
    """

    case Ripple.on_click_centered(ripple?) do
      nil -> script
      ripple_js -> ripple_js <> ";" <> script
    end
  end

  # Only the page-wide theme is remembered — a scoped preview's theme is
  # the caller's own business. `"phx:theme"` is the key Phoenix 1.8's
  # generated root layout already restores on load.
  defp persist_js("html", value_js) do
    "try{var v=#{value_js};if(v){localStorage.setItem('phx:theme',v);}else{localStorage.removeItem('phx:theme');}}catch(e){}"
  end

  defp persist_js(_target, _value_js), do: ""

  defp segmented_track_classes do
    "relative inline-flex shrink-0 items-center rounded-full bg-gray-500/25 p-0.5"
  end

  # The indicator's position is keyed off the nearest ancestor's
  # data-theme (no data-theme at all → System, the default position).
  defp indicator_classes do
    "pointer-events-none absolute left-0.5 top-0.5 size-7 rounded-full bg-white shadow transition-transform duration-200 [[data-theme=light]_&]:translate-x-7 [[data-theme=dark]_&]:translate-x-14"
  end

  # The selected icon sits on the white indicator, so it switches to a
  # fixed dark color; the others keep the surrounding text color, dimmed.
  defp segment_classes("system") do
    "relative z-10 flex size-7 cursor-pointer items-center justify-center rounded-full text-slate-700 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-current [[data-theme=light]_&]:text-inherit [[data-theme=light]_&]:opacity-70 [[data-theme=dark]_&]:text-inherit [[data-theme=dark]_&]:opacity-70"
  end

  defp segment_classes("light") do
    "relative z-10 flex size-7 cursor-pointer items-center justify-center rounded-full opacity-70 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-current [[data-theme=light]_&]:text-slate-700 [[data-theme=light]_&]:opacity-100"
  end

  defp segment_classes("dark") do
    "relative z-10 flex size-7 cursor-pointer items-center justify-center rounded-full opacity-70 transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-current [[data-theme=dark]_&]:text-slate-700 [[data-theme=dark]_&]:opacity-100"
  end

  defp onclick_script(ripple?, target) do
    sync_selector =
      "[data-pp-component=\"theme-toggle\"][data-pp-target=\"#{target}\"] input[type=checkbox]"

    toggle = """
    (function(cb){\
    var isDark=document.documentElement.getAttribute('data-theme')==='dark'||(!document.documentElement.hasAttribute('data-theme')&&window.matchMedia('(prefers-color-scheme: dark)').matches);\
    var next=isDark?'light':'dark';\
    document.querySelector(#{inspect(target)}).setAttribute('data-theme',next);\
    document.querySelectorAll(#{inspect(sync_selector)}).forEach(function(other){other.checked=(next==='dark');});\
    #{persist_js(target, "next")}\
    })(this);\
    """

    case Ripple.on_click_centered(ripple?) do
      nil -> toggle
      ripple_js -> ripple_js <> ";" <> toggle
    end
  end

  # The `[[data-theme=...]_&]:!...` rules make an explicit data-theme win
  # over the checkbox's own (possibly stale) checked state — see the
  # moduledoc, "The switch shows data-theme, not its checkbox". `!` because
  # `has-[:checked]:`/`peer-checked:` would otherwise tie or beat them.
  defp track_classes do
    "has-[:checked]:bg-gray-500/70 relative inline-flex h-6 w-10 shrink-0 items-center rounded-full bg-gray-500/40 transition-colors [[data-theme=dark]_&]:!bg-gray-500/70 [[data-theme=light]_&]:!bg-gray-500/40"
  end

  defp input_classes do
    "peer absolute inset-0 m-0 cursor-pointer opacity-0"
  end

  defp thumb_classes do
    "pointer-events-none absolute left-0.5 flex size-5 items-center justify-center rounded-full bg-white shadow transition-transform peer-checked:translate-x-4 peer-checked:[&>span:first-child]:opacity-0 peer-checked:[&>span:last-child]:opacity-100 [[data-theme=dark]_&]:!translate-x-4 [[data-theme=dark]_&]:[&>span:first-child]:!opacity-0 [[data-theme=dark]_&]:[&>span:last-child]:!opacity-100 [[data-theme=light]_&]:!translate-x-0 [[data-theme=light]_&]:[&>span:first-child]:!opacity-100 [[data-theme=light]_&]:[&>span:last-child]:!opacity-0"
  end
end
