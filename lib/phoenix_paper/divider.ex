defmodule PhoenixPaper.Divider do
  @moduledoc """
  A thin separator line (`pp_divider/1`) — most often used between sections
  of a `PhoenixPaper.List`.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:inset, :boolean,
    default: false,
    doc: "indent past a leading icon/avatar column instead of spanning full width"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders a divider. See the module doc."
  def pp_divider(assigns) do
    ~H"""
    <hr data-pp-component="divider" class={Helpers.classes(@paperize, paper_classes(@inset), @class)} {@rest} />
    """
  end

  defp paper_classes(false), do: "my-1 border-t border-pp-outline/20"
  defp paper_classes(true), do: "my-1 ml-14 border-t border-pp-outline/20"
end
