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

  The **whole card** is the clickable area, actions row included: hover
  anywhere tints the whole card, a click anywhere that isn't an action
  button follows the link, and the focus ring outlines the whole card.
  The `:actions` markup still stays **outside** the `<a>` (a `<button>` or
  second link nested inside an `<a>` is invalid HTML): the link uses the
  "stretched link" technique instead, an `::after` overlay covering the
  whole card (`relative` root, `after:absolute after:inset-0`). The actions
  row sits above that overlay so its buttons keep their own clicks, and
  passes clicks in the gaps between buttons through to the overlay.

  `target` and `rel` are explicit attrs that go on the link (a card's
  other extra attrs land on its root `<div>`, where a `target` would do
  nothing):

      <.pp_card href="https://hexdocs.pm/phoenix_paper" target="_blank" rel="noopener">
        <:title>Docs</:title>
        Opens in a new tab.
      </.pp_card>

  In link mode the padding moves from the card root onto the link (and the
  actions row). The stretch itself is unconditional (it defines what's
  clickable); the tint, focus ring and ripple are paperize-gated as usual.
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
  attr(:target, :string, default: nil, doc: "link mode: the link's target, e.g. _blank")
  attr(:rel, :string, default: nil, doc: "link mode: the link's rel, e.g. noopener")

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
      class={["relative", Helpers.classes(@paperize, "overflow-hidden", @class)]}
      {@rest}
    >
      <.link
        href={@href}
        navigate={@navigate}
        patch={@patch}
        target={@target}
        rel={@rel}
        data-pp-card-action-area
        class={
          [
            stretch_classes(),
            Helpers.classes(@paperize, [action_area_classes(), Spacing.padding(@padding)], nil)
          ]
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
        data-pp-card-actions
        class={[
          actions_layer_classes(),
          Helpers.classes(
            @paperize,
            ["flex items-center justify-end gap-2 !pt-0", Spacing.padding(@padding)],
            nil
          )
        ]}
      >
        {render_slot(@actions)}
      </div>
    </.pp_paper>
    """
  end

  # The "stretched link": the link's ::after covers the whole card (the
  # root is `relative`), so the card is clickable everywhere, actions row
  # included. Unconditional like Menu's positioning — it defines what's
  # clickable, it isn't skin.
  defp stretch_classes do
    "block after:absolute after:inset-0 after:content-['']"
  end

  # The hover tint and focus ring are painted on that same ::after overlay,
  # so they cover the whole card too.
  defp action_area_classes do
    "text-inherit no-underline outline-none after:transition-colors hover:after:bg-pp-on-surface/5 focus-visible:after:bg-pp-on-surface/10 focus-visible:after:outline focus-visible:after:outline-2 focus-visible:after:-outline-offset-2 focus-visible:after:outline-pp-primary"
  end

  # The actions row sits above the overlay (`relative z-10`) so its own
  # buttons get their clicks, but ignores the pointer itself so a click in
  # the gaps between buttons falls through to the overlay and follows the
  # card's link.
  defp actions_layer_classes do
    "relative z-10 pointer-events-none [&>*]:pointer-events-auto"
  end
end
