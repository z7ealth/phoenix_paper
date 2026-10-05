defmodule PhoenixPaper.Button do
  @moduledoc """
  An MD3 common button (`pp_button/1`), with the M3 Expressive sizes,
  shapes, shape morphing and toggle buttons.

      <.pp_button>Save</.pp_button>
      <.pp_button variant="tonal">
        <:start_icon><.pp_icon name="hero-plus" /></:start_icon>
        Add item
      </.pp_button>

  ## Variants

  | `variant`  | look |
  |------------|------|
  | `filled` (default) | `primary` container, highest emphasis |
  | `tonal`    | `secondary-container`, between filled and outlined |
  | `elevated` | `surface-container-low` with a level-1 shadow |
  | `outlined` | `outline-variant` border, no fill |
  | `text`     | no container, lowest emphasis |

  Icon-only buttons are `PhoenixPaper.IconButton` (`pp_icon_button/1`),
  not a `variant` here.

  `color` (`primary`, `secondary`, `tertiary`, `error`, `inherit`) swaps the
  role a variant is built on — `filled` + `tertiary` is
  `bg-pp-tertiary text-pp-on-tertiary`, `tonal` + `tertiary` is
  `tertiary-container`. Leave it unset for MD3's defaults (primary, or
  secondary for `tonal`). `inherit` takes the surrounding text color for
  `text`/`outlined` buttons sitting on a colored surface (a vibrant
  toolbar, a filled card); on a filled variant it's a translucent tint of
  that color.

  ## Size and shape (Expressive)

  `size` is `xs` (32dp), `sm` (40dp, default — the baseline MD3 button),
  `md` (56dp), `lg` (96dp) or `xl` (136dp); padding, label type role and
  icon size scale with it. `shape` is `round` (default, fully rounded) or
  `square` (12–28dp corners depending on size).

  The corners **morph**: pressing squeezes them to a smaller radius, and a
  selected toggle button swaps round ↔ square. The motion is the
  Expressive spatial spring (`pp-motion-spatial-fast`), so it overshoots
  slightly and settles. Round corners are an explicit radius (half the
  height) rather than `9999px`, so the morph animates instead of jumping.

  ## Toggle buttons

  Give a button `selected` (`true`/`false`) and it becomes an Expressive
  toggle button: `aria-pressed` is rendered, and the unselected/selected
  colors and the shape swap come from MD3's toggle spec rather than
  `color`. Two modes, see `PhoenixPaper.Toggle`:

      <%!-- controlled: the server owns the state --%>
      <.pp_button selected={@bold} phx-click="toggle_bold">Bold</.pp_button>

      <%!-- client-side: flips aria-pressed with no round trip --%>
      <.pp_button toggle selected={false} on_toggle={JS.push("bold_changed")}>Bold</.pp_button>

  `group` (inside a single-select `PhoenixPaper.ButtonGroup`) makes the
  client-side toggle exclusive across every button with the same group.
  `text` buttons have no toggle spec in MD3; they fall back to a primary
  label when selected.

  ## Icons and loading

  `:start_icon`/`:end_icon` place an icon before/after the label, sized to
  the button. `loading` shows a spinner in the `:start_icon` position and
  disables the button.

  ## Link mode

  Pass `href`, `navigate` or `patch` and `pp_button/1` renders a
  `Phoenix.Component.link/1` (an `<a>`) with the same look. `type` and the
  toggle attrs are ignored; `disabled` renders `aria-disabled="true"` and
  the same disabled colors (an `<a>` has no native `disabled`). Link attrs
  (`method`, `download`, `target`, `rel`, ...) pass through `rest`.

  ## Positioning

  The state layer and ripple need the button positioned, and Tailwind
  orders `.relative` after `.absolute`/`.fixed`, so `class="absolute ..."`
  would lose. Use `position` (offsets stay in `class`).

  ## Migrating from 0.3

  `raised` → `elevated`, `flat` → `filled`, `variant="icon"` →
  `pp_icon_button/1`, `color="accent"` → `tertiary`, `size` `small`/
  `medium`/`large` → `xs`/`sm`/`md`, `shape` atoms → `round`/`square`.
  `elevation` is gone: MD3 fixes each variant's elevation.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Helpers, Ripple, Toggle}

  attr(:paperize, :boolean, default: true, doc: "apply PhoenixPaper's Material styling")
  attr(:variant, :string, default: "filled", values: ~w(filled tonal elevated outlined text))

  attr(:color, :string,
    default: nil,
    values: [nil | ~w(primary secondary tertiary error inherit)],
    doc: "the role the variant is built on; unset uses MD3's default"
  )

  attr(:size, :string, default: "sm", values: ~w(xs sm md lg xl))
  attr(:shape, :string, default: "round", values: ~w(round square))

  attr(:selected, :boolean,
    default: nil,
    doc: "makes it a toggle button; true/false is the (initial) selected state"
  )

  attr(:toggle, :boolean,
    default: false,
    doc: "flip selected on the client with JS commands, no round trip"
  )

  attr(:group, :string,
    default: nil,
    doc: "exclusive client-side toggle across buttons sharing this name (implies toggle)"
  )

  attr(:on_toggle, JS,
    default: %JS{},
    doc: "extra JS run after a client-side toggle, e.g. JS.push(...)"
  )

  attr(:ripple, :boolean,
    default: true,
    doc: "the ripple on click/tap — off whenever paperize is false, see PhoenixPaper.Ripple"
  )

  attr(:position, :string,
    default: "relative",
    values: ~w(relative fixed absolute sticky),
    doc: "the root's CSS position; set it here, not via class"
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

  @doc "Renders a button. See the module doc."
  def pp_button(assigns) do
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
      aria-busy={@loading && "true"}
      data-pp-component="button"
      data-pp-variant={@variant}
      data-pp-size={@size}
      class={
        Helpers.classes(
          @paperize,
          paper_classes(@variant, @color, @size, @shape, false, @position),
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
      aria-busy={@loading && "true"}
      aria-pressed={@toggle? && Toggle.aria_pressed(@selected, true)}
      data-pp-component="button"
      data-pp-variant={@variant}
      data-pp-size={@size}
      data-pp-toggle-group={@group}
      class={
        Helpers.classes(
          @paperize,
          paper_classes(@variant, @color, @size, @shape, @toggle?, @position),
          @class
        )
      }
      onclick={Ripple.on_click(@ripple?)}
      phx-click={@client_toggle? && Toggle.js(@group, @on_toggle)}
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
      class="inline-block size-[1.125em] shrink-0 animate-spin rounded-full border-2 border-current border-t-transparent"
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

  defp paper_classes(variant, color, size, shape, toggle?, position) do
    [
      "inline-flex shrink-0 items-center justify-center whitespace-nowrap cursor-pointer select-none pp-state-layer pp-focus-ring pp-motion-spatial-fast disabled:cursor-default disabled:pointer-events-none aria-disabled:pointer-events-none",
      size_classes(size),
      shape_classes(size, shape, toggle?),
      if(toggle?,
        do: toggle_classes(variant),
        else: color_classes(variant, color || default_color(variant))
      ),
      disabled_classes(variant),
      Ripple.container_classes(true, position)
    ]
  end

  @doc false
  def default_color("tonal"), do: "secondary"
  def default_color(_variant), do: "primary"

  @doc false
  # Shared with IconButton/ButtonGroup/SplitButton: the label type role,
  # height, padding and icon size for each Expressive size.
  def size_classes("xs"),
    do: "h-8 gap-1 px-3 pp-label-large [&_[data-pp-component=icon]]:size-5"

  def size_classes("sm"),
    do: "h-10 gap-2 px-4 pp-label-large [&_[data-pp-component=icon]]:size-5"

  def size_classes("md"),
    do: "h-14 gap-2 px-6 pp-title-medium [&_[data-pp-component=icon]]:size-6"

  def size_classes("lg"),
    do: "h-24 gap-3 px-12 pp-headline-small [&_[data-pp-component=icon]]:size-8"

  def size_classes("xl"),
    do: "h-[8.5rem] gap-4 px-16 pp-headline-large [&_[data-pp-component=icon]]:size-10"

  @doc false
  # Resting radius, pressed radius, and (for toggles) the selected radius —
  # round ↔ square — plus the pressed radius while selected. Round is half
  # the height as a real length so the morph can interpolate it.
  def shape_classes(size, shape, toggle?)

  def shape_classes("xs", "round", false), do: "rounded-[16px] active:rounded-pp-sm"
  def shape_classes("sm", "round", false), do: "rounded-[20px] active:rounded-pp-sm"
  def shape_classes("md", "round", false), do: "rounded-[28px] active:rounded-pp-md"
  def shape_classes("lg", "round", false), do: "rounded-[48px] active:rounded-pp-lg"
  def shape_classes("xl", "round", false), do: "rounded-[68px] active:rounded-pp-lg"
  def shape_classes("xs", "square", false), do: "rounded-pp-md active:rounded-pp-sm"
  def shape_classes("sm", "square", false), do: "rounded-pp-md active:rounded-pp-sm"
  def shape_classes("md", "square", false), do: "rounded-pp-lg active:rounded-pp-md"
  def shape_classes("lg", "square", false), do: "rounded-pp-xl active:rounded-pp-lg"
  def shape_classes("xl", "square", false), do: "rounded-pp-xl active:rounded-pp-lg"

  def shape_classes("xs", "round", true),
    do:
      "rounded-[16px] active:rounded-pp-sm aria-pressed:rounded-pp-md aria-pressed:active:rounded-pp-sm"

  def shape_classes("sm", "round", true),
    do:
      "rounded-[20px] active:rounded-pp-sm aria-pressed:rounded-pp-md aria-pressed:active:rounded-pp-sm"

  def shape_classes("md", "round", true),
    do:
      "rounded-[28px] active:rounded-pp-md aria-pressed:rounded-pp-lg aria-pressed:active:rounded-pp-md"

  def shape_classes("lg", "round", true),
    do:
      "rounded-[48px] active:rounded-pp-lg aria-pressed:rounded-pp-xl aria-pressed:active:rounded-pp-lg"

  def shape_classes("xl", "round", true),
    do:
      "rounded-[68px] active:rounded-pp-lg aria-pressed:rounded-pp-xl aria-pressed:active:rounded-pp-lg"

  def shape_classes("xs", "square", true),
    do:
      "rounded-pp-md active:rounded-pp-sm aria-pressed:rounded-[16px] aria-pressed:active:rounded-pp-sm"

  def shape_classes("sm", "square", true),
    do:
      "rounded-pp-md active:rounded-pp-sm aria-pressed:rounded-[20px] aria-pressed:active:rounded-pp-sm"

  def shape_classes("md", "square", true),
    do:
      "rounded-pp-lg active:rounded-pp-md aria-pressed:rounded-[28px] aria-pressed:active:rounded-pp-md"

  def shape_classes("lg", "square", true),
    do:
      "rounded-pp-xl active:rounded-pp-lg aria-pressed:rounded-[48px] aria-pressed:active:rounded-pp-lg"

  def shape_classes("xl", "square", true),
    do:
      "rounded-pp-xl active:rounded-pp-lg aria-pressed:rounded-[68px] aria-pressed:active:rounded-pp-lg"

  @doc false
  # Shared with SplitButton.
  def color_classes(variant, color)

  def color_classes("filled", "primary"),
    do: "bg-pp-primary text-pp-on-primary hover:pp-elevation-1"

  def color_classes("filled", "secondary"),
    do: "bg-pp-secondary text-pp-on-secondary hover:pp-elevation-1"

  def color_classes("filled", "tertiary"),
    do: "bg-pp-tertiary text-pp-on-tertiary hover:pp-elevation-1"

  def color_classes("filled", "error"), do: "bg-pp-error text-pp-on-error hover:pp-elevation-1"
  def color_classes("filled", "inherit"), do: "bg-current/12 text-inherit"

  def color_classes("tonal", "primary"),
    do: "bg-pp-primary-container text-pp-on-primary-container hover:pp-elevation-1"

  def color_classes("tonal", "secondary"),
    do: "bg-pp-secondary-container text-pp-on-secondary-container hover:pp-elevation-1"

  def color_classes("tonal", "tertiary"),
    do: "bg-pp-tertiary-container text-pp-on-tertiary-container hover:pp-elevation-1"

  def color_classes("tonal", "error"),
    do: "bg-pp-error-container text-pp-on-error-container hover:pp-elevation-1"

  def color_classes("tonal", "inherit"), do: "bg-current/12 text-inherit"

  def color_classes("elevated", "primary"),
    do: "bg-pp-surface-container-low text-pp-primary pp-elevation-1 hover:pp-elevation-2"

  def color_classes("elevated", "secondary"),
    do: "bg-pp-surface-container-low text-pp-secondary pp-elevation-1 hover:pp-elevation-2"

  def color_classes("elevated", "tertiary"),
    do: "bg-pp-surface-container-low text-pp-tertiary pp-elevation-1 hover:pp-elevation-2"

  def color_classes("elevated", "error"),
    do: "bg-pp-surface-container-low text-pp-error pp-elevation-1 hover:pp-elevation-2"

  def color_classes("elevated", "inherit"),
    do: "bg-pp-surface-container-low text-inherit pp-elevation-1 hover:pp-elevation-2"

  def color_classes("outlined", "primary"), do: "border border-pp-outline-variant text-pp-primary"

  def color_classes("outlined", "secondary"),
    do: "border border-pp-outline-variant text-pp-secondary"

  def color_classes("outlined", "tertiary"),
    do: "border border-pp-outline-variant text-pp-tertiary"

  def color_classes("outlined", "error"), do: "border border-pp-outline-variant text-pp-error"
  def color_classes("outlined", "inherit"), do: "border border-current/40 text-inherit"

  def color_classes("text", "primary"), do: "text-pp-primary"
  def color_classes("text", "secondary"), do: "text-pp-secondary"
  def color_classes("text", "tertiary"), do: "text-pp-tertiary"
  def color_classes("text", "error"), do: "text-pp-error"
  def color_classes("text", "inherit"), do: "text-inherit"

  # MD3 Expressive toggle colors: unselected base, selected via aria-pressed.
  defp toggle_classes("filled"),
    do:
      "bg-pp-surface-container text-pp-on-surface-variant aria-pressed:bg-pp-primary aria-pressed:text-pp-on-primary hover:pp-elevation-1"

  defp toggle_classes("tonal"),
    do:
      "bg-pp-secondary-container text-pp-on-secondary-container aria-pressed:bg-pp-secondary aria-pressed:text-pp-on-secondary hover:pp-elevation-1"

  defp toggle_classes("elevated"),
    do:
      "bg-pp-surface-container-low text-pp-primary pp-elevation-1 hover:pp-elevation-2 aria-pressed:bg-pp-primary aria-pressed:text-pp-on-primary"

  defp toggle_classes("outlined"),
    do:
      "border border-pp-outline-variant text-pp-on-surface-variant aria-pressed:border-transparent aria-pressed:bg-pp-inverse-surface aria-pressed:text-pp-inverse-on-surface"

  defp toggle_classes("text"),
    do: "text-pp-on-surface-variant aria-pressed:text-pp-primary"

  @doc false
  # MD3 disabled: container on-surface at 10%, content at 38%. Both the
  # native `:disabled` and link mode's `aria-disabled` are covered.
  def disabled_classes("outlined"),
    do:
      "disabled:border-pp-on-surface/12 disabled:text-pp-on-surface/38 aria-disabled:border-pp-on-surface/12 aria-disabled:text-pp-on-surface/38"

  def disabled_classes("text"),
    do: "disabled:text-pp-on-surface/38 aria-disabled:text-pp-on-surface/38"

  def disabled_classes(_filled),
    do:
      "disabled:bg-pp-on-surface/10 disabled:text-pp-on-surface/38 disabled:shadow-none aria-disabled:bg-pp-on-surface/10 aria-disabled:text-pp-on-surface/38 aria-disabled:shadow-none"
end
