defmodule PhoenixPaper.Progress do
  @moduledoc """
  MD3 progress indicators (`pp_progress/1`) — linear or circular,
  determinate or indeterminate, flat or M3 Expressive wavy.

      <.pp_progress value={72} label="Uploading" />
      <.pp_progress label="Loading" />
      <.pp_progress variant="circular" value={72} label="Uploading" />
      <.pp_progress variant="circular" wavy label="Loading" />

  `value` (0-100) makes it determinate; `nil` (default) is indeterminate.
  `label` is the progressbar's accessible name.

  ## Look

  The current MD3 spec: a `primary` active indicator and a
  `secondary-container` track separated by a small gap, rounded ends,
  and — on determinate linear indicators — a 4dp stop dot at the track's
  end (`stop_indicator={false}` drops it). `color` swaps the indicator's
  role (`primary`, `secondary`, `tertiary`, `error`).

  M3 Expressive adds:

  - `wavy`: the active indicator is a traveling sine wave (the track stays
    flat). CSS only — a masked box, see `phoenix_paper.css`.
  - `thickness`: `4` (default) or `8` dp.

  Circular indicators are `size` px across (default 40). Determinate
  circular is a real SVG arc with the gap computed from `value`; the
  wavy ring is a precomputed SVG path, so nothing is computed per frame.

  ## Migrating from 0.3

  `color="accent"` → `tertiary`. Indeterminate circular is now an SVG arc
  rather than a bordered spinner. For the Expressive loading indicator
  (a morphing shape), see `PhoenixPaper.LoadingIndicator`.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)
  attr(:variant, :string, default: "linear", values: ~w(linear circular))
  attr(:value, :integer, default: nil, doc: "0-100, nil for indeterminate")
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary error))
  attr(:wavy, :boolean, default: false, doc: "M3 Expressive wavy active indicator")
  attr(:thickness, :integer, default: 4, values: [4, 8])
  attr(:stop_indicator, :boolean, default: true, doc: "determinate linear only")
  attr(:size, :integer, default: 40, doc: "circular only — diameter in pixels")
  attr(:label, :string, default: nil, doc: "aria-label")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders a progress indicator. See the module doc."
  def pp_progress(%{variant: "linear"} = assigns) do
    assigns = assign(assigns, :value, clamp(assigns.value))

    ~H"""
    <div
      role="progressbar"
      aria-label={@label}
      aria-valuenow={@value}
      aria-valuemin="0"
      aria-valuemax="100"
      data-pp-component="progress"
      data-pp-variant="linear"
      class={Helpers.classes(@paperize, linear_container(@value, @wavy, @thickness), @class)}
      {@rest}
    >
      <%= if @value do %>
        <div
          :if={@value > 0}
          class={Helpers.classes(@paperize, [linear_indicator(@wavy, @thickness), bg(@color)], nil)}
          style={"flex: 0 1 #{@value}%"}
        />
        <div
          :if={@value < 100}
          class={Helpers.classes(@paperize, linear_track(@thickness), nil)}
        >
          <span
            :if={@stop_indicator}
            class={Helpers.classes(@paperize, ["absolute end-0 top-1/2 size-1 -translate-y-1/2 rounded-pp-full", bg(@color)], nil)}
          />
        </div>
      <% else %>
        <div :if={@wavy} class={Helpers.classes(@paperize, wavy_indeterminate_track(@thickness), nil)} />
        <div class={Helpers.classes(@paperize, [segment(1, @wavy, @thickness), bg(@color)], nil)} />
        <div class={Helpers.classes(@paperize, [segment(2, @wavy, @thickness), bg(@color)], nil)} />
      <% end %>
    </div>
    """
  end

  def pp_progress(assigns) do
    assigns =
      assigns
      |> assign(:value, clamp(assigns.value))
      |> assign(:geometry, circular_geometry(assigns.thickness, assigns.wavy))

    ~H"""
    <svg
      role="progressbar"
      aria-label={@label}
      aria-valuenow={@value}
      aria-valuemin="0"
      aria-valuemax="100"
      data-pp-component="progress"
      data-pp-variant="circular"
      viewBox="0 0 48 48"
      width={@size}
      height={@size}
      class={Helpers.classes(@paperize, [text(@color), !@value && "pp-circular-rotate"], @class)}
      {@rest}
    >
      <%= if @value do %>
        <circle
          :for={track <- circular_track(@geometry, @value)}
          cx="24"
          cy="24"
          r={@geometry.r}
          fill="none"
          stroke-width={@geometry.stroke}
          stroke-linecap="round"
          transform="rotate(-90 24 24)"
          class={@paperize && "stroke-pp-secondary-container"}
          stroke-dasharray={track.dasharray}
          stroke-dashoffset={track.dashoffset}
        />
        <circle
          :if={!@wavy && @value > 0}
          cx="24"
          cy="24"
          r={@geometry.r}
          fill="none"
          stroke="currentColor"
          stroke-width={@geometry.stroke}
          stroke-linecap="round"
          transform="rotate(-90 24 24)"
          stroke-dasharray={"#{arc(@geometry.r, @value)} #{circumference(@geometry.r)}"}
          style="transition: stroke-dasharray 300ms cubic-bezier(0.2, 0, 0, 1)"
        />
        <path
          :if={@wavy && @value > 0}
          d={@geometry.wave}
          fill="none"
          stroke="currentColor"
          stroke-width={@geometry.stroke}
          stroke-linecap="round"
          stroke-linejoin="round"
          pathLength="100"
          stroke-dasharray={"#{@value} 100"}
          style="transition: stroke-dasharray 300ms cubic-bezier(0.2, 0, 0, 1)"
        />
      <% else %>
        <circle
          :if={!@wavy}
          cx="24"
          cy="24"
          r={@geometry.r}
          fill="none"
          stroke="currentColor"
          stroke-width={@geometry.stroke}
          stroke-linecap="round"
          class="pp-circular-dash"
          style="transform-origin: center"
        />
        <path
          :if={@wavy}
          d={@geometry.wave}
          fill="none"
          stroke="currentColor"
          stroke-width={@geometry.stroke}
          stroke-linecap="round"
          stroke-linejoin="round"
          pathLength="126"
          class="pp-circular-dash"
        />
      <% end %>
    </svg>
    """
  end

  defp clamp(nil), do: nil
  defp clamp(value), do: value |> max(0) |> min(100)

  # ---- linear ----

  defp linear_container(nil, false, 4),
    do: "relative h-1 w-full overflow-hidden rounded-pp-full bg-pp-secondary-container"

  defp linear_container(nil, false, 8),
    do: "relative h-2 w-full overflow-hidden rounded-pp-full bg-pp-secondary-container"

  defp linear_container(nil, true, 4), do: "relative h-[10px] w-full overflow-hidden"
  defp linear_container(nil, true, 8), do: "relative h-[14px] w-full overflow-hidden"
  defp linear_container(_value, false, 4), do: "flex h-1 w-full items-center gap-1"
  defp linear_container(_value, false, 8), do: "flex h-2 w-full items-center gap-1"
  defp linear_container(_value, true, 4), do: "flex h-[10px] w-full items-center gap-1"
  defp linear_container(_value, true, 8), do: "flex h-[14px] w-full items-center gap-1"

  defp linear_indicator(false, 4),
    do: "h-1 min-w-1 rounded-pp-full transition-[flex-basis] duration-300 ease-pp-standard"

  defp linear_indicator(false, 8),
    do: "h-2 min-w-2 rounded-pp-full transition-[flex-basis] duration-300 ease-pp-standard"

  defp linear_indicator(true, 4),
    do: "pp-progress-wave min-w-1 transition-[flex-basis] duration-300 ease-pp-standard"

  defp linear_indicator(true, 8),
    do: "pp-progress-wave-thick min-w-2 transition-[flex-basis] duration-300 ease-pp-standard"

  defp linear_track(4),
    do: "relative h-1 min-w-0 flex-1 rounded-pp-full bg-pp-secondary-container"

  defp linear_track(8),
    do: "relative h-2 min-w-0 flex-1 rounded-pp-full bg-pp-secondary-container"

  defp wavy_indeterminate_track(4),
    do:
      "absolute inset-x-0 top-1/2 h-1 -translate-y-1/2 rounded-pp-full bg-pp-secondary-container"

  defp wavy_indeterminate_track(8),
    do:
      "absolute inset-x-0 top-1/2 h-2 -translate-y-1/2 rounded-pp-full bg-pp-secondary-container"

  defp segment(1, false, _t), do: "absolute inset-y-0 rounded-pp-full pp-progress-indeterminate-1"
  defp segment(2, false, _t), do: "absolute inset-y-0 rounded-pp-full pp-progress-indeterminate-2"

  defp segment(1, true, 4),
    do: "absolute top-0 pp-progress-wave-mask pp-progress-wave-indeterminate-1"

  defp segment(2, true, 4),
    do: "absolute top-0 pp-progress-wave-mask pp-progress-wave-indeterminate-2"

  defp segment(1, true, 8),
    do: "absolute top-0 pp-progress-wave-mask-thick pp-progress-wave-indeterminate-1"

  defp segment(2, true, 8),
    do: "absolute top-0 pp-progress-wave-mask-thick pp-progress-wave-indeterminate-2"

  defp bg("primary"), do: "bg-pp-primary"
  defp bg("secondary"), do: "bg-pp-secondary"
  defp bg("tertiary"), do: "bg-pp-tertiary"
  defp bg("error"), do: "bg-pp-error"

  defp text("primary"), do: "text-pp-primary"
  defp text("secondary"), do: "text-pp-secondary"
  defp text("tertiary"), do: "text-pp-tertiary"
  defp text("error"), do: "text-pp-error"

  # ---- circular ----

  # The wavy ring's path is computed once, at compile time: 10 waves of
  # 1.6 amplitude around the base radius, starting at 12 o'clock.
  @wave_count 10
  @wave_amplitude 1.6

  wave_path = fn base_r ->
    points =
      for i <- 0..240 do
        theta = 2 * :math.pi() * i / 240
        rr = base_r + @wave_amplitude * :math.sin(@wave_count * theta)
        x = 24 + rr * :math.sin(theta)
        y = 24 - rr * :math.cos(theta)
        "#{Float.round(x, 2)} #{Float.round(y, 2)}"
      end

    "M" <> Enum.join(points, " L") <> " Z"
  end

  @wave_thin wave_path.(18.0)
  @wave_thick wave_path.(16.0)

  defp circular_geometry(4, false), do: %{r: 20, stroke: 4, wave: nil}
  defp circular_geometry(8, false), do: %{r: 18, stroke: 8, wave: nil}
  defp circular_geometry(4, true), do: %{r: 18, stroke: 4, wave: @wave_thin}
  defp circular_geometry(8, true), do: %{r: 16, stroke: 8, wave: @wave_thick}

  defp circumference(r), do: Float.round(2 * :math.pi() * r, 3)
  defp arc(r, value), do: Float.round(circumference(r) * value / 100, 3)

  # The track arc runs from just after the indicator to just before it,
  # leaving a gap of 4 + stroke (round caps reach stroke/2 past each end).
  defp circular_track(%{r: r, stroke: stroke}, value) do
    c = circumference(r)
    ind = arc(r, value)
    gap = 4 + stroke

    cond do
      value == 0 ->
        [%{dasharray: nil, dashoffset: nil}]

      value >= 100 ->
        []

      c - ind - 2 * gap <= 0 ->
        []

      true ->
        [%{dasharray: "#{Float.round(c - ind - 2 * gap, 3)} #{c}", dashoffset: "#{-(ind + gap)}"}]
    end
  end
end
