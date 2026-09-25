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

  ## Use the attrs, not `class`, for direction and spacing

  `direction`, `spacing` and `wrap` each emit a built-in class
  (`flex-col`/`flex-row`, `gap-*`, `flex-wrap`). PhoenixPaper doesn't merge
  classes (see AGENTS.md, "Overriding built-in classes via `class`"), so
  `class="flex-row"` on a default (`direction="column"`) stack renders
  *both* `flex-col` and `flex-row`, and which one wins is down to
  Tailwind's stylesheet order, not your markup. Nothing warns you. Set the
  attr instead:

      <.pp_stack direction="row" spacing={:sm}>...</.pp_stack>

  | Instead of `class=`              | use                           |
  |----------------------------------|-------------------------------|
  | `flex-row` / `flex-col`          | `direction="row"` / `"column"` |
  | `gap-*`                          | `spacing={:xs .. :"2xl"}` (or `:none`) |
  | `flex-wrap`                      | `wrap`                        |

  Responsive changes (`md:flex-row`) have no attr; they add a *different*
  class rather than replacing one, so they're safe to pass in `class`.
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
