defmodule PhoenixPaper.Card do
  @moduledoc """
  A Material Design card (`pp_card/1`): `PhoenixPaper.Paper` (the surface)
  plus padding and optional title/actions slots.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Spacing}
  import PhoenixPaper.Paper, only: [pp_paper: 1]

  attr(:paperize, :boolean, default: true)
  attr(:elevation, :integer, default: 1)
  attr(:padding, :atom, default: :md, values: ~w(none xs sm md lg xl 2xl)a)

  attr(:shape, :atom,
    default: :lg,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:title)
  slot(:actions)
  slot(:inner_block, required: true)

  @doc "Renders a card. See the module doc."
  def pp_card(assigns) do
    ~H"""
    <.pp_paper
      elevation={@elevation}
      shape={@shape}
      paperize={@paperize}
      component="card"
      class={Helpers.classes(@paperize, Spacing.padding(@padding), @class)}
      {@rest}
    >
      <div :if={@title != []} class="mb-2 text-lg font-medium">
        {render_slot(@title)}
      </div>

      {render_slot(@inner_block)}

      <div :if={@actions != []} class="mt-4 flex items-center justify-end gap-2">
        {render_slot(@actions)}
      </div>
    </.pp_paper>
    """
  end
end
