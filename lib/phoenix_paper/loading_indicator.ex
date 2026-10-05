defmodule PhoenixPaper.LoadingIndicator do
  @moduledoc """
  The M3 Expressive loading indicator (`pp_loading_indicator/1`): a shape
  that morphs through MD3's shape library while it spins, for waits too
  short for a progress bar (pull to refresh, a card's content loading).

      <.pp_loading_indicator label="Loading messages" />
      <.pp_loading_indicator contained />

  48dp by default (`size` in px). `contained` sets it on a
  `primary-container` circle, for indicators floating over content.
  `color` swaps the shape's role (`primary` default; the contained one
  uses `on-primary-container`).

  ## How it animates

  CSS: the shape is one SVG path whose `d` is animated through seven
  shapes (all sampled as the same 72-point polygon, so they interpolate),
  each step on the Expressive fast spatial spring, while the SVG rotates.
  Chromium and Firefox animate `d` in CSS; Safari doesn't, so it shows
  a rotating soft burst there. With the PhoenixPaper JS hook (see
  `PhoenixPaper.Helpers.hook/1`) and an `id`, the hook morphs the path
  itself, which works everywhere.

  For a determinate wait, or one longer than a few seconds, use
  `PhoenixPaper.Progress`.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  @first_shape "M24.00 5.00 L25.60 5.69 L26.95 7.29 L28.08 8.76 L29.35 9.29 L31.05 8.88 L33.07 8.29 L34.88 8.46 L35.95 9.75 L36.21 11.79 L36.22 13.75 L36.76 15.07 L38.21 15.80 L40.19 16.45 L41.76 17.54 L42.13 19.14 L41.31 20.95 L40.10 22.59 L39.55 24.00 L40.10 25.41 L41.31 27.05 L42.13 28.86 L41.76 30.46 L40.19 31.55 L38.21 32.20 L36.76 32.93 L36.22 34.25 L36.21 36.21 L35.95 38.25 L34.88 39.54 L33.07 39.71 L31.05 39.12 L29.35 38.71 L28.08 39.24 L26.95 40.71 L25.60 42.31 L24.00 43.00 L22.40 42.31 L21.05 40.71 L19.92 39.24 L18.65 38.71 L16.95 39.12 L14.93 39.71 L13.12 39.54 L12.05 38.25 L11.79 36.21 L11.78 34.25 L11.24 32.93 L9.79 32.20 L7.81 31.55 L6.24 30.46 L5.87 28.86 L6.69 27.05 L7.90 25.41 L8.45 24.00 L7.90 22.59 L6.69 20.95 L5.87 19.14 L6.24 17.54 L7.81 16.45 L9.79 15.80 L11.24 15.07 L11.78 13.75 L11.79 11.79 L12.05 9.75 L13.12 8.46 L14.93 8.29 L16.95 8.88 L18.65 9.29 L19.92 8.76 L21.05 7.29 L22.40 5.69 Z"

  attr(:size, :integer, default: 48, doc: "px")
  attr(:contained, :boolean, default: false)
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary))
  attr(:label, :string, default: "Loading", doc: "aria-label")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders a loading indicator. See the module doc."
  def pp_loading_indicator(assigns) do
    assigns = assign(assigns, :first_shape, @first_shape)

    ~H"""
    <span
      role="progressbar"
      aria-label={@label}
      data-pp-component="loading-indicator"
      phx-hook={Helpers.hook(@rest[:id])}
      class={Helpers.classes(@paperize, container_classes(@contained, @color), @class)}
      style={"width: #{@size}px; height: #{@size}px"}
      {@rest}
    >
      <svg viewBox="0 0 48 48" class="pp-loading-rotate size-[79%]" aria-hidden="true">
        <path d={@first_shape} fill="currentColor" class="pp-loading-morph" />
      </svg>
    </span>
    """
  end

  defp container_classes(false, color),
    do: ["inline-flex items-center justify-center", text(color)]

  defp container_classes(true, _color),
    do:
      "inline-flex items-center justify-center rounded-pp-full bg-pp-primary-container text-pp-on-primary-container"

  defp text("primary"), do: "text-pp-primary"
  defp text("secondary"), do: "text-pp-secondary"
  defp text("tertiary"), do: "text-pp-tertiary"
end
