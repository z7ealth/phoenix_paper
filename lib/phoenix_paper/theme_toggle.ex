defmodule PhoenixPaper.ThemeToggle do
  @moduledoc """
  A System / Light / Dark theme picker (`pp_theme_toggle/1`) that sets
  `data-theme` on `<html>` (the attribute Phoenix 1.8's generated
  `app.css` and `phoenix_paper.css` key dark mode off — see AGENTS.md,
  "Theming").

      <.pp_theme_toggle />

  Three icon buttons (monitor, sun, moon) in an `outline-variant` pill,
  with a sliding `secondary-container` indicator under the selected one
  (MD3's selected-segment color, moving on the Expressive spatial
  spring). **System is the default**: it *removes* `data-theme`, so
  `phoenix_paper.css`'s `prefers-color-scheme` fallback follows the OS
  (live, when the OS switches). Light and Dark set `data-theme="light"`/
  `"dark"` explicitly.

  - **Which one is selected is pure CSS**, keyed off the nearest ancestor's
    `data-theme` (`[[data-theme=light]_&]:translate-x-8`, ...): no
    `data-theme` anywhere above → System. Nothing is stored on the
    component, so a LiveView patch can't reset the indicator (a script
    setting a checkbox's `checked` property can be undone by hydration),
    and every toggle on the page shows the same state with no syncing code.
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
    so `on_toggle={JS.push("save_theme")}` sends `%{"theme" => "dark"}` to
    your LiveView to persist it server-side.
  - `aria-label="Theme"` on the group, `aria-label`/`title` on each
    button. There's no `aria-pressed`: it would have to be set by JS on
    click, which a LiveView patch can undo — the same reason the indicator
    is CSS. `label` adds visible text next to the control.
  - `target` (default `"html"`) is a CSS selector, so a toggle can theme a
    scoped preview instead (`target="#preview"`). Put that toggle *inside*
    the target so its indicator reads the right `data-theme`.

  ## Migrating from 0.4

  `variant="switch"` (and its `default_checked`) is gone: its sun/moon
  switch used hand-picked colors rather than MD3 roles. The segmented
  control is the only variant, so `variant` is gone too.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Helpers, Ripple}
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:id, :any, default: nil)

  attr(:label, :string, default: nil, doc: "visible text next to the control")

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
  def pp_theme_toggle(assigns) do
    assigns =
      assigns
      |> assign(:ripple?, assigns.ripple and assigns.paperize)
      |> assign(:modes, @modes)

    ~H"""
    <div
      id={@id}
      data-pp-component="theme-toggle"
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
          <.pp_icon name={icon} size="sm" />
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
    "relative inline-flex shrink-0 items-center rounded-pp-full border border-pp-outline-variant p-0.5"
  end

  # The indicator's position is keyed off the nearest ancestor's
  # data-theme (no data-theme at all → System, the default position).
  defp indicator_classes do
    "pointer-events-none absolute start-0.5 top-0.5 size-8 rounded-pp-full bg-pp-secondary-container pp-motion-spatial-default [[data-theme=light]_&]:translate-x-8 [[data-theme=dark]_&]:translate-x-16"
  end

  # The selected icon sits on the secondary-container indicator, so it
  # takes on-secondary-container; the others are on-surface-variant.
  defp segment_classes("system") do
    "relative z-10 flex size-8 cursor-pointer items-center justify-center rounded-pp-full text-pp-on-secondary-container pp-focus-ring pp-motion-effects-fast [[data-theme=light]_&]:text-pp-on-surface-variant [[data-theme=dark]_&]:text-pp-on-surface-variant"
  end

  defp segment_classes("light") do
    "relative z-10 flex size-8 cursor-pointer items-center justify-center rounded-pp-full text-pp-on-surface-variant pp-focus-ring pp-motion-effects-fast [[data-theme=light]_&]:text-pp-on-secondary-container"
  end

  defp segment_classes("dark") do
    "relative z-10 flex size-8 cursor-pointer items-center justify-center rounded-pp-full text-pp-on-surface-variant pp-focus-ring pp-motion-effects-fast [[data-theme=dark]_&]:text-pp-on-secondary-container"
  end
end
