defmodule PhoenixPaper.Progress do
  @moduledoc """
  A Material progress indicator (`pp_progress/1`) — `variant="linear"`
  (MUI's `LinearProgress`) or `variant="circular"` (MUI's
  `CircularProgress`), combined into one component since they share the
  same `value`/`color` contract.

      <.pp_progress value={72} />
      <.pp_progress />
      <.pp_progress variant="circular" value={72} />
      <.pp_progress variant="circular" />

  `value` nil (the default) renders the indeterminate/animated form — an
  unknown-duration loading state, the same distinction `PhoenixPaper.Button`'s
  `loading` makes. Circular determinate is a real SVG arc (`stroke-dasharray`/
  `stroke-dashoffset` computed from `value` — plain numeric `style`, not a
  Tailwind class, so the "no dynamic Tailwind classes" rule doesn't apply to
  it); circular indeterminate reuses the same bordered-circle
  `animate-spin` trick as `Button`'s loading spinner instead of a second SVG,
  since an indeterminate ring doesn't need to represent a real percentage.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)
  attr(:variant, :string, default: "linear", values: ~w(linear circular))
  attr(:value, :integer, default: nil, doc: "0-100, nil for indeterminate (animated)")
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary error))
  attr(:size, :integer, default: 40, doc: "circular only — diameter in pixels")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders a progress indicator. See the module doc."
  def pp_progress(assigns) do
    ~H"""
    <div
      :if={@variant == "linear"}
      role="progressbar"
      aria-valuenow={@value}
      aria-valuemin="0"
      aria-valuemax="100"
      data-pp-component="progress"
      data-pp-variant="linear"
      class={Helpers.classes(@paperize, track_classes(@color), @class)}
      {@rest}
    >
      <div class={Helpers.classes(@paperize, bar_classes(@color, @value), nil)} style={bar_style(@value)} />
    </div>

    <svg
      :if={@variant == "circular" && @value}
      role="progressbar"
      aria-valuenow={@value}
      aria-valuemin="0"
      aria-valuemax="100"
      data-pp-component="progress"
      data-pp-variant="circular"
      class={Helpers.classes(@paperize, circular_classes(@color), @class)}
      viewBox="0 0 44 44"
      width={@size}
      height={@size}
      {@rest}
    >
      <circle cx="22" cy="22" r="20" fill="none" stroke="currentColor" stroke-width="4" opacity="0.2" />
      <circle
        cx="22"
        cy="22"
        r="20"
        fill="none"
        stroke="currentColor"
        stroke-width="4"
        stroke-linecap="round"
        transform="rotate(-90 22 22)"
        style={circular_arc_style(@value)}
      />
    </svg>

    <span
      :if={@variant == "circular" && !@value}
      role="progressbar"
      data-pp-component="progress"
      data-pp-variant="circular"
      class={Helpers.classes(@paperize, indeterminate_circular_classes(@color), @class)}
      style={"width: #{@size}px; height: #{@size}px"}
      {@rest}
    />
    """
  end

  @circumference 2 * :math.pi() * 20

  defp circular_arc_style(value) do
    offset = @circumference * (1 - value / 100)

    "stroke-dasharray: #{@circumference}; stroke-dashoffset: #{offset}; transition: stroke-dashoffset 300ms ease"
  end

  defp bar_style(nil), do: nil
  defp bar_style(value), do: "width: #{value}%"

  defp track_classes("primary"), do: "h-1 w-full overflow-hidden rounded-full bg-pp-primary/20"

  defp track_classes("secondary"),
    do: "h-1 w-full overflow-hidden rounded-full bg-pp-secondary/20"

  defp track_classes("tertiary"), do: "h-1 w-full overflow-hidden rounded-full bg-pp-tertiary/20"
  defp track_classes("error"), do: "h-1 w-full overflow-hidden rounded-full bg-pp-error/20"

  defp bar_classes("primary", nil),
    do: "h-full w-1/3 rounded-full bg-pp-primary pp-progress-indeterminate"

  defp bar_classes("secondary", nil),
    do: "h-full w-1/3 rounded-full bg-pp-secondary pp-progress-indeterminate"

  defp bar_classes("tertiary", nil),
    do: "h-full w-1/3 rounded-full bg-pp-tertiary pp-progress-indeterminate"

  defp bar_classes("error", nil),
    do: "h-full w-1/3 rounded-full bg-pp-error pp-progress-indeterminate"

  defp bar_classes("primary", _value),
    do: "h-full rounded-full bg-pp-primary transition-[width] duration-300"

  defp bar_classes("secondary", _value),
    do: "h-full rounded-full bg-pp-secondary transition-[width] duration-300"

  defp bar_classes("tertiary", _value),
    do: "h-full rounded-full bg-pp-tertiary transition-[width] duration-300"

  defp bar_classes("error", _value),
    do: "h-full rounded-full bg-pp-error transition-[width] duration-300"

  defp circular_classes("primary"), do: "text-pp-primary"
  defp circular_classes("secondary"), do: "text-pp-secondary"
  defp circular_classes("tertiary"), do: "text-pp-tertiary"
  defp circular_classes("error"), do: "text-pp-error"

  defp indeterminate_circular_classes("primary"),
    do:
      "inline-block animate-spin rounded-full border-4 border-current text-pp-primary border-t-transparent"

  defp indeterminate_circular_classes("secondary"),
    do:
      "inline-block animate-spin rounded-full border-4 border-current text-pp-secondary border-t-transparent"

  defp indeterminate_circular_classes("tertiary"),
    do:
      "inline-block animate-spin rounded-full border-4 border-current text-pp-tertiary border-t-transparent"

  defp indeterminate_circular_classes("error"),
    do:
      "inline-block animate-spin rounded-full border-4 border-current text-pp-error border-t-transparent"
end
