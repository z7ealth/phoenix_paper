defmodule PhoenixPaper.Ripple do
  @moduledoc """
  The Material Design ripple effect — a circle that expands from the
  click/tap position and fades out.

  Implemented as a small vanilla inline `onclick` snippet — no JS hook, no
  bundler, no extra dependency, same approach as
  `PhoenixPaper.NumberField`'s stepper buttons (see AGENTS.md). `onclick`
  (not `onpointerdown`/`onmousedown`) is used deliberately: Phoenix's HEEx
  compiler only accepts a fixed allowlist of `on*` event attributes on
  function components like `Phoenix.Component.link/1` (which `ListItem`
  renders through for a linked item), and `onclick` is the one in that list
  that also fires reliably for touch — `onpointerdown`/`onmousedown` either
  aren't recognized at all or behave inconsistently on touch devices.

  Every component that supports it (`Button`, `Fab`, `ToggleButton`,
  `ListItem`) exposes a `ripple` boolean attr, **default `true`**, and wires
  it the same way:

      class={Helpers.classes(@paperize, [..., Ripple.container_classes(@ripple)], @class)}
      onclick={Ripple.on_click(@ripple)}

  `Switch`, `Checkbox`, and `RadioGroup` also support it, but wire
  `on_click_centered/1` instead of `on_click/1`, and don't use
  `container_classes/1` at all — their small track/box is already
  `relative`, and deliberately *without* `overflow-hidden`: Material's
  ripple on these controls is meant to spill out past the tiny target as a
  soft halo, not get clipped to it, unlike Button's ripple which stays
  contained inside the button's own bounds. `on_click_centered/1` is also a
  visibly *smaller* effect than `on_click/1` — see its own doc for why
  click-position-based sizing doesn't suit a 20-40px control.

  `container_classes/1` adds `relative overflow-hidden` when ripple is on —
  the ripple `<span>` is absolutely positioned relative to the nearest
  `position: relative` ancestor and clipped by the nearest `overflow:
  hidden` one, so the component needs both for the ripple to render inside
  its own bounds instead of spilling out or floating relative to some other
  ancestor. Those classes live in `paper_classes`, so — like the rest of a
  component's styling — `paperize={false}` strips them too. Because of
  that, every ripple-capable component computes its *effective* ripple
  state as `ripple and paperize` (e.g. `assign(:ripple?, assigns.ripple and
  assigns.paperize)`) rather than using the caller's `ripple` value
  directly — `paperize={false}` always turns ripple off too, regardless of
  `ripple`, so there's no positioning-context footgun by default. There's
  no attr combination that brings it back; a caller who wants a ripple
  without PhoenixPaper's other styling needs to keep `paperize={true}` and
  override the unwanted classes individually via `class` instead.

  Two non-obvious things about the script itself, both worth knowing before
  touching it:

  - **The radius is the distance from the click point to the farthest
    corner** (`Math.max(x, width - x)` and `Math.max(y, height - y)`,
    combined via Pythagoras), not just a multiple of the element's
    dimensions — a click near one edge needs to reach much farther to the
    opposite corner than a click in the center does. Sizing it off
    `max(width, height)` alone (an earlier version of this did) under-covers
    the element for most click positions.
  - **The reflow between setting `scale(0)` and `scale(1)` is required, not
    decorative.** Setting the ripple's initial `transform: scale(0)` and
    then its target `transform: scale(1)` back-to-back in the same tick
    (even from inside a single `requestAnimationFrame` callback — an
    earlier version of this did that too) lets the browser coalesce both
    style writes into one recalculation, so the *transition* never actually
    runs — the circle just pops directly to full size with no visible
    expansion, only the opacity fade at the end is visible. Reading
    `span.offsetWidth` between the two writes forces the browser to flush
    style/layout for the `scale(0)` state first, so the following
    `scale(1)` write is seen as a genuine change and animates.
  """

  @ripple_js "(function(e){var el=e.currentTarget;var rect=el.getBoundingClientRect();var x=e.clientX-rect.left;var y=e.clientY-rect.top;var radius=Math.sqrt(Math.pow(Math.max(x,rect.width-x),2)+Math.pow(Math.max(y,rect.height-y),2));var size=radius*2;var span=document.createElement('span');span.style.cssText='position:absolute;left:'+(x-radius)+'px;top:'+(y-radius)+'px;width:'+size+'px;height:'+size+'px;border-radius:9999px;background:currentColor;opacity:.25;pointer-events:none;transform:scale(0);transition:transform .5s cubic-bezier(0,0,.2,1),opacity .7s ease-out;';el.appendChild(span);void span.offsetWidth;span.style.transform='scale(1)';setTimeout(function(){span.style.opacity='0';},250);setTimeout(function(){span.remove();},700);})(event)"

  @ripple_js_centered "(function(e){var el=e.currentTarget;var rect=el.getBoundingClientRect();var size=Math.min(rect.width,rect.height)*1.6;var span=document.createElement('span');span.style.cssText='position:absolute;left:'+(rect.width/2-size/2)+'px;top:'+(rect.height/2-size/2)+'px;width:'+size+'px;height:'+size+'px;border-radius:9999px;background:currentColor;opacity:.25;pointer-events:none;transform:scale(0);transition:transform .5s cubic-bezier(0,0,.2,1),opacity .7s ease-out;';el.appendChild(span);void span.offsetWidth;span.style.transform='scale(1)';setTimeout(function(){span.style.opacity='0';},250);setTimeout(function(){span.remove();},700);})(event)"

  @doc """
  The `onclick` attribute value that spawns a ripple expanding from the
  click/tap position, or `nil` when `enabled?` is `false` — HEEx drops an
  attribute entirely when its value is `nil`, so
  `onclick={Ripple.on_click(@ripple)}` just renders no attribute at all
  rather than an empty one. Used by `Button`, `Fab`, `ToggleButton`, and
  `ListItem`; see `on_click_centered/1` for the small-toggle-control
  variant.
  """
  @spec on_click(boolean()) :: String.t() | nil
  def on_click(false), do: nil
  def on_click(true), do: @ripple_js

  @doc """
  Like `on_click/1`, but the ripple is a fixed size (`1.6×` the element's
  smaller dimension) centered on the element, ignoring click position —
  used by `Switch`, `Checkbox`, and `RadioGroup` instead of `on_click/1`.

  Click-position sizing doesn't suit these: `on_click/1`'s radius reaches
  the *farthest corner* from the click, which on a 20-40px control means
  almost any click produces a ripple 1.4-2.2× the control's own size — on
  a button that's invisible against everything else going on, but on a
  bare checkbox it reads as oversized and, since it tracks click position,
  inconsistently placed/sized between clicks on the same tiny target.
  Material's own state-layer treatment for these controls is a fixed-size
  halo centered on the control regardless of exactly where within it you
  clicked, which is what this produces.
  """
  @spec on_click_centered(boolean()) :: String.t() | nil
  def on_click_centered(false), do: nil
  def on_click_centered(true), do: @ripple_js_centered

  @doc """
  The classes a ripple-enabled root element needs so the ripple stays
  positioned and clipped correctly. Empty when `enabled?` is `false`. Only
  relevant to `on_click/1`'s users — see the moduledoc for why
  `on_click_centered/1`'s users don't use this.
  """
  @spec container_classes(boolean()) :: String.t()
  def container_classes(false), do: ""
  def container_classes(true), do: "relative overflow-hidden"
end
