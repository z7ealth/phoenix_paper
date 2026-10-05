defmodule PhoenixPaper.TextField do
  @moduledoc """
  An MD3 text field (`pp_text_field/1`) with a floating label — pure CSS,
  no JavaScript. Renamed from 0.3's `Input` (`pp_input/1`).

      <.pp_text_field field={@form[:email]} type="email" label="Email" />

      <.pp_text_field label="Amount" name="amount" variant="filled">
        <:start_adornment>$</:start_adornment>
      </.pp_text_field>

      <.pp_text_field label="Bio" name="bio" multiline rows={4} supporting_text="Max 200 characters" />

  Accepts a `Phoenix.HTML.FormField` via `field=` (the `to_form/2` idiom,
  like a generated `core_components.ex` input) or plain `name`/`value`.

  ## Variants

  - `outlined` (default): a 1dp `outline` border with 4dp corners. The
    floated label sits **on** the border, in a real notch (a
    `<fieldset>`/`<legend>` pair — see below). Hover darkens the border to
    `on-surface`; focus makes it 2dp in `color`.
  - `filled`: a `surface-container-highest` box with 4dp top corners and
    an active indicator line along the bottom (1dp `on-surface-variant`,
    2dp `color` when focused — drawn as an inset shadow, so focusing
    doesn't shift the layout). Hover adds the 8% state layer.

  Both are 56dp tall with `body-large` input text, the label resting in
  `body-large` and floating up in `body-small`. `size="small"` is a
  40dp, `body-medium` field for dense layouts (not an MD3 size).

  `color` (`primary` default, `secondary`, `tertiary`, `error`) is the
  focused border/indicator and label color. Errors (from `field=` once
  the input was used, or `errors=`) turn the label, outline and supporting
  text `error`, add a trailing error icon (unless there's an end
  adornment) and replace `supporting_text` with the messages.

  `multiline` renders a `<textarea rows={@rows}>` with the same label
  mechanism (its resting label sits on the first line). `:start_adornment`
  / `:end_adornment` hold leading/trailing icons, prefix/suffix text or an
  icon button; they're flex siblings of the input, outside its
  positioning box, so they never touch the input's padding.

  ## `hide_label` — the dense inline variant

  `hide_label` drops the floating label, the notch, the column wrapper and
  the supporting text: just the box, with `label` as the `placeholder`,
  for a field inline in a toolbar (errors still show as the error
  outline). Pair it with `size="small"`.

  ## How the outlined notch works

  The border is a `<fieldset>` absolutely positioned over the field, and
  its `<legend>` (holding an invisible copy of the label, in the floated
  label's `body-small`) is what cuts the gap: browsers notch a fieldset's
  border around its legend natively. The legend is `max-w-0` with **no**
  padding at rest (padding is a floor `max-width` can't shrink below, so
  a resting `px-1` would leave a sliver of open border), and opens to its
  natural width plus `px-1` when the input has a value or focus. The
  fieldset is the input's sibling, not its ancestor (a flex fieldset stops
  notching), so the trigger is `has-[input:not(:placeholder-shown)]` on
  their common wrapper — scoped to `input`/`textarea`, because the
  unscoped `has-[:not(:placeholder-shown)]` also matches the `<label>`
  and would keep the notch open forever.

  A `:start_adornment` moves the label right; the legend follows with a
  fixed offset sized for a 24dp leading icon (MD3's case). A wider prefix
  can misalign the notch — there's no CSS-only way to measure it.

  The input always has `placeholder=" "` (a single space) so
  `:placeholder-shown` tracks emptiness; a real `placeholder` attr would
  defeat the floating label, so use `supporting_text` for hints.

  ## Migrating from 0.3

  `pp_input` → `pp_text_field`, `variant="standard"` is gone (MD3 has only
  filled and outlined), `helper_text` → `supporting_text`, `color="accent"`
  → `tertiary`, `shape` is gone (MD3 fixes the corners).
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:type, :string, default: "text")
  attr(:variant, :string, default: "outlined", values: ~w(outlined filled))
  attr(:size, :string, default: "medium", values: ~w(medium small))
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary error))
  attr(:multiline, :boolean, default: false, doc: "renders a <textarea rows={@rows}>")
  attr(:rows, :integer, default: 3, doc: "multiline only")

  attr(:hide_label, :boolean,
    default: false,
    doc: "dense inline variant: no floating label (used as placeholder), no supporting text"
  )

  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:errors, :list, default: [])
  attr(:supporting_text, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(autocomplete autofocus form list max maxlength min minlength pattern readonly required step inputmode)
  )

  slot(:start_adornment)
  slot(:end_adornment)

  @doc "Renders a text field. See the module doc."
  def pp_text_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil)
    |> assign(:name, assigns.name || field.name)
    |> assign(:id, assigns.id || field.id)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Helpers.translate_error/1))
    |> pp_text_field()
  end

  def pp_text_field(%{hide_label: true} = assigns) do
    ~H"""
    <div
      data-pp-component="text-field"
      data-pp-dense="true"
      class={Helpers.classes(@paperize, dense_wrapper_classes(@variant, @color, @errors), @class)}
    >
      <span :if={@start_adornment != []} data-pp-adornment="start" class={adornment_classes(:start)}>
        {render_slot(@start_adornment)}
      </span>
      <textarea
        :if={@multiline}
        id={@id}
        name={@name}
        rows={@rows}
        disabled={@disabled}
        placeholder={@label}
        aria-invalid={@errors != [] && "true"}
        class={Helpers.classes(@paperize, [dense_field_classes(@size), "resize-y"], nil)}
        {@rest}
      >{@value}</textarea>
      <input
        :if={!@multiline}
        type={@type}
        id={@id}
        name={@name}
        value={input_value(@type, @value)}
        disabled={@disabled}
        placeholder={@label}
        aria-invalid={@errors != [] && "true"}
        class={Helpers.classes(@paperize, dense_field_classes(@size), nil)}
        {@rest}
      />
      <span :if={@end_adornment != []} data-pp-adornment="end" class={adornment_classes(:end)}>
        {render_slot(@end_adornment)}
      </span>
    </div>
    """
  end

  def pp_text_field(assigns) do
    assigns =
      assign(
        assigns,
        :describedby,
        (assigns.supporting_text || assigns.errors != []) && assigns.id &&
          "#{assigns.id}-supporting"
      )

    ~H"""
    <div data-pp-component="text-field" class={Helpers.classes(@paperize, "flex flex-col gap-1", @class)}>
      <div class={Helpers.classes(@paperize, wrapper_classes(@variant, @color, @errors, @size), nil)}>
        <span :if={@start_adornment != []} data-pp-adornment="start" class={adornment_classes(:start)}>
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
            aria-invalid={@errors != [] && "true"}
            aria-describedby={@describedby}
            class={Helpers.classes(@paperize, [input_classes(@variant, @size), "resize-y"], nil)}
            {@rest}
          >{@value}</textarea>
          <input
            :if={!@multiline}
            type={@type}
            id={@id}
            name={@name}
            value={input_value(@type, @value)}
            disabled={@disabled}
            placeholder=" "
            aria-invalid={@errors != [] && "true"}
            aria-describedby={@describedby}
            class={Helpers.classes(@paperize, input_classes(@variant, @size), nil)}
            {@rest}
          />
          <label
            :if={@label}
            for={@id}
            class={Helpers.classes(@paperize, label_classes(@variant, @size, @color, @errors, @multiline), nil)}
          >
            {@label}
          </label>
        </div>
        <span :if={@end_adornment != []} data-pp-adornment="end" class={adornment_classes(:end)}>
          {render_slot(@end_adornment)}
        </span>
        <span
          :if={@end_adornment == [] && @errors != [] && @paperize}
          data-pp-adornment="end"
          class={[adornment_classes(:end), "text-pp-error"]}
        >
          <.pp_icon name="hero-exclamation-circle" />
        </span>
        <fieldset
          :if={@variant == "outlined" && @paperize}
          aria-hidden="true"
          class={fieldset_classes(@errors)}
        >
          <legend class={legend_classes()}>
            <span :if={@label}>{@label}</span>
          </legend>
        </fieldset>
      </div>
      <div :if={@describedby || @supporting_text} id={@describedby} class="flex flex-col">
        <p
          :if={@supporting_text && @errors == []}
          class={Helpers.classes(@paperize, "px-4 pp-body-small text-pp-on-surface-variant", nil)}
        >
          {@supporting_text}
        </p>
        <p :for={msg <- @errors} class={Helpers.classes(@paperize, "px-4 pp-body-small text-pp-error", nil)}>
          {msg}
        </p>
      </div>
    </div>
    """
  end

  # `Phoenix.HTML.Form.normalize_value/2` turns a `NaiveDateTime`/`DateTime`
  # into the `YYYY-MM-DDTHH:MM` a `datetime-local` input requires, the same
  # call a generated `core_components.ex` makes.
  defp input_value("datetime-local" = type, value),
    do: Phoenix.HTML.Form.normalize_value(type, value)

  defp input_value(_type, value), do: value

  # ---- wrapper ----

  defp wrapper_classes("outlined", color, errors, size) do
    [
      "relative flex items-stretch rounded-pp-xs has-[:disabled]:pointer-events-none has-[:disabled]:opacity-38",
      height(size),
      "has-[input:not(:placeholder-shown)]:[&>fieldset>legend]:max-w-full has-[input:not(:placeholder-shown)]:[&>fieldset>legend]:px-1",
      "has-[textarea:not(:placeholder-shown)]:[&>fieldset>legend]:max-w-full has-[textarea:not(:placeholder-shown)]:[&>fieldset>legend]:px-1",
      "focus-within:[&>fieldset>legend]:max-w-full focus-within:[&>fieldset>legend]:px-1",
      "has-[[data-pp-adornment=start]]:[&>fieldset>legend]:ms-12",
      outlined_state_classes(color, errors)
    ]
  end

  defp wrapper_classes("filled", color, errors, size) do
    [
      "relative flex items-stretch rounded-t-pp-xs bg-pp-surface-container-highest has-[:disabled]:pointer-events-none has-[:disabled]:opacity-38",
      "before:pointer-events-none before:absolute before:inset-0 before:rounded-[inherit] before:bg-pp-on-surface before:opacity-0 before:transition-opacity hover:before:opacity-8",
      height(size),
      filled_indicator_classes(color, errors),
      filled_adornment_classes(size)
    ]
  end

  defp height("medium"), do: "min-h-14"
  defp height("small"), do: "min-h-10"

  defp outlined_state_classes(_color, errors) when errors != [],
    do: "focus-within:[&>fieldset]:border-2"

  defp outlined_state_classes("primary", []),
    do:
      "hover:[&>fieldset]:border-pp-on-surface focus-within:[&>fieldset]:border-2 focus-within:[&>fieldset]:!border-pp-primary"

  defp outlined_state_classes("secondary", []),
    do:
      "hover:[&>fieldset]:border-pp-on-surface focus-within:[&>fieldset]:border-2 focus-within:[&>fieldset]:!border-pp-secondary"

  defp outlined_state_classes("tertiary", []),
    do:
      "hover:[&>fieldset]:border-pp-on-surface focus-within:[&>fieldset]:border-2 focus-within:[&>fieldset]:!border-pp-tertiary"

  defp outlined_state_classes("error", []),
    do:
      "hover:[&>fieldset]:border-pp-on-surface focus-within:[&>fieldset]:border-2 focus-within:[&>fieldset]:!border-pp-error"

  # The active indicator is an inset bottom shadow, so 1dp → 2dp on focus
  # doesn't move anything.
  defp filled_indicator_classes(_color, errors) when errors != [],
    do:
      "shadow-[inset_0_-1px_0_0_var(--color-pp-error)] focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-error)]"

  defp filled_indicator_classes("primary", []),
    do:
      "shadow-[inset_0_-1px_0_0_var(--color-pp-on-surface-variant)] focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-primary)]"

  defp filled_indicator_classes("secondary", []),
    do:
      "shadow-[inset_0_-1px_0_0_var(--color-pp-on-surface-variant)] focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-secondary)]"

  defp filled_indicator_classes("tertiary", []),
    do:
      "shadow-[inset_0_-1px_0_0_var(--color-pp-on-surface-variant)] focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-tertiary)]"

  defp filled_indicator_classes("error", []),
    do:
      "shadow-[inset_0_-1px_0_0_var(--color-pp-on-surface-variant)] focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-error)]"

  # In a filled field the input text sits low (room for the floated label
  # above it), so once the label floats, prefix/suffix text adornments drop
  # to the input's baseline: `items-end` plus the input's bottom padding.
  # `has-*` lives on the wrapper because the adornment is the input's
  # sibling, not its ancestor.
  defp filled_adornment_classes("medium") do
    "has-[input:not(:placeholder-shown)]:[&>[data-pp-adornment]]:items-end has-[input:not(:placeholder-shown)]:[&>[data-pp-adornment]]:pb-2 " <>
      "has-[textarea:not(:placeholder-shown)]:[&>[data-pp-adornment]]:items-end has-[textarea:not(:placeholder-shown)]:[&>[data-pp-adornment]]:pb-2 " <>
      "focus-within:[&>[data-pp-adornment]]:items-end focus-within:[&>[data-pp-adornment]]:pb-2"
  end

  defp filled_adornment_classes("small") do
    "has-[input:not(:placeholder-shown)]:[&>[data-pp-adornment]]:items-end has-[input:not(:placeholder-shown)]:[&>[data-pp-adornment]]:pb-1 " <>
      "has-[textarea:not(:placeholder-shown)]:[&>[data-pp-adornment]]:items-end has-[textarea:not(:placeholder-shown)]:[&>[data-pp-adornment]]:pb-1 " <>
      "focus-within:[&>[data-pp-adornment]]:items-end focus-within:[&>[data-pp-adornment]]:pb-1"
  end

  defp fieldset_classes(errors) when errors != [],
    do:
      "pointer-events-none absolute inset-0 m-0 min-w-0 rounded-pp-xs border border-pp-error p-0"

  defp fieldset_classes([]),
    do:
      "pointer-events-none absolute inset-0 m-0 min-w-0 rounded-pp-xs border border-pp-outline p-0 transition-colors"

  defp legend_classes do
    "invisible ms-3 max-w-0 overflow-hidden whitespace-nowrap px-0 pp-body-small transition-[max-width] duration-150"
  end

  # ---- input ----

  defp input_classes("outlined", "medium"),
    do:
      "peer block w-full min-w-0 bg-transparent px-4 py-4 pp-body-large text-pp-on-surface outline-none placeholder:text-transparent"

  defp input_classes("outlined", "small"),
    do:
      "peer block w-full min-w-0 bg-transparent px-4 py-2.5 pp-body-medium text-pp-on-surface outline-none placeholder:text-transparent"

  defp input_classes("filled", "medium"),
    do:
      "peer block w-full min-w-0 bg-transparent px-4 pt-6 pb-2 pp-body-large text-pp-on-surface outline-none placeholder:text-transparent"

  defp input_classes("filled", "small"),
    do:
      "peer block w-full min-w-0 bg-transparent px-4 pt-4 pb-1 pp-body-medium text-pp-on-surface outline-none placeholder:text-transparent"

  # ---- label ----

  # Resting: centered (or on the first line when multiline), on-surface-
  # variant. Floated (focus or a value): body-small, at the top of a filled
  # field or centered on an outlined field's border.
  defp label_classes(variant, size, color, errors, multiline) do
    [
      "pointer-events-none absolute start-4 max-w-[calc(100%-2rem)] truncate transition-all duration-150 ease-pp-standard",
      resting(size, multiline),
      floated(variant, size),
      label_color(color, errors)
    ]
  end

  defp resting("medium", false), do: "top-1/2 -translate-y-1/2 pp-body-large"
  defp resting("small", false), do: "top-1/2 -translate-y-1/2 pp-body-medium"
  defp resting("medium", true), do: "top-4 translate-y-0 pp-body-large"
  defp resting("small", true), do: "top-2.5 translate-y-0 pp-body-medium"

  defp floated("filled", "medium"),
    do:
      "peer-focus:top-2 peer-focus:translate-y-0 peer-focus:pp-body-small peer-[:not(:placeholder-shown)]:top-2 peer-[:not(:placeholder-shown)]:translate-y-0 peer-[:not(:placeholder-shown)]:pp-body-small"

  defp floated("filled", "small"),
    do:
      "peer-focus:top-0.5 peer-focus:translate-y-0 peer-focus:pp-body-small peer-[:not(:placeholder-shown)]:top-0.5 peer-[:not(:placeholder-shown)]:translate-y-0 peer-[:not(:placeholder-shown)]:pp-body-small"

  defp floated("outlined", _size),
    do:
      "peer-focus:top-0 peer-focus:-translate-y-1/2 peer-focus:pp-body-small peer-[:not(:placeholder-shown)]:top-0 peer-[:not(:placeholder-shown)]:-translate-y-1/2 peer-[:not(:placeholder-shown)]:pp-body-small"

  defp label_color(_color, errors) when errors != [], do: "text-pp-error"
  defp label_color("primary", []), do: "text-pp-on-surface-variant peer-focus:text-pp-primary"
  defp label_color("secondary", []), do: "text-pp-on-surface-variant peer-focus:text-pp-secondary"
  defp label_color("tertiary", []), do: "text-pp-on-surface-variant peer-focus:text-pp-tertiary"
  defp label_color("error", []), do: "text-pp-on-surface-variant peer-focus:text-pp-error"

  defp adornment_classes(:start),
    do: "relative flex shrink-0 items-center ps-3 pp-body-large text-pp-on-surface-variant"

  defp adornment_classes(:end),
    do: "relative flex shrink-0 items-center pe-3 pp-body-large text-pp-on-surface-variant"

  # ---- hide_label ----

  defp dense_wrapper_classes(variant, color, errors) do
    [
      "relative flex items-stretch has-[:disabled]:pointer-events-none has-[:disabled]:opacity-38",
      dense_border_classes(variant, color, errors)
    ]
  end

  defp dense_border_classes("outlined", _color, errors) when errors != [],
    do: "rounded-pp-xs border-2 border-pp-error"

  defp dense_border_classes("filled", _color, errors) when errors != [],
    do:
      "rounded-t-pp-xs bg-pp-surface-container-highest shadow-[inset_0_-2px_0_0_var(--color-pp-error)]"

  defp dense_border_classes("outlined", color, []),
    do: [
      "rounded-pp-xs border border-pp-outline hover:border-pp-on-surface focus-within:border-2",
      dense_focus_border(color)
    ]

  defp dense_border_classes("filled", color, []),
    do: [
      "rounded-t-pp-xs bg-pp-surface-container-highest shadow-[inset_0_-1px_0_0_var(--color-pp-on-surface-variant)]",
      dense_focus_indicator(color)
    ]

  defp dense_focus_border("primary"), do: "focus-within:border-pp-primary"
  defp dense_focus_border("secondary"), do: "focus-within:border-pp-secondary"
  defp dense_focus_border("tertiary"), do: "focus-within:border-pp-tertiary"
  defp dense_focus_border("error"), do: "focus-within:border-pp-error"

  defp dense_focus_indicator("primary"),
    do: "focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-primary)]"

  defp dense_focus_indicator("secondary"),
    do: "focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-secondary)]"

  defp dense_focus_indicator("tertiary"),
    do: "focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-tertiary)]"

  defp dense_focus_indicator("error"),
    do: "focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-error)]"

  defp dense_field_classes("medium"),
    do:
      "block w-full min-w-0 bg-transparent px-4 py-4 pp-body-large text-pp-on-surface outline-none placeholder:text-pp-on-surface-variant"

  defp dense_field_classes("small"),
    do:
      "block w-full min-w-0 bg-transparent px-3 py-2 pp-body-medium text-pp-on-surface outline-none placeholder:text-pp-on-surface-variant"
end
