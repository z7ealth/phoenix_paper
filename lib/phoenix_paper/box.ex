defmodule PhoenixPaper.Box do
  @moduledoc """
  A generic layout container (`pp_box/1`), in the spirit of MUI's
  [`Box`](https://mui.com/material-ui/react-box/) — a bare `<div>` (or
  `<span>` via `tag="span"`) that exists purely to hold a `class`, not to
  apply any visual style of its own.

  Unlike every other PhoenixPaper component, `pp_box/1` has **no
  `paperize` attribute** — there's no "paper" skin to strip, since it never
  applies one in the first place. It's a layout primitive, not a styled
  component; see AGENTS.md, "Component conventions".
  """
  use Phoenix.Component

  attr(:tag, :string, default: "div", values: ~w(div span))
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a bare container. See the module doc."
  def pp_box(assigns) do
    ~H"""
    <div :if={@tag == "div"} data-pp-component="box" class={@class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    <span :if={@tag == "span"} data-pp-component="box" class={@class} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
