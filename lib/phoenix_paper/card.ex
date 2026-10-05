defmodule PhoenixPaper.Card do
  @moduledoc """
  An MD3 card (`pp_card/1`): `PhoenixPaper.Paper` plus padding and
  optional media/title/subhead/actions slots.

      <.pp_card variant="filled">
        <:media><img src={~p"/images/lake.jpg"} alt="" class="h-40 w-full object-cover" /></:media>
        <:title>Lake trip</:title>
        <:subhead>3 days · 4 people</:subhead>
        Pack light; the cabin has everything else.
        <:actions><.pp_button variant="text">Share</.pp_button></:actions>
      </.pp_card>

  ## Variants

  | `variant` | surface |
  |-----------|---------|
  | `elevated` (default) | `surface-container-low`, level-1 shadow |
  | `filled` | `surface-container-highest`, no shadow |
  | `outlined` | `surface` with an `outline-variant` border |

  Corners default to `:md` (12dp, MD3's card shape). `:media` renders
  edge to edge above the padded content and is clipped to the card's
  corners. The title is `title-large`, the subhead `body-medium` in
  `on-surface-variant`. `padding` (a `PhoenixPaper.Spacing` token) is the
  content padding.

  0.3's `elevation` attr is gone: MD3 fixes each variant's elevation.

  ## Link mode

  Pass `href`, `navigate` or `patch` and the card's title and body become
  one `Phoenix.Component.link/1` — MUI's `CardActionArea`. It gets the
  MD3 hover state layer (and the elevated card rises to level 2), a focus ring, and a ripple on click (`ripple`, default `true`, the
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
  attr(:variant, :string, default: "elevated", values: ~w(elevated filled outlined))
  attr(:padding, :atom, default: :md, values: ~w(none xs sm md lg xl 2xl)a)

  attr(:shape, :atom,
    default: :md,
    values: PhoenixPaper.Shape.tokens(),
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:href, :any, default: nil, doc: "makes the media, title and body a link")
  attr(:navigate, :any, default: nil, doc: "like href, a LiveView live navigation")
  attr(:patch, :any, default: nil, doc: "like href, a LiveView live patch")
  attr(:target, :string, default: nil, doc: "link mode: the link's target, e.g. _blank")
  attr(:rel, :string, default: nil, doc: "link mode: the link's rel, e.g. noopener")

  attr(:ripple, :boolean,
    default: true,
    doc: "the ripple on click in link mode — off whenever paperize is false"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:media, doc: "full-bleed media above the content (an image, a video)")
  slot(:title)
  slot(:subhead)
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
      color={surface(@variant)}
      elevation={elevation(@variant)}
      outlined={@variant == "outlined"}
      shape={@shape}
      paperize={@paperize}
      component="card"
      class={[@media != [] && "overflow-hidden", @class]}
      {@rest}
    >
      <div :if={@media != []} data-pp-card-media>{render_slot(@media)}</div>
      <div class={Helpers.classes(@paperize, Spacing.padding(@padding), nil)}>
        {card_heading(assigns)}
        {render_slot(@inner_block)}
        <div :if={@actions != []} class="mt-4 flex flex-wrap items-center justify-end gap-2">
          {render_slot(@actions)}
        </div>
      </div>
    </.pp_paper>
    <.pp_paper
      :if={@linked?}
      color={surface(@variant)}
      elevation={elevation(@variant)}
      outlined={@variant == "outlined"}
      shape={@shape}
      paperize={@paperize}
      component="card"
      class={[
        "relative",
        Helpers.classes(@paperize, ["overflow-hidden pp-motion-effects-default", hover_lift(@variant)], @class)
      ]}
      {@rest}
    >
      <.link
        href={@href}
        navigate={@navigate}
        patch={@patch}
        target={@target}
        rel={@rel}
        data-pp-card-action-area
        class={[stretch_classes(), Helpers.classes(@paperize, action_area_classes(), nil)]}
        onclick={Ripple.on_click(@ripple?)}
      >
        <div :if={@media != []} data-pp-card-media>{render_slot(@media)}</div>
        <div class={Helpers.classes(@paperize, Spacing.padding(@padding), nil)}>
          {card_heading(assigns)}
          {render_slot(@inner_block)}
        </div>
      </.link>

      <div
        :if={@actions != []}
        data-pp-card-actions
        class={[
          actions_layer_classes(),
          Helpers.classes(
            @paperize,
            ["flex flex-wrap items-center justify-end gap-2 !pt-0", Spacing.padding(@padding)],
            nil
          )
        ]}
      >
        {render_slot(@actions)}
      </div>
    </.pp_paper>
    """
  end

  defp card_heading(assigns) do
    ~H"""
    <div :if={@title != [] or @subhead != []} class="mb-2 flex flex-col gap-0.5">
      <div :if={@title != []} class={Helpers.classes(@paperize, "pp-title-large", nil)}>
        {render_slot(@title)}
      </div>
      <div
        :if={@subhead != []}
        class={Helpers.classes(@paperize, "pp-body-medium text-pp-on-surface-variant", nil)}
      >
        {render_slot(@subhead)}
      </div>
    </div>
    """
  end

  defp surface("elevated"), do: "surface-container-low"
  defp surface("filled"), do: "surface-container-highest"
  defp surface("outlined"), do: "surface"

  defp elevation("elevated"), do: 1
  defp elevation(_variant), do: 0

  # An elevated card rises a level while its link is hovered; the others
  # keep MD3's flat look and only show the state layer.
  defp hover_lift("elevated"), do: "has-[[data-pp-card-action-area]:hover]:pp-elevation-2"
  defp hover_lift(_variant), do: nil

  # The "stretched link": the link's ::after covers the whole card (the
  # root is `relative`), so the card is clickable everywhere, actions row
  # included. Unconditional like Menu's positioning — it defines what's
  # clickable, it isn't skin.
  defp stretch_classes do
    "block after:absolute after:inset-0 after:content-['']"
  end

  # The state layer and focus ring are painted on that same ::after
  # overlay, so they cover the whole card too. The layer is a translucent
  # background (not `opacity`, which would fade the ring with it), and the
  # ring is inset, since the root's `overflow-hidden` clips anything
  # outside it.
  defp action_area_classes do
    "text-inherit no-underline outline-none after:rounded-[inherit] after:transition-colors hover:after:bg-current/8 focus-visible:after:bg-current/10 active:after:bg-current/10 focus-visible:after:outline-3 focus-visible:after:-outline-offset-3 focus-visible:after:outline-solid focus-visible:after:outline-pp-secondary"
  end

  # The actions row sits above the overlay (`relative z-10`) so its own
  # buttons get their clicks, but ignores the pointer itself so a click in
  # the gaps between buttons falls through to the overlay and follows the
  # card's link.
  defp actions_layer_classes do
    "relative z-10 pointer-events-none [&>*]:pointer-events-auto"
  end
end
