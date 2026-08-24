defmodule PhoenixPaper.List do
  @moduledoc """
  A Material Design list container (`pp_list/1`) — a vertical stack of
  `PhoenixPaper.ListItem`s (and optionally `PhoenixPaper.ListSubheader`/
  `PhoenixPaper.Divider`).

      <.pp_list>
        <.pp_list_subheader>Main</.pp_list_subheader>
        <.pp_list_item navigate={~p"/"}>Home</.pp_list_item>
        <.pp_list_item navigate={~p"/inbox"}>Inbox</.pp_list_item>
        <.pp_divider />
        <.pp_list_subheader>Account</.pp_list_subheader>
        <.pp_list_item navigate={~p"/settings"}>Settings</.pp_list_item>
      </.pp_list>

  Renders `role="list"` on a `<div>` rather than `<ul>`/`<li>` so items are
  free to render as `<a>`, `<button>`, or `<div>` depending on their own
  attrs (see `PhoenixPaper.ListItem`) without fighting list-item content
  model rules.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a list. See the module doc."
  def pp_list(assigns) do
    ~H"""
    <div
      role="list"
      data-pp-component="list"
      class={Helpers.classes(@paperize, "flex flex-col py-1", @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
