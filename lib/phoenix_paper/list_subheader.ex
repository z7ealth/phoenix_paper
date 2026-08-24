defmodule PhoenixPaper.ListSubheader do
  @moduledoc """
  A small section label (`pp_list_subheader/1`) for grouping items inside a
  `PhoenixPaper.List` (e.g. "Main", "Account").
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a list subheader. See the module doc."
  def pp_list_subheader(assigns) do
    ~H"""
    <div
      data-pp-component="list-subheader"
      class={Helpers.classes(@paperize, "px-4 pb-1 pt-3 text-xs font-medium uppercase tracking-wide text-pp-outline", @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
