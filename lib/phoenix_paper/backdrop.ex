defmodule PhoenixPaper.Backdrop do
  @moduledoc """
  A full-screen MD3 scrim (`pp_backdrop/1`, 32% `scrim`), in the spirit of MUI's
  `Backdrop` — most often used behind a full-page loading spinner, or as the
  piece `PhoenixPaper.Dialog` composes for its own overlay.

      <.pp_backdrop open={@loading}>
        <.pp_loading_indicator contained />
      </.pp_backdrop>

  Stateless: `open` just toggles rendering the overlay at all (`:if`, not a
  CSS class), so there's nothing to keep in sync client-side.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)
  attr(:open, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block)

  @doc "Renders a backdrop. See the module doc."
  def pp_backdrop(assigns) do
    ~H"""
    <div
      :if={@open}
      data-pp-component="backdrop"
      class={Helpers.classes(@paperize, "fixed inset-0 z-40 flex items-center justify-center bg-pp-scrim/32", @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
