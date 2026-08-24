defmodule PhoenixPaper.Typography do
  @moduledoc """
  Material's type scale (`pp_typography/1`) — `variant` picks both the
  rendered tag and the text classes, in the spirit of MUI's
  [`Typography`](https://mui.com/material-ui/react-typography/).

      <.pp_typography variant="h4">Account settings</.pp_typography>
      <.pp_typography variant="body1">Regular paragraph text.</.pp_typography>
      <.pp_typography variant="caption">Last updated 2 minutes ago</.pp_typography>
      <.pp_typography variant="code">mix phx.new my_app</.pp_typography>

  Unlike MUI's `Typography`, there's no `component` prop to override the
  tag independently of `variant` — HEEx can't parameterize a tag name (see
  AGENTS.md, "Conditional root tag"), and one attr driving both together
  keeps this to a single set of `:if` branches instead of the cross product
  of every variant with every possible tag. If you need a specific
  variant's styling on a different element, apply its classes yourself, or
  ask for the override to be added.

  | `variant`                          | tag      |
  |-------------------------------------|----------|
  | `h1` .. `h6`                        | `h1`..`h6` |
  | `subtitle1`, `subtitle2`, `body1`, `body2` | `p` |
  | `caption`, `overline`, `button`     | `span`   |
  | `code`                              | `code`   |
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:variant, :string,
    default: "body1",
    values: ~w(h1 h2 h3 h4 h5 h6 subtitle1 subtitle2 body1 body2 caption overline button code)
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders text styled by the type scale. See the module doc."
  def pp_typography(assigns) do
    ~H"""
    <h1 :if={@variant == "h1"} class={Helpers.classes(@paperize, variant_classes(@variant), @class)} {@rest}>{render_slot(@inner_block)}</h1>
    <h2 :if={@variant == "h2"} class={Helpers.classes(@paperize, variant_classes(@variant), @class)} {@rest}>{render_slot(@inner_block)}</h2>
    <h3 :if={@variant == "h3"} class={Helpers.classes(@paperize, variant_classes(@variant), @class)} {@rest}>{render_slot(@inner_block)}</h3>
    <h4 :if={@variant == "h4"} class={Helpers.classes(@paperize, variant_classes(@variant), @class)} {@rest}>{render_slot(@inner_block)}</h4>
    <h5 :if={@variant == "h5"} class={Helpers.classes(@paperize, variant_classes(@variant), @class)} {@rest}>{render_slot(@inner_block)}</h5>
    <h6 :if={@variant == "h6"} class={Helpers.classes(@paperize, variant_classes(@variant), @class)} {@rest}>{render_slot(@inner_block)}</h6>
    <p :if={@variant in ~w(subtitle1 subtitle2 body1 body2)} class={Helpers.classes(@paperize, variant_classes(@variant), @class)} {@rest}>{render_slot(@inner_block)}</p>
    <span :if={@variant in ~w(caption overline button)} class={Helpers.classes(@paperize, variant_classes(@variant), @class)} {@rest}>{render_slot(@inner_block)}</span>
    <code :if={@variant == "code"} class={Helpers.classes(@paperize, variant_classes(@variant), @class)} {@rest}>{render_slot(@inner_block)}</code>
    """
  end

  defp variant_classes("h1"), do: "text-5xl font-normal tracking-tight"
  defp variant_classes("h2"), do: "text-4xl font-normal tracking-tight"
  defp variant_classes("h3"), do: "text-3xl font-normal"
  defp variant_classes("h4"), do: "text-2xl font-medium"
  defp variant_classes("h5"), do: "text-xl font-medium"
  defp variant_classes("h6"), do: "text-lg font-medium"
  defp variant_classes("subtitle1"), do: "text-base font-medium"
  defp variant_classes("subtitle2"), do: "text-sm font-medium"
  defp variant_classes("body1"), do: "text-base font-normal"
  defp variant_classes("body2"), do: "text-sm font-normal"
  defp variant_classes("caption"), do: "text-xs font-normal text-pp-on-surface/70"
  defp variant_classes("overline"), do: "text-xs font-medium uppercase tracking-wide"
  defp variant_classes("button"), do: "text-sm font-medium uppercase tracking-wide"
  defp variant_classes("code"), do: "font-mono text-xs"
end
