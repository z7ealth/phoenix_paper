defmodule PhoenixPaper.Slider do
  @moduledoc """
  An MD3 slider (`pp_slider/1`), with the M3 Expressive sizes, centered
  slider and value indicator — built on native `<input type="range">`.

      <.pp_slider name="volume" value={60} label="Volume" />
      <.pp_slider name="balance" value={0} min={-50} max={50} track="centered" />
      <.pp_slider name="price" value={{20, 80}} label="Price" value_indicator />

  ## Look

  The current MD3 slider: a thick rounded track — the active part in
  `color`, the inactive part in its container role (`secondary-container`
  for `primary`) — a 4dp bar handle that narrows to 2dp while pressed,
  6dp gaps on each side of the handle, and a 4dp stop indicator at the
  end of the inactive track (`stop_indicator={false}` drops it). The
  handle has MD3's focus ring when focused by keyboard.

  `size` (Expressive) is the track thickness: `xs` (16dp, default — the
  baseline MD3 slider), `sm` (24dp), `md` (40dp), `lg` (56dp), `xl`
  (96dp); the handle grows with it.

  `track` is `normal` (active from the start), `inverted` (active from the
  handle to the end), `centered` (Expressive: active between the center
  and the handle — for values around a midpoint) or `none` (no active
  segment). Range sliders always fill between their handles.

  `value_indicator` shows the Expressive value bubble (an
  `inverse-surface` pill above the handle) while dragging or focused.
  `label` adds a header row with the label and the current value.

  ## Marks

  `marks={true}` adds a stop at every `step`; `marks={[10, 50, 90]}` at
  specific values; `marks={[{0, "0°C"}, {100, "100°C"}]}` with labels
  under the track. They're also a native `<datalist>`, so the handle
  snaps near them.

  ## Range sliders

  A `{low, high}` tuple as `value` renders two handles, submitted as
  `"\#{name}_min"`/`"\#{name}_max"`. It's two overlapping native inputs
  whose tracks are transparent and whose thumbs alone take the pointer; an
  inline `oninput` snippet clamps a handle dragged past the other (after
  the fact — the usual limitation of this technique). No `marks`,
  `orientation` or `track` in range mode.

  ## How it stays in sync

  The visible track is a separate element painted by one CSS gradient
  from custom properties on the wrapper (`--pp-slider-f`, or `-lo`/`-hi`),
  set for the first paint by the server and on every `input` event by a
  small inline script (which also updates the value text). No hook. See
  the slider section of `phoenix_paper.css`.

  ## Orientation

  `orientation="vertical"` (single sliders) runs bottom to top, using
  `writing-mode: vertical-lr` plus Firefox's `-moz-orient`. Give the
  slider a height via `class` (default `h-48`).

  ## Migrating from 0.3

  `size` `medium`/`small` → `xs`..`xl`, `color="accent"` → `tertiary`,
  `track` gains `centered`. Ticks are now MD3 stop dots on the track.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: nil, doc: "a number, or a {low, high} tuple for a range slider")
  attr(:min, :any, default: 0)
  attr(:max, :any, default: 100)
  attr(:step, :any, default: 1)
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary error))
  attr(:size, :string, default: "xs", values: ~w(xs sm md lg xl))
  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))
  attr(:track, :string, default: "normal", values: ~w(normal inverted centered none))
  attr(:stop_indicator, :boolean, default: true)
  attr(:value_indicator, :boolean, default: false, doc: "Expressive value bubble while dragging")

  attr(:marks, :any,
    default: false,
    doc: "true (every step), a list of values, or a list of {value, label} tuples"
  )

  attr(:label, :string, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form autofocus))

  @doc "Renders a slider. See the module doc."
  def pp_slider(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:name, assigns.name || field.name)
    |> assign(:id, assigns.id || field.id)
    |> assign(:value, assigns.value || field.value)
    |> pp_slider()
  end

  def pp_slider(%{value: {lo, hi}} = assigns) do
    assigns =
      assigns
      |> assign(:lo, lo)
      |> assign(:hi, hi)
      |> assign(:lo_f, fraction(lo, assigns.min, assigns.max))
      |> assign(:hi_f, fraction(hi, assigns.min, assigns.max))
      |> assign(:sync_js, range_sync_script())

    ~H"""
    <div data-pp-component="slider" class={Helpers.classes(@paperize, "flex flex-col gap-2", @class)}>
      <div :if={@label} class={Helpers.classes(@paperize, header_classes(), nil)}>
        <span>{@label}</span>
        <span class="tabular-nums" data-pp-slider-current>{@lo} – {@hi}</span>
      </div>
      <div
        class={["group/slider relative flex items-center", Helpers.classes(@paperize, [size_vars(@size), color_vars(@color), "has-[:disabled]:opacity-38"], nil)]}
        style={"--pp-slider-lo: #{@lo_f}; --pp-slider-hi: #{@hi_f}"}
      >
        <div :if={@paperize} class={["pp-slider-track-shape pp-slider-track-range", !@stop_indicator && "pp-slider-no-stop"]} />
        <input
          :for={{bound, value, suffix} <- [{:lo, @lo, "_min"}, {:hi, @hi, "_max"}]}
          type="range"
          id={@id && "#{@id}#{suffix}"}
          name={@name && "#{@name}#{suffix}"}
          value={value}
          min={@min}
          max={@max}
          step={@step}
          disabled={@disabled}
          aria-label={@label && "#{@label} (#{bound_label(bound)})"}
          data-pp-slider-bound={bound}
          oninput={@sync_js}
          class={[
            "absolute inset-x-0",
            Helpers.classes(@paperize, "pp-slider-input pp-slider-input-range", nil)
          ]}
          {@rest}
        />
        <span
          :for={{bound, value} <- [{"lo", @lo}, {"hi", @hi}]}
          :if={@value_indicator && @paperize}
          data-pp-slider-value={bound}
          class={value_indicator_classes(bound)}
        >
          {value}
        </span>
      </div>
    </div>
    """
  end

  def pp_slider(%{orientation: "vertical"} = assigns) do
    assigns =
      assigns
      |> assign(:value, assigns.value || midpoint(assigns.min, assigns.max))
      |> then(&assign(&1, :f, fraction(&1.value, &1.min, &1.max)))
      |> assign(:sync_js, sync_script())

    ~H"""
    <div data-pp-component="slider" class={Helpers.classes(@paperize, "inline-flex flex-col items-center gap-2", @class)}>
      <div :if={@label} class={Helpers.classes(@paperize, header_classes(), nil)}>
        <span>{@label}</span>
        <span class="tabular-nums" data-pp-slider-current>{@value}</span>
      </div>
      <div
        class={["relative flex h-48 justify-center", Helpers.classes(@paperize, [size_vars(@size), color_vars(@color), "has-[:disabled]:opacity-38"], nil)]}
        style={"--pp-slider-f: #{@f}"}
      >
        <div :if={@paperize} class="pp-slider-track-vertical" />
        <input
          type="range"
          id={@id}
          name={@name}
          value={@value}
          min={@min}
          max={@max}
          step={@step}
          disabled={@disabled}
          aria-label={@label}
          oninput={@sync_js}
          class={["relative", Helpers.classes(@paperize, "pp-slider-input-vertical", nil)]}
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
      |> then(&assign(&1, :f, fraction(&1.value, &1.min, &1.max)))
      |> assign(:mark_values, mark_values(assigns.marks, assigns.min, assigns.max, assigns.step))
      |> assign(:labeled_marks, labeled_marks(assigns.marks))
      |> assign(:sync_js, sync_script())
      |> then(fn a ->
        assign(
          a,
          :datalist_id,
          a.marks && "#{a.id || a.name || System.unique_integer([:positive])}-marks"
        )
      end)

    ~H"""
    <div data-pp-component="slider" class={Helpers.classes(@paperize, "flex flex-col gap-2", @class)}>
      <div :if={@label} class={Helpers.classes(@paperize, header_classes(), nil)}>
        <span>{@label}</span>
        <span class="tabular-nums" data-pp-slider-current>{@value}</span>
      </div>
      <div
        class={["group/slider relative flex items-center", Helpers.classes(@paperize, [size_vars(@size), color_vars(@color), "has-[:disabled]:opacity-38"], nil)]}
        style={"--pp-slider-f: #{@f}"}
      >
        <div :if={@paperize} class={["pp-slider-track-shape", track_mode(@track), !@stop_indicator && "pp-slider-no-stop"]}>
          <span
            :for={v <- @mark_values}
            class="absolute top-1/2 size-1 -translate-x-1/2 -translate-y-1/2 rounded-full bg-pp-on-secondary-container/70"
            style={"left: calc(2px + (100% - 4px) * #{fraction(v, @min, @max)})"}
          />
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
          aria-label={@label}
          oninput={@sync_js}
          class={["relative", Helpers.classes(@paperize, "pp-slider-input", nil)]}
          {@rest}
        />
        <span :if={@value_indicator && @paperize} data-pp-slider-value class={value_indicator_classes("f")}>
          {@value}
        </span>
      </div>
      <datalist :if={@marks} id={@datalist_id}>
        <option :for={v <- @mark_values} value={v} />
      </datalist>
      <div
        :if={@labeled_marks != []}
        class={Helpers.classes(@paperize, "relative h-4 pp-label-medium text-pp-on-surface-variant", nil)}
      >
        <span
          :for={{v, text} <- @labeled_marks}
          class="absolute -translate-x-1/2"
          style={"left: calc(2px + (100% - 4px) * #{fraction(v, @min, @max)})"}
        >
          {text}
        </span>
      </div>
    </div>
    """
  end

  defp header_classes, do: "flex items-center justify-between pp-label-large text-pp-on-surface"

  defp bound_label(:lo), do: "minimum"
  defp bound_label(:hi), do: "maximum"

  defp track_mode("normal"), do: "pp-slider-track-normal"
  defp track_mode("inverted"), do: "pp-slider-track-inverted"
  defp track_mode("centered"), do: "pp-slider-track-centered"
  defp track_mode("none"), do: "pp-slider-track-none"

  # Track thickness, handle height and inactive-track corner radius per
  # Expressive size.
  defp size_vars("xs"),
    do: "[--pp-slider-track-size:16px] [--pp-slider-handle:44px] [--pp-slider-radius:8px]"

  defp size_vars("sm"),
    do: "[--pp-slider-track-size:24px] [--pp-slider-handle:44px] [--pp-slider-radius:8px]"

  defp size_vars("md"),
    do: "[--pp-slider-track-size:40px] [--pp-slider-handle:52px] [--pp-slider-radius:12px]"

  defp size_vars("lg"),
    do: "[--pp-slider-track-size:56px] [--pp-slider-handle:68px] [--pp-slider-radius:16px]"

  defp size_vars("xl"),
    do: "[--pp-slider-track-size:96px] [--pp-slider-handle:108px] [--pp-slider-radius:28px]"

  defp color_vars("primary"),
    do:
      "[--pp-slider-active:var(--color-pp-primary)] [--pp-slider-inactive:var(--color-pp-secondary-container)]"

  defp color_vars("secondary"),
    do:
      "[--pp-slider-active:var(--color-pp-secondary)] [--pp-slider-inactive:var(--color-pp-secondary-container)]"

  defp color_vars("tertiary"),
    do:
      "[--pp-slider-active:var(--color-pp-tertiary)] [--pp-slider-inactive:var(--color-pp-tertiary-container)]"

  defp color_vars("error"),
    do:
      "[--pp-slider-active:var(--color-pp-error)] [--pp-slider-inactive:var(--color-pp-error-container)]"

  # The Expressive value bubble: above the handle, shown while the slider
  # is pressed or keyboard-focused.
  defp value_indicator_classes(bound) do
    [
      "pointer-events-none absolute bottom-full mb-1 inline-flex h-11 min-w-12 -translate-x-1/2 scale-75 items-center justify-center rounded-pp-full bg-pp-inverse-surface px-4 pp-label-large text-pp-inverse-on-surface opacity-0 pp-motion-spatial-fast",
      "group-has-[:active]/slider:scale-100 group-has-[:active]/slider:opacity-100 group-has-[:focus-visible]/slider:scale-100 group-has-[:focus-visible]/slider:opacity-100",
      bubble_left(bound)
    ]
  end

  defp bubble_left("f"), do: "left-[calc(2px+(100%-4px)*var(--pp-slider-f))]"
  defp bubble_left("lo"), do: "left-[calc(2px+(100%-4px)*var(--pp-slider-lo))]"
  defp bubble_left("hi"), do: "left-[calc(2px+(100%-4px)*var(--pp-slider-hi))]"

  defp fraction(value, min, max) do
    lo = to_float(min)
    hi = to_float(max)

    ((to_float(value) - lo) / (hi - lo))
    |> max(0.0)
    |> min(1.0)
    |> Float.round(4)
  end

  defp midpoint(min, max), do: trunc((to_float(min) + to_float(max)) / 2)

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

  defp sync_script do
    "var w=this.parentNode;w.style.setProperty('--pp-slider-f',(this.value-this.min)/(this.max-this.min));var b=w.querySelector('[data-pp-slider-value]');if(b)b.textContent=this.value;var c=this.closest('[data-pp-component=slider]').querySelector('[data-pp-slider-current]');if(c)c.textContent=this.value;"
  end

  defp range_sync_script do
    "var w=this.parentNode;var lo=w.querySelector('[data-pp-slider-bound=lo]'),hi=w.querySelector('[data-pp-slider-bound=hi]');if(parseFloat(lo.value)>parseFloat(hi.value)){if(this===lo){lo.value=hi.value}else{hi.value=lo.value}}var min=parseFloat(lo.min),max=parseFloat(lo.max);w.style.setProperty('--pp-slider-lo',(lo.value-min)/(max-min));w.style.setProperty('--pp-slider-hi',(hi.value-min)/(max-min));var bl=w.querySelector('[data-pp-slider-value=lo]'),bh=w.querySelector('[data-pp-slider-value=hi]');if(bl)bl.textContent=lo.value;if(bh)bh.textContent=hi.value;var c=this.closest('[data-pp-component=slider]').querySelector('[data-pp-slider-current]');if(c)c.textContent=lo.value+' – '+hi.value;"
  end
end
