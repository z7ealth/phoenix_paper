defmodule PhoenixPaper.Button do
  @moduledoc """
  A Material Design button (`pp_button/1`).

  Supports the five classic Material button variants: `raised`, `flat`,
  `outlined`, `text` and `icon`. Ripples on click/tap by default — see
  `PhoenixPaper.Ripple`, and `AGENTS.md` for the `paperize` contract shared
  by every PhoenixPaper component.

  `:start_icon`/`:end_icon` slots place an icon before/after the label —
  the same idea as MUI's `startIcon`/`endIcon` props, just a slot instead
  of a prop holding an element, since that's how HEEx passes arbitrary
  markup (see `PhoenixPaper.ListItem`'s `:leading`/`:trailing` for the same
  pattern elsewhere in this library):

      <.pp_button variant="outlined">
        <:start_icon><.pp_icon name="hero-trash" /></:start_icon>
        Delete
      </.pp_button>

  `loading` shows a spinner in the `:start_icon` position (replacing it,
  if both are given) and disables the button — no `loading_position`/
  overlay options like MUI's; this covers the common case without the
  complexity of the rest of that API.

  ## Link mode

  Pass `href`, `navigate` or `patch` and `pp_button/1` renders a
  `Phoenix.Component.link/1` (an `<a>`) instead of a `<button>`, keeping
  the exact same variants/colors/ripple — the same idea as MUI's `Button`
  taking an `href` (or `component={Link}`). Use it wherever the "button"
  is really navigation, so you don't end up nesting a real `<button>`
  inside an `<a>` (invalid HTML):

      <.pp_button href={~p"/issues"} variant="text">Issues</.pp_button>
      <.pp_button navigate={~p"/new"} variant="raised">New workbook</.pp_button>
      <.pp_button href={~p"/users/log_out"} method="delete" variant="text">
        Sign out
      </.pp_button>

  `type` is ignored in link mode (there's no form to submit); `disabled`
  still works — an `<a>` can't be natively disabled, so it renders
  `aria-disabled="true"` plus `pointer-events-none` and the same dimmed
  look. Any link-specific attr (`method`, `download`, `target`, `rel`, ...)
  passes straight through via the global `rest`.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers, Ripple, Shape}

  attr(:paperize, :boolean, default: true, doc: "apply PhoenixPaper's Material styling")
  attr(:variant, :string, default: "raised", values: ~w(raised flat outlined text icon))
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary error))
  attr(:elevation, :integer, default: nil, doc: "override the resting elevation (0-24)")

  attr(:shape, :atom,
    default: :full,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:ripple, :boolean,
    default: true,
    doc:
      "the Material ripple effect on click/tap — off whenever paperize is false, see PhoenixPaper.Ripple"
  )

  attr(:disabled, :boolean, default: false)

  attr(:loading, :boolean,
    default: false,
    doc: "shows a spinner in place of start_icon and disables the button"
  )

  attr(:type, :string, default: "button", values: ~w(button submit reset))

  attr(:href, :any,
    default: nil,
    doc: "renders an <a> (via Phoenix.Component.link/1) instead of a <button>"
  )

  attr(:navigate, :any, default: nil, doc: "like href, a LiveView live navigation")
  attr(:patch, :any, default: nil, doc: "like href, a LiveView live patch")

  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(form name value autofocus download hreflang referrerpolicy rel target method csrf_token replace)
  )

  slot(:start_icon, doc: "an icon before the label, replaced by the spinner when loading")
  slot(:end_icon, doc: "an icon after the label")
  slot(:inner_block, required: true)

  @doc "Renders a button. See the module doc for variants, colors, icons/loading, and link mode."
  def pp_button(assigns) do
    linked? =
      assigns.href not in [nil, false] or assigns.navigate not in [nil, false] or
        assigns.patch not in [nil, false]

    assigns =
      assigns
      |> assign(:linked?, linked?)
      |> assign(:inert?, assigns.disabled or assigns.loading)
      |> assign(
        :ripple?,
        assigns.ripple and assigns.paperize and not assigns.loading and not assigns.disabled
      )

    ~H"""
    <.link
      :if={@linked?}
      href={@href}
      navigate={@navigate}
      patch={@patch}
      aria-disabled={@inert? && "true"}
      aria-busy={to_string(@loading)}
      data-pp-component="button"
      data-pp-variant={@variant}
      class={
        Helpers.classes(
          @paperize,
          [paper_classes(@variant, @color, @elevation, @shape, @ripple?), inert_classes(@inert?)],
          @class
        )
      }
      onclick={Ripple.on_click(@ripple?)}
      {@rest}
    >
      {button_content(assigns)}
    </.link>
    <button
      :if={!@linked?}
      type={@type}
      disabled={@inert?}
      aria-busy={to_string(@loading)}
      data-pp-component="button"
      data-pp-variant={@variant}
      class={Helpers.classes(@paperize, paper_classes(@variant, @color, @elevation, @shape, @ripple?), @class)}
      onclick={Ripple.on_click(@ripple?)}
      {@rest}
    >
      {button_content(assigns)}
    </button>
    """
  end

  defp button_content(assigns) do
    ~H"""
    <span
      :if={@loading}
      class="inline-block size-4 shrink-0 animate-spin rounded-full border-2 border-current border-t-transparent"
    />
    <span :if={!@loading && @start_icon != []} class="inline-flex shrink-0 items-center">
      {render_slot(@start_icon)}
    </span>
    {render_slot(@inner_block)}
    <span :if={@end_icon != []} class="inline-flex shrink-0 items-center">
      {render_slot(@end_icon)}
    </span>
    """
  end

  # An `<a>` has no native `disabled`, so link mode reproduces the
  # `disabled:opacity-40 disabled:pointer-events-none` look from
  # `base_classes/1` (which only fires on a real `:disabled` element)
  # with always-on utilities instead, gated on the same `disabled || loading`.
  defp inert_classes(true), do: "pointer-events-none opacity-40"
  defp inert_classes(false), do: ""

  defp paper_classes(variant, color, elevation, shape, ripple) do
    [
      base_classes(variant),
      Shape.class(shape),
      color_classes(variant, color),
      elevation_classes(variant, elevation),
      Ripple.container_classes(ripple)
    ]
  end

  defp base_classes("icon") do
    "inline-flex items-center justify-center p-2 cursor-pointer transition-colors duration-150 ease-out select-none disabled:opacity-40 disabled:pointer-events-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
  end

  defp base_classes(_variant) do
    "inline-flex items-center justify-center gap-2 px-6 py-2.5 text-sm font-medium tracking-wide uppercase whitespace-nowrap cursor-pointer transition-[box-shadow,background-color,color,border-color] duration-150 ease-out select-none disabled:opacity-40 disabled:pointer-events-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
  end

  defp color_classes("raised", "primary"),
    do: "bg-pp-primary text-pp-on-primary focus-visible:outline-pp-primary"

  defp color_classes("raised", "secondary"),
    do: "bg-pp-secondary text-pp-on-secondary focus-visible:outline-pp-secondary"

  defp color_classes("raised", "tertiary"),
    do: "bg-pp-tertiary text-pp-on-tertiary focus-visible:outline-pp-tertiary"

  defp color_classes("raised", "error"),
    do: "bg-pp-error text-pp-on-error focus-visible:outline-pp-error"

  defp color_classes("flat", "primary"),
    do: "bg-pp-primary text-pp-on-primary focus-visible:outline-pp-primary"

  defp color_classes("flat", "secondary"),
    do: "bg-pp-secondary text-pp-on-secondary focus-visible:outline-pp-secondary"

  defp color_classes("flat", "tertiary"),
    do: "bg-pp-tertiary text-pp-on-tertiary focus-visible:outline-pp-tertiary"

  defp color_classes("flat", "error"),
    do: "bg-pp-error text-pp-on-error focus-visible:outline-pp-error"

  defp color_classes("outlined", "primary"),
    do:
      "bg-transparent text-pp-primary border border-pp-primary hover:bg-pp-primary/10 focus-visible:outline-pp-primary"

  defp color_classes("outlined", "secondary"),
    do:
      "bg-transparent text-pp-secondary border border-pp-secondary hover:bg-pp-secondary/10 focus-visible:outline-pp-secondary"

  defp color_classes("outlined", "tertiary"),
    do:
      "bg-transparent text-pp-tertiary border border-pp-tertiary hover:bg-pp-tertiary/10 focus-visible:outline-pp-tertiary"

  defp color_classes("outlined", "error"),
    do:
      "bg-transparent text-pp-error border border-pp-error hover:bg-pp-error/10 focus-visible:outline-pp-error"

  defp color_classes("text", "primary"),
    do: "bg-transparent text-pp-primary hover:bg-pp-primary/10 focus-visible:outline-pp-primary"

  defp color_classes("text", "secondary"),
    do:
      "bg-transparent text-pp-secondary hover:bg-pp-secondary/10 focus-visible:outline-pp-secondary"

  defp color_classes("text", "tertiary"),
    do:
      "bg-transparent text-pp-tertiary hover:bg-pp-tertiary/10 focus-visible:outline-pp-tertiary"

  defp color_classes("text", "error"),
    do: "bg-transparent text-pp-error hover:bg-pp-error/10 focus-visible:outline-pp-error"

  defp color_classes("icon", "primary"),
    do: "text-pp-primary hover:bg-pp-primary/10 focus-visible:outline-pp-primary"

  defp color_classes("icon", "secondary"),
    do: "text-pp-secondary hover:bg-pp-secondary/10 focus-visible:outline-pp-secondary"

  defp color_classes("icon", "tertiary"),
    do: "text-pp-tertiary hover:bg-pp-tertiary/10 focus-visible:outline-pp-tertiary"

  defp color_classes("icon", "error"),
    do: "text-pp-error hover:bg-pp-error/10 focus-visible:outline-pp-error"

  # Default elevation is only animated (hover boost) when the caller hasn't
  # pinned an explicit level — see the "Tailwind class safety" note in
  # AGENTS.md for why this is two literal branches instead of interpolation.
  defp elevation_classes("raised", nil), do: "pp-elevation-2 hover:pp-elevation-4"
  defp elevation_classes("raised", level), do: Elevation.class(level)
  defp elevation_classes(_variant, nil), do: ""
  defp elevation_classes(_variant, level), do: Elevation.class(level)
end
