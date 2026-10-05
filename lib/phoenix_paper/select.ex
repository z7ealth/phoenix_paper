defmodule PhoenixPaper.Select do
  @moduledoc """
  An MD3 select field (`pp_select/1`) — a native `<select>` styled as an
  MD3 `outlined`/`filled` text field with a trailing drop-down arrow. Its
  label is always floated (a select always shows a value), so the
  outlined notch is always open. For a styled, searchable menu instead of
  the browser's native list, see `PhoenixPaper.PowerSelect`.

  Accepts either a Phoenix `Phoenix.HTML.FormField` via `field=` or plain
  `name`/`value` attrs.

  `hide_label` is the dense, inline variant — the counterpart of
  `PhoenixPaper.TextField`'s own `hide_label` (see its module doc): it drops
  the outer wrapper column, the floating label and the helper/error rows,
  leaving a compact bordered `<select>` box sized to sit in a filter
  toolbar. Pass `prompt` to give it placeholder-style text.

  Migrating from 0.3: `helper_text` → `supporting_text`; `shape` is gone
  (MD3 fixes the corners).
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:options, :list, required: true, doc: "list of {label, value} tuples, or plain values")
  attr(:prompt, :string, default: nil)
  attr(:variant, :string, default: "outlined", values: ~w(outlined filled))

  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:errors, :list, default: [])
  attr(:supporting_text, :string, default: nil)
  attr(:disabled, :boolean, default: false)

  attr(:hide_label, :boolean,
    default: false,
    doc: "dense inline variant — no wrapper column, no floating label, no helper/error text"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(autofocus form multiple required))

  def pp_select(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil)
    |> assign(:name, assigns.name || field.name)
    |> assign(:id, assigns.id || field.id)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Helpers.translate_error/1))
    |> pp_select()
  end

  def pp_select(%{hide_label: true} = assigns) do
    assigns = assign(assigns, :normalized_options, Enum.map(assigns.options, &normalize_option/1))

    ~H"""
    <div
      data-pp-component="select"
      data-pp-dense="true"
      class={Helpers.classes(@paperize, dense_wrapper_classes(@variant, @errors), @class)}
    >
      <select
        id={@id}
        name={@name}
        disabled={@disabled}
        class={Helpers.classes(@paperize, dense_select_classes(), nil)}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        <option
          :for={{opt_label, opt_value} <- @normalized_options}
          value={opt_value}
          selected={to_string(opt_value) == to_string(@value)}
        >
          {opt_label}
        </option>
      </select>
      <span
        :if={@paperize}
        class="pointer-events-none absolute end-4 top-1/2 size-0 -translate-y-1/2 border-x-[5px] border-t-[5px] border-x-transparent border-t-pp-on-surface-variant"
      />
    </div>
    """
  end

  def pp_select(assigns) do
    assigns = assign(assigns, :normalized_options, Enum.map(assigns.options, &normalize_option/1))

    ~H"""
    <div data-pp-component="select" class={Helpers.classes(@paperize, "flex flex-col gap-1", @class)}>
      <div class={Helpers.classes(@paperize, wrapper_classes(@variant, @errors), nil)}>
        <select
          id={@id}
          name={@name}
          disabled={@disabled}
          class={Helpers.classes(@paperize, select_classes(), nil)}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          <option
            :for={{opt_label, opt_value} <- @normalized_options}
            value={opt_value}
            selected={to_string(opt_value) == to_string(@value)}
          >
            {opt_label}
          </option>
        </select>
        <span
          :if={@paperize}
          class="pointer-events-none absolute end-4 top-1/2 size-0 -translate-y-1/2 border-x-[5px] border-t-[5px] border-x-transparent border-t-pp-on-surface-variant"
        />
        <label
          :if={@label}
          for={@id}
          class={Helpers.classes(@paperize, label_classes(@variant, @errors), nil)}
        >
          {@label}
        </label>
        <fieldset
          :if={@variant == "outlined" && @paperize}
          aria-hidden="true"
          class={fieldset_classes(@errors)}
        >
          <legend class="invisible ms-3 whitespace-nowrap px-1 pp-body-small">
            <span :if={@label}>{@label}</span>
          </legend>
        </fieldset>
      </div>
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
    """
  end

  defp normalize_option({label, value}), do: {label, value}
  defp normalize_option(value), do: {to_string(value), value}

  # Outlined: the border is a fieldset whose legend is always open (a
  # select always shows a value, so its label is always floated onto the
  # border) — the same notch as `PhoenixPaper.TextField`. Filled: the MD3
  # active indicator as an inset shadow.
  defp wrapper_classes("outlined", []),
    do:
      "relative flex h-14 items-center rounded-pp-xs hover:[&>fieldset]:border-pp-on-surface focus-within:[&>fieldset]:border-2 focus-within:[&>fieldset]:!border-pp-primary has-[:disabled]:opacity-38"

  defp wrapper_classes("outlined", _errors),
    do:
      "relative flex h-14 items-center rounded-pp-xs focus-within:[&>fieldset]:border-2 has-[:disabled]:opacity-38"

  defp wrapper_classes("filled", []),
    do:
      "relative flex h-14 items-end rounded-t-pp-xs bg-pp-surface-container-highest shadow-[inset_0_-1px_0_0_var(--color-pp-on-surface-variant)] focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-primary)] has-[:disabled]:opacity-38"

  defp wrapper_classes("filled", _errors),
    do:
      "relative flex h-14 items-end rounded-t-pp-xs bg-pp-surface-container-highest shadow-[inset_0_-1px_0_0_var(--color-pp-error)] focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-error)] has-[:disabled]:opacity-38"

  defp fieldset_classes([]),
    do:
      "pointer-events-none absolute inset-0 m-0 min-w-0 rounded-pp-xs border border-pp-outline p-0 transition-colors"

  defp fieldset_classes(_errors),
    do:
      "pointer-events-none absolute inset-0 m-0 min-w-0 rounded-pp-xs border border-pp-error p-0"

  # `<select>` centers its displayed value inside its own box regardless of
  # asymmetric padding, so a filled select is pinned to the bottom of the
  # fixed-height `items-end` wrapper instead, leaving the label room on top.
  defp select_classes do
    "peer block w-full cursor-pointer appearance-none bg-transparent px-4 py-2 pe-10 pp-body-large text-pp-on-surface outline-none disabled:cursor-default"
  end

  defp dense_wrapper_classes("outlined", []),
    do:
      "relative flex items-center rounded-pp-xs border border-pp-outline hover:border-pp-on-surface focus-within:border-2 focus-within:!border-pp-primary has-[:disabled]:opacity-38"

  defp dense_wrapper_classes("outlined", _errors),
    do: "relative flex items-center rounded-pp-xs border-2 border-pp-error"

  defp dense_wrapper_classes("filled", []),
    do:
      "relative flex items-center rounded-t-pp-xs bg-pp-surface-container-highest shadow-[inset_0_-1px_0_0_var(--color-pp-on-surface-variant)] focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-primary)] has-[:disabled]:opacity-38"

  defp dense_wrapper_classes("filled", _errors),
    do:
      "relative flex items-center rounded-t-pp-xs bg-pp-surface-container-highest shadow-[inset_0_-2px_0_0_var(--color-pp-error)]"

  defp dense_select_classes do
    "block w-full cursor-pointer appearance-none bg-transparent px-3 py-2 pe-9 pp-body-medium text-pp-on-surface outline-none disabled:cursor-default"
  end

  defp label_classes("outlined", []),
    do:
      "pointer-events-none absolute start-4 top-0 -translate-y-1/2 pp-body-small text-pp-on-surface-variant peer-focus:text-pp-primary"

  defp label_classes("outlined", _errors),
    do: "pointer-events-none absolute start-4 top-0 -translate-y-1/2 pp-body-small text-pp-error"

  defp label_classes("filled", []),
    do:
      "pointer-events-none absolute start-4 top-2 pp-body-small text-pp-on-surface-variant peer-focus:text-pp-primary"

  defp label_classes("filled", _errors),
    do: "pointer-events-none absolute start-4 top-2 pp-body-small text-pp-error"
end
