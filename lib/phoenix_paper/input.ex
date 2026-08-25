defmodule PhoenixPaper.Input do
  @moduledoc """
  A Material Design text field (`pp_input/1`) with a floating label — pure
  CSS, no JavaScript. Three variants: `outlined` (bordered box), `filled`
  (filled background with an underline accent), and `standard` (underline
  only, no box/background — and no `shape`, since there's nothing to round).

  Accepts either a Phoenix `Phoenix.HTML.FormField` via `field=` (idiomatic
  `to_form/2` usage, same as the default `core_components.ex` input) or
  plain `name`/`value` attrs.

      <.pp_input label="Amount" name="amount">
        <:start_adornment>$</:start_adornment>
      </.pp_input>

      <.pp_input label="Bio" name="bio" multiline rows={4} />

  `multiline` renders a `<textarea rows={@rows}>` instead of `<input>`,
  reusing the exact same floating-label/`peer-*` mechanism — the label
  doesn't care whether its peer is an `<input>` or a `<textarea>`, both are
  ordinary form controls as far as `:placeholder-shown`/`:focus` are
  concerned. There's no auto-growing-height JS here (`rows` is fixed) —
  modern browsers support this via the plain CSS `field-sizing: content`
  property with no JS at all, but it's new enough (2024+ Chromium/Firefox)
  that it isn't relied on here; add it yourself via `class` if your
  supported browsers cover it and you want it.

  `:start_adornment`/`:end_adornment` (prefix/suffix content — an icon, a
  unit like "kg", a button) sit as plain flex siblings *outside* the
  input/label positioning box, not inside it — this means adding one never
  requires touching the input's own padding or the label's `left-*`
  position (both of which vary by variant/size already); the flex layout
  just gives the adornment its own space and lets the input/label pair
  occupy whatever's left.

  ## The `outlined` notch

  `variant="outlined"`'s border has a real gap cut into it around the
  floated label — MUI's "notched outline" — not just a label floating on
  top of an unbroken border line (an earlier version of this did that,
  which reads as visibly wrong/off-brand next to any genuine Material
  text field; caught from a side-by-side screenshot comparison, not by
  reasoning about it). This is a real `<fieldset>`/`<legend>` — the actual
  technique MUI itself uses, and a genuine browser rendering behavior, not
  a CSS trick: browsers already draw a gap in a `<fieldset>`'s own border
  around its `<legend>` natively, with zero custom CSS, if you just write
  the HTML — `PhoenixPaper.Shape`'s `rounded-*` plus a color are the only
  things this component adds on top. The `<legend>` holds the same label
  text as the real, visible floating `<label>` (in `invisible` text, so
  it's never seen) — its only job is sizing the notch: `max-width:0` at
  rest so the border stays intact, transitioning to the label's natural
  content width in the outlined-and-focused/outlined-and-filled state, the
  same trigger conditions the real label's own `top-2`/`text-xs` shrink
  already uses.

  The `<fieldset>` is a *sibling* of the input (both descend from the same
  wrapper `<div>`, absolutely positioned over it), not an ancestor of it —
  `<legend>`'s native border-notching behavior is a product of the
  fieldset's own default (non-flex) box layout, so the fieldset can't
  double as the actual flex row arranging adornments/input/label without
  losing that behavior entirely (verified empirically: setting
  `display: flex` on the fieldset stops it from notching the legend at
  all). Because of that sibling relationship, the usual `peer-*` trick
  (which only reaches true siblings) can't connect the input to the
  fieldset's nested `<legend>` two levels down — this uses `has-*` from
  their common ancestor instead, scoped to the actual tag
  (`has-[input:not(:placeholder-shown)]`/`has-[textarea:not(:placeholder-shown)]`),
  *not* the unscoped `has-[:not(:placeholder-shown)]` — the unscoped form
  would trivially match the `<label>` itself (which vacuously satisfies
  "not placeholder-shown" the same way any non-form-control element does,
  since it doesn't show a placeholder at all), keeping the notch
  permanently open regardless of the input's real state. Caught before
  shipping by working through what the selector actually matches, not
  from a failing screenshot.

  `filled`/`standard` don't get a notch — Material only notches the
  bordered `outlined` variant; `filled`'s underline and `standard`'s
  bare underline have no enclosing border to cut a gap into.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Shape}

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:type, :string, default: "text")
  attr(:variant, :string, default: "outlined", values: ~w(outlined filled standard))
  attr(:size, :string, default: "medium", values: ~w(medium small))
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary error))

  attr(:shape, :atom,
    default: :sm,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape — ignored for variant=\"standard\""
  )

  attr(:multiline, :boolean,
    default: false,
    doc: "renders a <textarea rows={@rows}> instead of <input>"
  )

  attr(:rows, :integer, default: 3, doc: "multiline only")

  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:errors, :list, default: [])
  attr(:helper_text, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(autocomplete autofocus form list max maxlength min minlength pattern placeholder readonly required step)
  )

  slot(:start_adornment)
  slot(:end_adornment)

  def pp_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil)
    |> assign(:name, assigns.name || field.name)
    |> assign(:id, assigns.id || field.id)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Helpers.translate_error/1))
    |> pp_input()
  end

  def pp_input(assigns) do
    ~H"""
    <div data-pp-component="input" class={Helpers.classes(@paperize, "flex flex-col gap-1", @class)}>
      <div class={Helpers.classes(@paperize, wrapper_classes(@variant, @color, @shape, @errors), nil)}>
        <span :if={@start_adornment != []} class="flex shrink-0 items-center pl-3 text-pp-outline">
          {render_slot(@start_adornment)}
        </span>
        <div class="relative min-w-0 flex-1">
          <textarea
            :if={@multiline}
            id={@id}
            name={@name}
            rows={@rows}
            disabled={@disabled}
            placeholder=" "
            class={Helpers.classes(@paperize, [input_classes(@size), "resize-y"], nil)}
            {@rest}
          >{@value}</textarea>
          <input
            :if={!@multiline}
            type={@type}
            id={@id}
            name={@name}
            value={@value}
            disabled={@disabled}
            placeholder=" "
            class={Helpers.classes(@paperize, input_classes(@size), nil)}
            {@rest}
          />
          <label :if={@label} for={@id} class={Helpers.classes(@paperize, label_classes(@color, @errors), nil)}>
            {@label}
          </label>
        </div>
        <span :if={@end_adornment != []} class="flex shrink-0 items-center pr-3 text-pp-outline">
          {render_slot(@end_adornment)}
        </span>
        <fieldset
          :if={@variant == "outlined" && @paperize}
          aria-hidden="true"
          class={fieldset_classes(@shape, @errors)}
        >
          <legend class={legend_classes()}>
            <span :if={@label}>{@label}</span>
          </legend>
        </fieldset>
      </div>
      <p :if={@helper_text && @errors == []} class="text-xs text-pp-outline">{@helper_text}</p>
      <p :for={msg <- @errors} class="text-xs text-pp-error">{msg}</p>
    </div>
    """
  end

  defp wrapper_classes("outlined", color, _shape, errors) do
    [
      "relative flex items-stretch transition-colors",
      "has-[input:not(:placeholder-shown)]:[&>fieldset>legend]:max-w-full has-[textarea:not(:placeholder-shown)]:[&>fieldset>legend]:max-w-full focus-within:[&>fieldset>legend]:max-w-full",
      outlined_focus_border_classes(color, errors)
    ]
  end

  defp wrapper_classes(variant, _color, _shape, errors) when errors != [] do
    error_classes(variant)
  end

  defp wrapper_classes(variant, color, shape, []) do
    [base_wrapper_classes(variant), color_classes(variant, color), shape_classes(variant, shape)]
  end

  defp outlined_focus_border_classes(_color, errors) when errors != [], do: ""

  defp outlined_focus_border_classes("primary", []),
    do: "focus-within:[&>fieldset]:border-2 focus-within:[&>fieldset]:border-pp-primary"

  defp outlined_focus_border_classes("secondary", []),
    do: "focus-within:[&>fieldset]:border-2 focus-within:[&>fieldset]:border-pp-secondary"

  defp outlined_focus_border_classes("tertiary", []),
    do: "focus-within:[&>fieldset]:border-2 focus-within:[&>fieldset]:border-pp-tertiary"

  defp outlined_focus_border_classes("error", []),
    do: "focus-within:[&>fieldset]:border-2 focus-within:[&>fieldset]:border-pp-error"

  defp fieldset_classes(shape, errors) when errors != [] do
    [
      "pointer-events-none absolute inset-0 m-0 min-w-0 border-2 border-pp-error p-0",
      Shape.class(shape)
    ]
  end

  defp fieldset_classes(shape, []) do
    [
      "pointer-events-none absolute inset-0 m-0 min-w-0 border border-pp-outline p-0",
      Shape.class(shape)
    ]
  end

  defp legend_classes do
    "invisible ml-2 max-w-0 overflow-hidden whitespace-nowrap px-1 text-sm transition-[max-width] duration-150"
  end

  defp base_wrapper_classes("filled"),
    do:
      "relative flex items-stretch border-b border-pp-outline bg-pp-surface-variant transition-colors"

  defp base_wrapper_classes(_variant), do: "relative flex items-stretch transition-colors"

  defp shape_classes("standard", _shape), do: ""
  defp shape_classes("filled", shape), do: Shape.class(shape, :top)

  defp color_classes("filled", "primary"),
    do: "focus-within:border-b-2 focus-within:border-pp-primary"

  defp color_classes("filled", "secondary"),
    do: "focus-within:border-b-2 focus-within:border-pp-secondary"

  defp color_classes("filled", "tertiary"),
    do: "focus-within:border-b-2 focus-within:border-pp-tertiary"

  defp color_classes("filled", "error"),
    do: "focus-within:border-b-2 focus-within:border-pp-error"

  defp color_classes("standard", "primary"),
    do: "border-b border-pp-outline focus-within:border-b-2 focus-within:border-pp-primary"

  defp color_classes("standard", "secondary"),
    do: "border-b border-pp-outline focus-within:border-b-2 focus-within:border-pp-secondary"

  defp color_classes("standard", "tertiary"),
    do: "border-b border-pp-outline focus-within:border-b-2 focus-within:border-pp-tertiary"

  defp color_classes("standard", "error"),
    do: "border-b border-pp-outline focus-within:border-b-2 focus-within:border-pp-error"

  defp error_classes("filled"),
    do: "relative flex items-stretch border-b-2 border-pp-error bg-pp-surface-variant"

  defp error_classes("standard"), do: "relative flex items-stretch border-b-2 border-pp-error"

  defp input_classes("medium"),
    do:
      "peer block w-full min-w-0 bg-transparent px-3 pt-7 pb-2 text-sm text-pp-on-surface outline-none placeholder:text-transparent disabled:cursor-not-allowed disabled:opacity-40"

  defp input_classes("small"),
    do:
      "peer block w-full min-w-0 bg-transparent px-3 pt-5 pb-1.5 text-sm text-pp-on-surface outline-none placeholder:text-transparent disabled:cursor-not-allowed disabled:opacity-40"

  defp label_classes(_color, errors) when errors != [] do
    "pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm text-pp-error transition-all peer-focus:top-2 peer-focus:text-xs peer-[:not(:placeholder-shown)]:top-2 peer-[:not(:placeholder-shown)]:text-xs"
  end

  defp label_classes("primary", []) do
    "pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm text-pp-outline transition-all peer-focus:top-2 peer-focus:text-xs peer-focus:text-pp-primary peer-[:not(:placeholder-shown)]:top-2 peer-[:not(:placeholder-shown)]:text-xs"
  end

  defp label_classes("secondary", []) do
    "pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm text-pp-outline transition-all peer-focus:top-2 peer-focus:text-xs peer-focus:text-pp-secondary peer-[:not(:placeholder-shown)]:top-2 peer-[:not(:placeholder-shown)]:text-xs"
  end

  defp label_classes("tertiary", []) do
    "pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm text-pp-outline transition-all peer-focus:top-2 peer-focus:text-xs peer-focus:text-pp-tertiary peer-[:not(:placeholder-shown)]:top-2 peer-[:not(:placeholder-shown)]:text-xs"
  end

  defp label_classes("error", []) do
    "pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm text-pp-outline transition-all peer-focus:top-2 peer-focus:text-xs peer-focus:text-pp-error peer-[:not(:placeholder-shown)]:top-2 peer-[:not(:placeholder-shown)]:text-xs"
  end
end
