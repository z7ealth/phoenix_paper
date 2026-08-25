defmodule PhoenixPaper.Slider do
  @moduledoc """
  A Material Design slider (`pp_slider/1`) — a native `<input
  type="range">`, in the spirit of MUI's `Slider`.

      <.pp_slider name="volume" value={60} label="Volume" />

  Colored/sized via a small set of literal, mutually-exclusive CSS
  utilities in `priv/static/phoenix_paper.css` (`pp-slider`/
  `pp-slider-small`/`pp-slider-vertical`/`pp-slider-vertical-small`, plus
  `pp-slider-primary`/etc. and `pp-slider-track-none`/
  `pp-slider-track-inverted`) rather than `accent-color` alone — see that
  file's own comment for why `accent-color` can't give the *unfilled* part
  of the track a controlled color once you also want control over its
  thickness/rounding. The filled segment is a `linear-gradient` positioned
  by a `--pp-slider-percent` CSS custom property, set inline for the first
  paint and kept in sync on drag by a tiny vanilla `oninput` snippet — the
  same "small inline script, no hook, no bundler" approach
  `PhoenixPaper.Ripple`/`PhoenixPaper.NumberField`'s steppers already use.

  ## Sizes

  `size="small"` shrinks the track/thumb, matching MUI's own `size` prop.

  ## Track

  `track="none"` hides the filled segment entirely (still shows the
  neutral track + a colored thumb) — MUI's `track={false}`. `track="inverted"`
  fills from the thumb to `max` instead of from `min` to the thumb — MUI's
  `track="inverted"`. Both are ignored for range sliders (see below), which
  always show the colored segment *between* the two thumbs.

  ## Marks

  `marks={true}` ticks every `step`; `marks={[10, 50, 90]}` ticks specific
  values; `marks={[{0, "0°C"}, {100, "100°C"}]}` ticks specific values
  *with* labels drawn below the track. Ticks render via the native
  `<datalist>`/`list=` pairing (real HTML, not a custom widget) — Chrome
  and Firefox both draw tick marks and snap the thumb near them for free.
  Label positioning assumes `orientation="horizontal"`; it isn't
  implemented for vertical sliders.

  ## Range sliders

  Pass a `{low, high}` tuple as `value` for a two-thumb range slider —
  MUI's array `value`. Submits as `"\#{name}_min"`/`"\#{name}_max"` (two
  separate native inputs; there's no native two-handle range input, and
  splitting the name avoids the query-string array-parsing ambiguity a
  shared name would need to resolve). Built the well-known way two
  overlapping native range inputs fake a range slider: each input's own
  track is made fully transparent (`pointer-events: none` on the input,
  re-enabled only on its own thumb via `[&::-webkit-slider-thumb]:pointer-events-auto`/
  `[&::-moz-range-thumb]:pointer-events-auto`, so clicking near either thumb
  reaches it and nothing else), and the colored segment *between* the two
  thumbs is a separate absolutely-positioned `<div>` kept in sync by the
  same kind of inline `oninput` snippet. Known, inherent limitation of this
  technique (shared by essentially every native-input-based range slider):
  a low thumb dragged past the high thumb's value (or vice versa) is
  clamped by the inline script on `input`, not prevented at the OS/browser
  drag-gesture level, so there's a narrow window where the two can briefly
  overlap before the clamp corrects it. `marks`/`orientation="vertical"`
  aren't supported in range mode.

  ## Orientation

  `orientation="vertical"` uses `writing-mode: vertical-lr` (Chromium/WebKit)
  plus the still-supported non-standard `-moz-orient: vertical`
  (Firefox) — the current cross-browser way to get a vertical native range
  input; there's no vendor-neutral standard property for this yet.

  ## Not implemented

  MUI's `valueLabelDisplay` (a tooltip that tracks the thumb's exact pixel
  position while dragging) and non-linear `scale` functions both need real
  per-frame JS computing pixel offsets or transforming displayed numbers —
  more than a "small inline snippet" can reasonably do without becoming a
  bespoke JS hook, which this library avoids. The always-visible
  `label`/current-value header serves the same purpose as
  `valueLabelDisplay="on"` without needing to track the thumb's position at
  all.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)

  attr(:value, :any,
    default: nil,
    doc: "a number, or a {low, high} tuple for a range slider"
  )

  attr(:min, :any, default: 0)
  attr(:max, :any, default: 100)
  attr(:step, :any, default: 1)
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary error))
  attr(:size, :string, default: "medium", values: ~w(medium small))
  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))

  attr(:track, :string,
    default: "normal",
    values: ~w(normal none inverted),
    doc:
      "none hides the filled segment; inverted fills from the thumb to max — ignored for range sliders"
  )

  attr(:marks, :any,
    default: false,
    doc: "true (tick every step), a list of values, or a list of {value, label} tuples"
  )

  attr(:label, :string, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form autofocus phx-change))

  def pp_slider(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:name, assigns.name || field.name)
    |> assign(:id, assigns.id || field.id)
    |> assign(:value, assigns.value || field.value)
    |> pp_slider()
  end

  def pp_slider(%{value: {_lo, _hi}} = assigns) do
    {lo, hi} = assigns.value

    assigns =
      assigns
      |> assign(:lo, lo)
      |> assign(:hi, hi)
      |> assign(:lo_percent, percent(lo, assigns.min, assigns.max))
      |> assign(:hi_percent, percent(hi, assigns.min, assigns.max))

    ~H"""
    <div data-pp-component="slider" class={Helpers.classes(@paperize, "flex flex-col gap-1", @class)}>
      <div :if={@label} class="flex items-center justify-between text-sm">
        <span>{@label}</span>
        <span class="tabular-nums opacity-70">{@lo} – {@hi}</span>
      </div>
      <div class="relative flex h-5 items-center">
        <div class={Helpers.classes(@paperize, "pointer-events-none absolute h-1 rounded-full bg-pp-outline/40 inset-x-0", nil)} />
        <div
          data-pp-slider-between
          class={Helpers.classes(@paperize, ["pointer-events-none absolute h-1 rounded-full", between_classes(@color)], nil)}
          style={"left: #{@lo_percent}%; right: #{100 - @hi_percent}%"}
        />
        <input
          type="range"
          name={@name && "#{@name}_min"}
          value={@lo}
          min={@min}
          max={@max}
          step={@step}
          disabled={@disabled}
          style={"--pp-slider-percent: #{@lo_percent}%"}
          oninput={range_sync_script()}
          class={
            Helpers.classes(
              @paperize,
              [
                "pointer-events-none absolute inset-x-0 [&::-webkit-slider-thumb]:pointer-events-auto [&::-moz-range-thumb]:pointer-events-auto",
                slider_shape_classes(@size, "horizontal"),
                color_classes(@color),
                "pp-slider-range-input"
              ],
              nil
            )
          }
          {@rest}
        />
        <input
          type="range"
          name={@name && "#{@name}_max"}
          value={@hi}
          min={@min}
          max={@max}
          step={@step}
          disabled={@disabled}
          style={"--pp-slider-percent: #{@hi_percent}%"}
          oninput={range_sync_script()}
          class={
            Helpers.classes(
              @paperize,
              [
                "pointer-events-none absolute inset-x-0 [&::-webkit-slider-thumb]:pointer-events-auto [&::-moz-range-thumb]:pointer-events-auto",
                slider_shape_classes(@size, "horizontal"),
                color_classes(@color),
                "pp-slider-range-input"
              ],
              nil
            )
          }
          {@rest}
        />
      </div>
    </div>
    """
  end

  def pp_slider(assigns) do
    assigns =
      assigns
      |> assign(:value, assigns.value || midpoint(assigns.min, assigns.max))
      |> then(fn assigns ->
        assign(assigns, :percent, percent(assigns.value, assigns.min, assigns.max))
      end)
      |> assign(:mark_values, mark_values(assigns.marks, assigns.min, assigns.max, assigns.step))
      |> assign(:labeled_marks, labeled_marks(assigns.marks))
      |> assign_new(:datalist_id, fn ->
        assigns.marks &&
          "#{assigns.id || assigns.name || System.unique_integer([:positive])}-marks"
      end)

    ~H"""
    <div data-pp-component="slider" class={Helpers.classes(@paperize, "flex flex-col gap-1", @class)}>
      <div :if={@label} class="flex items-center justify-between text-sm">
        <span>{@label}</span>
        <span class="tabular-nums opacity-70">{@value}</span>
      </div>
      <input
        type="range"
        id={@id}
        name={@name}
        value={@value}
        min={@min}
        max={@max}
        step={@step}
        disabled={@disabled}
        list={@datalist_id}
        style={"--pp-slider-percent: #{@percent}%"}
        oninput={percent_sync_script()}
        class={
          Helpers.classes(
            @paperize,
            [
              slider_shape_classes(@size, @orientation),
              color_classes(@color),
              track_classes(@track)
            ],
            nil
          )
        }
        {@rest}
      />
      <datalist :if={@marks} id={@datalist_id}>
        <option :for={v <- @mark_values} value={v} />
      </datalist>
      <div :if={@labeled_marks != [] and @orientation == "horizontal"} class="relative mt-1 h-4 text-xs text-pp-outline">
        <span
          :for={{v, text} <- @labeled_marks}
          class="absolute -translate-x-1/2"
          style={"left: #{percent(v, @min, @max)}%"}
        >
          {text}
        </span>
      </div>
    </div>
    """
  end

  defp slider_shape_classes("medium", "horizontal"), do: "pp-slider"
  defp slider_shape_classes("small", "horizontal"), do: "pp-slider-small"
  defp slider_shape_classes("medium", "vertical"), do: "pp-slider-vertical"
  defp slider_shape_classes("small", "vertical"), do: "pp-slider-vertical-small"

  defp color_classes("primary"), do: "pp-slider-primary"
  defp color_classes("secondary"), do: "pp-slider-secondary"
  defp color_classes("tertiary"), do: "pp-slider-tertiary"
  defp color_classes("error"), do: "pp-slider-error"

  defp track_classes("normal"), do: ""
  defp track_classes("none"), do: "pp-slider-track-none"
  defp track_classes("inverted"), do: "pp-slider-track-inverted"

  defp between_classes("primary"), do: "bg-pp-primary"
  defp between_classes("secondary"), do: "bg-pp-secondary"
  defp between_classes("tertiary"), do: "bg-pp-tertiary"
  defp between_classes("error"), do: "bg-pp-error"

  defp percent(value, min, max) do
    v = to_float(value)
    lo = to_float(min)
    hi = to_float(max)

    ((v - lo) / (hi - lo) * 100)
    |> max(0.0)
    |> min(100.0)
  end

  defp midpoint(min, max) do
    lo = to_float(min)
    hi = to_float(max)
    trunc((lo + hi) / 2)
  end

  defp to_float(value) do
    {f, _} = value |> to_string() |> Float.parse()
    f
  end

  defp mark_values(true, min, max, step) do
    lo = to_float(min)
    hi = to_float(max)
    s = to_float(step)

    Stream.iterate(lo, &(&1 + s)) |> Enum.take_while(&(&1 <= hi))
  end

  defp mark_values(marks, _min, _max, _step) when is_list(marks) do
    Enum.map(marks, fn
      {v, _label} -> v
      v -> v
    end)
  end

  defp mark_values(_marks, _min, _max, _step), do: []

  defp labeled_marks(marks) when is_list(marks), do: Enum.filter(marks, &match?({_v, _label}, &1))
  defp labeled_marks(_marks), do: []

  defp percent_sync_script do
    "this.style.setProperty('--pp-slider-percent',((this.value-this.min)/(this.max-this.min)*100)+'%')"
  end

  defp range_sync_script do
    """
    (function(el){
      var root=el.closest('[data-pp-component="slider"]');
      var inputs=root.querySelectorAll('input[type="range"]');
      var lo=inputs[0],hi=inputs[1];
      if(parseFloat(lo.value)>parseFloat(hi.value)){
        if(el===lo){lo.value=hi.value;}else{hi.value=lo.value;}
      }
      var min=parseFloat(lo.min),max=parseFloat(hi.max);
      var loPct=(parseFloat(lo.value)-min)/(max-min)*100;
      var hiPct=(parseFloat(hi.value)-min)/(max-min)*100;
      lo.style.setProperty('--pp-slider-percent',loPct+'%');
      hi.style.setProperty('--pp-slider-percent',hiPct+'%');
      var between=root.querySelector('[data-pp-slider-between]');
      between.style.left=loPct+'%';
      between.style.right=(100-hiPct)+'%';
    })(this)
    """
  end
end
