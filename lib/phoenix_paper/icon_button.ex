defmodule PhoenixPaper.IconButton do
  @moduledoc """
  An MD3 icon button (`pp_icon_button/1`), with the M3 Expressive sizes,
  widths, shapes, shape morphing and toggle mode.

      <.pp_icon_button icon="hero-heart" label="Favorite" />
      <.pp_icon_button icon="hero-bookmark" label="Save" variant="tonal" toggle selected={false} />

  The icon is the `icon` attr (a `hero-*` name, see `PhoenixPaper.Icon`) or
  the inner block for anything else. `label` is required: it's the
  `aria-label` (an icon-only control has no other accessible name) and the
  native `title` tooltip — pass `title={false}` to drop the tooltip, or wrap
  the button in a `PhoenixPaper.Tooltip` for an MD3 plain tooltip.

  ## Variants

  | `variant` | look |
  |-----------|------|
  | `standard` (default) | no container, `on-surface-variant` icon |
  | `filled`  | `primary` container |
  | `tonal`   | `secondary-container` |
  | `outlined` | `outline-variant` border |

  `color` (`primary`, `secondary`, `tertiary`, `error`, `inherit`) swaps the
  role, like `PhoenixPaper.Button`'s. `inherit` is what to use on a
  colored surface — a vibrant toolbar, a filled card — where a fixed role
  could match the background.

  ## Size, width and shape (Expressive)

  `size` is `xs` (32dp), `sm` (40dp, default), `md` (56dp), `lg` (96dp)
  or `xl` (136dp). `width` is `narrow`, `default` or `wide` — the
  Expressive widths, so a row of icon buttons can show hierarchy. `shape`
  is `round` or `square`; pressing morphs the corners, and a selected
  toggle swaps round ↔ square, on the Expressive spatial spring.

  ## Toggle

  `selected`/`toggle`/`group`/`on_toggle` work exactly like
  `PhoenixPaper.Button`'s (see `PhoenixPaper.Toggle`); the selected colors
  are MD3's icon-button toggle colors (standard: icon turns `primary`;
  filled: `surface-container` → `primary`; tonal:
  `surface-container-highest` → `secondary-container`; outlined: border →
  `inverse-surface`). Pass `selected_icon` to swap the glyph too (MD3's
  outlined → filled icon pair):

      <.pp_icon_button icon="hero-star" selected_icon="hero-star-solid" label="Star" toggle selected={false} />
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Button, Helpers, Icon, Ripple, Toggle}

  attr(:icon, :string, default: nil, doc: "a hero-* icon name; or use the inner block")

  attr(:selected_icon, :string,
    default: nil,
    doc: "icon shown while a toggle is selected (MD3's filled glyph)"
  )

  attr(:label, :string, required: true, doc: "accessible name (aria-label) and title")
  attr(:title, :any, default: nil, doc: "native tooltip; defaults to label, false drops it")

  attr(:variant, :string, default: "standard", values: ~w(standard filled tonal outlined))

  attr(:color, :string,
    default: nil,
    values: [nil | ~w(primary secondary tertiary error inherit)],
    doc: "the role the variant is built on; unset uses MD3's default"
  )

  attr(:size, :string, default: "sm", values: ~w(xs sm md lg xl))
  attr(:width, :string, default: "default", values: ~w(narrow default wide))
  attr(:shape, :string, default: "round", values: ~w(round square))

  attr(:selected, :boolean, default: nil, doc: "makes it a toggle; the (initial) selected state")
  attr(:toggle, :boolean, default: false, doc: "flip selected on the client, no round trip")
  attr(:group, :string, default: nil, doc: "exclusive client-side toggle group name")
  attr(:on_toggle, JS, default: %JS{}, doc: "extra JS run after a client-side toggle")

  attr(:ripple, :boolean, default: true)

  attr(:position, :string,
    default: "relative",
    values: ~w(relative fixed absolute sticky),
    doc: "the root's CSS position; set it here, not via class"
  )

  attr(:disabled, :boolean, default: false)
  attr(:type, :string, default: "button", values: ~w(button submit reset))
  attr(:href, :any, default: nil, doc: "renders a link instead of a button")
  attr(:navigate, :any, default: nil)
  attr(:patch, :any, default: nil)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(form name value autofocus download hreflang referrerpolicy rel target method csrf_token replace)
  )

  slot(:inner_block, doc: "custom icon markup, instead of the icon attr")

  @doc "Renders an icon button. See the module doc."
  def pp_icon_button(assigns) do
    linked? =
      assigns.href not in [nil, false] or assigns.navigate not in [nil, false] or
        assigns.patch not in [nil, false]

    client_toggle? = not linked? and (assigns.toggle or assigns.group != nil)
    toggle? = not linked? and (client_toggle? or assigns.selected != nil)

    assigns =
      assigns
      |> assign(:linked?, linked?)
      |> assign(:toggle?, toggle?)
      |> assign(:client_toggle?, client_toggle?)
      |> assign(
        :title_text,
        if(assigns.title == false, do: nil, else: assigns.title || assigns.label)
      )
      |> assign(:ripple?, assigns.ripple and assigns.paperize and not assigns.disabled)

    ~H"""
    <.link
      :if={@linked?}
      href={@href}
      navigate={@navigate}
      patch={@patch}
      aria-label={@label}
      title={@title_text}
      aria-disabled={@disabled && "true"}
      data-pp-component="icon-button"
      data-pp-variant={@variant}
      class={Helpers.classes(@paperize, paper_classes(assigns, false), @class)}
      onclick={Ripple.on_click(@ripple?)}
      {@rest}
    >
      {icon_content(assigns)}
    </.link>
    <button
      :if={!@linked?}
      type={@type}
      disabled={@disabled}
      aria-label={@label}
      title={@title_text}
      aria-pressed={@toggle? && Toggle.aria_pressed(@selected, true)}
      data-pp-component="icon-button"
      data-pp-variant={@variant}
      data-pp-toggle-group={@group}
      class={Helpers.classes(@paperize, paper_classes(assigns, @toggle?), @class)}
      onclick={Ripple.on_click(@ripple?)}
      phx-click={@client_toggle? && Toggle.js(@group, @on_toggle)}
      {@rest}
    >
      {icon_content(assigns)}
    </button>
    """
  end

  defp icon_content(assigns) do
    ~H"""
    <Icon.pp_icon
      :if={@icon}
      name={@icon}
      size="none"
      class={["size-[1em]", @toggle? && @selected_icon && "[[aria-pressed=true]>&]:hidden"]}
    />
    <Icon.pp_icon
      :if={@toggle? && @selected_icon}
      name={@selected_icon}
      size="none"
      class="size-[1em] [[aria-pressed=false]>&]:hidden"
    />
    {render_slot(@inner_block)}
    """
  end

  defp paper_classes(assigns, toggle?) do
    [
      "inline-flex shrink-0 items-center justify-center cursor-pointer select-none pp-state-layer pp-focus-ring pp-motion-spatial-fast disabled:cursor-default disabled:pointer-events-none aria-disabled:pointer-events-none",
      size_classes(assigns.size, assigns.width),
      Button.shape_classes(assigns.size, assigns.shape, toggle?),
      if(toggle?,
        do: toggle_classes(assigns.variant),
        else: color_classes(assigns.variant, assigns.color)
      ),
      disabled_classes(assigns.variant),
      Ripple.container_classes(true, assigns.position)
    ]
  end

  # Height, Expressive width and icon size (as the root's font-size, which
  # the 1em icon follows) per size × width.
  defp size_classes("xs", "narrow"), do: "h-8 w-7 text-[20px]"
  defp size_classes("xs", "default"), do: "h-8 w-8 text-[20px]"
  defp size_classes("xs", "wide"), do: "h-8 w-10 text-[20px]"
  defp size_classes("sm", "narrow"), do: "h-10 w-8 text-[24px]"
  defp size_classes("sm", "default"), do: "h-10 w-10 text-[24px]"
  defp size_classes("sm", "wide"), do: "h-10 w-[52px] text-[24px]"
  defp size_classes("md", "narrow"), do: "h-14 w-12 text-[24px]"
  defp size_classes("md", "default"), do: "h-14 w-14 text-[24px]"
  defp size_classes("md", "wide"), do: "h-14 w-[72px] text-[24px]"
  defp size_classes("lg", "narrow"), do: "h-24 w-16 text-[32px]"
  defp size_classes("lg", "default"), do: "h-24 w-24 text-[32px]"
  defp size_classes("lg", "wide"), do: "h-24 w-32 text-[32px]"
  defp size_classes("xl", "narrow"), do: "h-[136px] w-[104px] text-[40px]"
  defp size_classes("xl", "default"), do: "h-[136px] w-[136px] text-[40px]"
  defp size_classes("xl", "wide"), do: "h-[136px] w-[184px] text-[40px]"

  defp color_classes("standard", nil), do: "text-pp-on-surface-variant"
  defp color_classes("standard", "primary"), do: "text-pp-primary"
  defp color_classes("standard", "secondary"), do: "text-pp-secondary"
  defp color_classes("standard", "tertiary"), do: "text-pp-tertiary"
  defp color_classes("standard", "error"), do: "text-pp-error"
  defp color_classes("standard", "inherit"), do: "text-inherit"

  defp color_classes("filled", nil), do: "bg-pp-primary text-pp-on-primary"
  defp color_classes("filled", "primary"), do: "bg-pp-primary text-pp-on-primary"
  defp color_classes("filled", "secondary"), do: "bg-pp-secondary text-pp-on-secondary"
  defp color_classes("filled", "tertiary"), do: "bg-pp-tertiary text-pp-on-tertiary"
  defp color_classes("filled", "error"), do: "bg-pp-error text-pp-on-error"
  defp color_classes("filled", "inherit"), do: "bg-current/12 text-inherit"

  defp color_classes("tonal", nil),
    do: "bg-pp-secondary-container text-pp-on-secondary-container"

  defp color_classes("tonal", "primary"),
    do: "bg-pp-primary-container text-pp-on-primary-container"

  defp color_classes("tonal", "secondary"),
    do: "bg-pp-secondary-container text-pp-on-secondary-container"

  defp color_classes("tonal", "tertiary"),
    do: "bg-pp-tertiary-container text-pp-on-tertiary-container"

  defp color_classes("tonal", "error"), do: "bg-pp-error-container text-pp-on-error-container"
  defp color_classes("tonal", "inherit"), do: "bg-current/12 text-inherit"

  defp color_classes("outlined", nil),
    do: "border border-pp-outline-variant text-pp-on-surface-variant"

  defp color_classes("outlined", "primary"),
    do: "border border-pp-outline-variant text-pp-primary"

  defp color_classes("outlined", "secondary"),
    do: "border border-pp-outline-variant text-pp-secondary"

  defp color_classes("outlined", "tertiary"),
    do: "border border-pp-outline-variant text-pp-tertiary"

  defp color_classes("outlined", "error"), do: "border border-pp-outline-variant text-pp-error"
  defp color_classes("outlined", "inherit"), do: "border border-current/40 text-inherit"

  defp toggle_classes("standard"),
    do: "text-pp-on-surface-variant aria-pressed:text-pp-primary"

  defp toggle_classes("filled"),
    do:
      "bg-pp-surface-container text-pp-primary aria-pressed:bg-pp-primary aria-pressed:text-pp-on-primary"

  defp toggle_classes("tonal"),
    do:
      "bg-pp-surface-container-highest text-pp-on-surface-variant aria-pressed:bg-pp-secondary-container aria-pressed:text-pp-on-secondary-container"

  defp toggle_classes("outlined"),
    do:
      "border border-pp-outline-variant text-pp-on-surface-variant aria-pressed:border-transparent aria-pressed:bg-pp-inverse-surface aria-pressed:text-pp-inverse-on-surface"

  defp disabled_classes("standard"),
    do: "disabled:text-pp-on-surface/38 aria-disabled:text-pp-on-surface/38"

  defp disabled_classes("outlined"),
    do:
      "disabled:border-pp-on-surface/12 disabled:text-pp-on-surface/38 aria-disabled:border-pp-on-surface/12 aria-disabled:text-pp-on-surface/38"

  defp disabled_classes(_filled),
    do:
      "disabled:bg-pp-on-surface/10 disabled:text-pp-on-surface/38 aria-disabled:bg-pp-on-surface/10 aria-disabled:text-pp-on-surface/38"
end
