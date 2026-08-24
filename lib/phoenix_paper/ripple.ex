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

  `container_classes/1` adds `relative overflow-hidden` when ripple is on —
  the ripple `<span>` is absolutely positioned relative to the nearest
  `position: relative` ancestor and clipped by the nearest `overflow:
  hidden` one, so the component needs both for the ripple to render inside
  its own bounds instead of spilling out or floating relative to some other
  ancestor. Those classes live in `paper_classes`, so — like the rest of a
  component's styling — `paperize={false}` strips them too; add them back
  yourself via `class` if you turn off `paperize` but still want `ripple` to
  look right.

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

  @doc """
  The `onclick` attribute value that spawns a ripple on the clicked
  element, or `nil` when `enabled?` is `false` — HEEx drops an attribute
  entirely when its value is `nil`, so `onclick={Ripple.on_click(@ripple)}`
  just renders no attribute at all rather than an empty one.
  """
  @spec on_click(boolean()) :: String.t() | nil
  def on_click(false), do: nil
  def on_click(true), do: @ripple_js

  @doc """
  The classes a ripple-enabled root element needs so the ripple stays
  positioned and clipped correctly. Empty when `enabled?` is `false`.
  """
  @spec container_classes(boolean()) :: String.t()
  def container_classes(false), do: ""
  def container_classes(true), do: "relative overflow-hidden"
end
