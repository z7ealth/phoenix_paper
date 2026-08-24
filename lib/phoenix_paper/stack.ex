defmodule PhoenixPaper.Stack do
  @moduledoc """
  A one-dimensional flex layout (`pp_stack/1`), in the spirit of MUI's
  [`Stack`](https://mui.com/material-ui/react-stack/) — arranges children in
  a row or column with consistent spacing between them.

  There's no `divider` slot to auto-interleave a `PhoenixPaper.Divider`
  between every child (MUI's `divider` prop) — a stateless function
  component only gets one opaque `inner_block` slot, it can't see individual
  children to insert between them. Add `<.pp_divider />` between children
  yourself where you want one.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Spacing}

  attr(:direction, :string, default: "column", values: ~w(row column))
  attr(:spacing, :atom, default: :md, values: ~w(none xs sm md lg xl 2xl)a)
  attr(:wrap, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a stack. See the module doc."
  def pp_stack(assigns) do
    ~H"""
    <div
      data-pp-component="stack"
      class={Helpers.classes(@paperize, paper_classes(@direction, @spacing, @wrap), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp paper_classes(direction, spacing, wrap) do
    ["flex", direction_class(direction), Spacing.gap(spacing), wrap_class(wrap)]
  end

  defp direction_class("row"), do: "flex-row"
  defp direction_class("column"), do: "flex-col"

  defp wrap_class(true), do: "flex-wrap"
  defp wrap_class(false), do: ""
end
