defmodule PhoenixPaper.Backdrop do
  @moduledoc """
  A full-screen dimming overlay (`pp_backdrop/1`), in the spirit of MUI's
  `Backdrop` — most often used behind a full-page loading spinner, or as the
  piece `PhoenixPaper.Dialog` composes for its own overlay.

      <.pp_backdrop open={@loading}>
        <span class="inline-block size-10 animate-spin rounded-full border-4 border-white border-t-transparent" />
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
      class={Helpers.classes(@paperize, "fixed inset-0 z-40 flex items-center justify-center bg-black/50", @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
