defmodule PhoenixPaper.Card do
  @moduledoc """
  A Material Design card (`pp_card/1`): `PhoenixPaper.Paper` (the surface)
  plus padding and optional title/actions slots.

  ## Link mode

  Pass `href`, `navigate` or `patch` and the card's title and body become
  one `Phoenix.Component.link/1` — MUI's `CardActionArea`. It gets a hover
  tint, a focus ring, and a ripple on click (`ripple`, default `true`, the
  same as `PhoenixPaper.Button`/`PhoenixPaper.ListItem`):

      <.pp_card navigate={~p"/components/button"}>
        <:title>Button</:title>
        Raised, outlined, text and icon buttons.
      </.pp_card>

  The `:actions` slot stays **outside** the link, below it, the way MUI
  puts `CardActions` next to `CardActionArea` rather than inside it. A
  `<button>` or second link nested inside an `<a>` is invalid HTML, so
  this keeps action buttons usable on a linked card.

  In link mode the padding moves from the card root onto the link (and the
  actions row), so the hover tint and ripple fill the whole clickable area
  up to the card's rounded edge.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Ripple, Spacing}
  import PhoenixPaper.Paper, only: [pp_paper: 1]

  attr(:paperize, :boolean, default: true)
  attr(:elevation, :integer, default: 1)
  attr(:padding, :atom, default: :md, values: ~w(none xs sm md lg xl 2xl)a)

  attr(:shape, :atom,
    default: :lg,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:href, :any, default: nil, doc: "makes the title and body a link (MUI's CardActionArea)")
  attr(:navigate, :any, default: nil, doc: "like href, a LiveView live navigation")
  attr(:patch, :any, default: nil, doc: "like href, a LiveView live patch")

  attr(:ripple, :boolean,
    default: true,
    doc: "the Material ripple on click in link mode — off whenever paperize is false"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:title)
  slot(:actions)
  slot(:inner_block, required: true)

  @doc "Renders a card. See the module doc."
  def pp_card(assigns) do
    linked? =
      assigns.href not in [nil, false] or assigns.navigate not in [nil, false] or
        assigns.patch not in [nil, false]

    assigns =
      assigns
      |> assign(:linked?, linked?)
      |> assign(:ripple?, linked? and assigns.ripple and assigns.paperize)

    ~H"""
    <.pp_paper
      :if={!@linked?}
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
    <.pp_paper
      :if={@linked?}
      elevation={@elevation}
      shape={@shape}
      paperize={@paperize}
      component="card"
      class={Helpers.classes(@paperize, "overflow-hidden", @class)}
      {@rest}
    >
      <.link
        href={@href}
        navigate={@navigate}
        patch={@patch}
        data-pp-card-action-area
        class={
          Helpers.classes(
            @paperize,
            [action_area_classes(), Spacing.padding(@padding), Ripple.container_classes(@ripple?)],
            nil
          )
        }
        onclick={Ripple.on_click(@ripple?)}
      >
        <div :if={@title != []} class="mb-2 text-lg font-medium">
          {render_slot(@title)}
        </div>

        {render_slot(@inner_block)}
      </.link>

      <div
        :if={@actions != []}
        class={
          Helpers.classes(
            @paperize,
            ["flex items-center justify-end gap-2 !pt-0", Spacing.padding(@padding)],
            nil
          )
        }
      >
        {render_slot(@actions)}
      </div>
    </.pp_paper>
    """
  end

  defp action_area_classes do
    "block text-inherit no-underline transition-colors hover:bg-pp-on-surface/5 focus-visible:bg-pp-on-surface/10 focus-visible:outline focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-pp-primary"
  end
end
