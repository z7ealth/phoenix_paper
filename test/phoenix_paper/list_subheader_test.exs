defmodule PhoenixPaper.ListSubheaderTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.ListSubheader

  test "renders the label with uppercase small-caps styling" do
    html = render_component(&subheader/1)

    assert html =~ "uppercase"
    assert html =~ "Main"
  end

  defp subheader(assigns) do
    ~H"""
    <.pp_list_subheader>Main</.pp_list_subheader>
    """
  end
end
