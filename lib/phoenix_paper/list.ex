defmodule PhoenixPaper.List do
  @moduledoc """
  An MD3 list (`pp_list/1`): a vertical run of `PhoenixPaper.ListItem`s,
  optionally separated by `PhoenixPaper.Divider`s.

      <.pp_list>
        <.pp_list_item navigate={~p"/"}>Home</.pp_list_item>
        <.pp_list_item navigate={~p"/inbox"}>Inbox</.pp_list_item>
        <.pp_divider />
        <.pp_list_item navigate={~p"/settings"}>Settings</.pp_list_item>
      </.pp_list>

  Renders `role="list"` on a `<div>` rather than `<ul>`/`<li>` so items are
  free to render as `<a>` or `<div>` depending on their own attrs (see
  `PhoenixPaper.ListItem`) without fighting list-item content model rules.
  The list adds MD3's 8dp top and bottom padding.

  ## Migrating from 0.4

  `dense`, `nested`, `inset` and `pp_list_group` are gone (MD3's list
  has none of them), and so is `PhoenixPaper.ListSubheader`.
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
      class={Helpers.classes(@paperize, "flex flex-col py-2", @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
