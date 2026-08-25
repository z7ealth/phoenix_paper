defmodule PhoenixPaper.Skeleton do
  @moduledoc """
  A placeholder loading shape (`pp_skeleton/1`), in the spirit of MUI's
  `Skeleton` — a text line, a circular avatar outline, or a rectangular
  block, with a pulsing or shimmering animation while real content loads.

      <.pp_skeleton />
      <.pp_skeleton variant="circular" width={40} height={40} />
      <.pp_skeleton variant="rectangular" height={120} />
      <.pp_skeleton animation="wave" />
      <.pp_skeleton animation="none" />

  `width`/`height` accept a bare integer (read as pixels) or any CSS length
  string (e.g. `"100%"`, `"12rem"`) — rendered as inline `style`, not a
  Tailwind class, since arbitrary numbers can't be literal class names (see
  AGENTS.md's "Tailwind class safety").
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)
  attr(:variant, :string, default: "text", values: ~w(text circular rectangular rounded))
  attr(:width, :any, default: nil, doc: "an integer (px) or a CSS length string")
  attr(:height, :any, default: nil, doc: "an integer (px) or a CSS length string")
  attr(:animation, :string, default: "pulse", values: ~w(pulse wave none))
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders a skeleton placeholder. See the module doc."
  def pp_skeleton(assigns) do
    ~H"""
    <div
      aria-hidden="true"
      data-pp-component="skeleton"
      data-pp-variant={@variant}
      class={Helpers.classes(@paperize, paper_classes(@variant, @animation), @class)}
      style={dimension_style(@width, @height, @variant)}
      {@rest}
    />
    """
  end

  defp paper_classes(variant, animation) do
    ["block bg-pp-on-surface/10", shape_classes(variant), animation_classes(animation)]
  end

  defp shape_classes("text"), do: "rounded"
  defp shape_classes("circular"), do: "rounded-full"
  defp shape_classes("rectangular"), do: "rounded-none"
  defp shape_classes("rounded"), do: "rounded-lg"

  defp animation_classes("pulse"), do: "animate-pulse"
  defp animation_classes("wave"), do: "pp-skeleton-wave"
  defp animation_classes("none"), do: ""

  defp dimension_style(width, height, variant) do
    w = css_dimension(width || default_width(variant))
    h = css_dimension(height || default_height(variant))
    "width: #{w}; height: #{h}"
  end

  defp default_width("circular"), do: 40
  defp default_width(_variant), do: "100%"

  defp default_height("circular"), do: 40
  defp default_height("text"), do: "1.2em"
  defp default_height(_variant), do: 40

  defp css_dimension(value) when is_integer(value), do: "#{value}px"
  defp css_dimension(value), do: value
end
