defmodule PhoenixPaper.Select do
  @moduledoc """
  A Material Design select field (`pp_select/1`) — a native `<select>`
  styled to match `PhoenixPaper.Input`'s `outlined`/`filled` variants.

  Accepts either a Phoenix `Phoenix.HTML.FormField` via `field=` or plain
  `name`/`value` attrs.

  `hide_label` is the dense, inline variant — the counterpart of
  `PhoenixPaper.Input`'s own `hide_label` (see its module doc): it drops
  the outer wrapper column, the floating label and the helper/error rows,
  leaving a compact bordered `<select>` box sized to sit in a filter
  toolbar. Pass `prompt` to give it placeholder-style text.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Shape}

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:options, :list, required: true, doc: "list of {label, value} tuples, or plain values")
  attr(:prompt, :string, default: nil)
  attr(:variant, :string, default: "outlined", values: ~w(outlined filled))

  attr(:shape, :atom,
    default: :sm,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:errors, :list, default: [])
  attr(:helper_text, :string, default: nil)
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
      class={Helpers.classes(@paperize, dense_wrapper_classes(@variant, @shape, @errors), @class)}
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
        class="pointer-events-none absolute right-3 top-1/2 size-0 -translate-y-1/2 border-x-4 border-t-4 border-x-transparent border-t-pp-outline"
      />
    </div>
    """
  end

  def pp_select(assigns) do
    assigns = assign(assigns, :normalized_options, Enum.map(assigns.options, &normalize_option/1))

    ~H"""
    <div data-pp-component="select" class={Helpers.classes(@paperize, "flex flex-col gap-1", @class)}>
      <div class={Helpers.classes(@paperize, wrapper_classes(@variant, @shape, @errors), nil)}>
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
          class="pointer-events-none absolute right-3 top-1/2 size-0 -translate-y-1/2 border-x-4 border-t-4 border-x-transparent border-t-pp-outline"
        />
        <label :if={@label} for={@id} class={Helpers.classes(@paperize, label_classes(@errors), nil)}>
          {@label}
        </label>
      </div>
      <p :if={@helper_text && @errors == []} class="text-xs text-pp-outline">{@helper_text}</p>
      <p :for={msg <- @errors} class="text-xs text-pp-error">{msg}</p>
    </div>
    """
  end

  defp normalize_option({label, value}), do: {label, value}
  defp normalize_option(value), do: {to_string(value), value}

  defp wrapper_classes("outlined", shape, []) do
    [
      "relative flex h-14 items-end border border-pp-outline transition-colors focus-within:border-2 focus-within:border-pp-primary",
      Shape.class(shape)
    ]
  end

  defp wrapper_classes("outlined", shape, _errors) do
    ["relative flex h-14 items-end border-2 border-pp-error", Shape.class(shape)]
  end

  defp wrapper_classes("filled", shape, []) do
    [
      "relative flex h-14 items-end border-b border-pp-outline bg-pp-surface-variant transition-colors focus-within:border-b-2 focus-within:border-pp-primary",
      Shape.class(shape, :top)
    ]
  end

  defp wrapper_classes("filled", shape, _errors) do
    [
      "relative flex h-14 items-end border-b-2 border-pp-error bg-pp-surface-variant",
      Shape.class(shape, :top)
    ]
  end

  # `<select>` centers its displayed value vertically inside its own box
  # regardless of asymmetric padding-top/-bottom (unlike a plain `<input>`,
  # which respects it literally) — so getting clearance for the label above
  # can't be done by just padding the select more on top. Instead the select
  # keeps small, symmetric padding and is pinned to the bottom of the fixed-
  # height `h-14 items-end` wrapper above, leaving the label's space free at
  # the top without fighting the select's own centering.
  defp select_classes do
    "peer block w-full cursor-pointer appearance-none bg-transparent px-3 py-2 pr-8 text-sm text-pp-on-surface outline-none disabled:cursor-not-allowed disabled:opacity-40"
  end

  # `hide_label` variant — compact box, `items-center` (no reserved label
  # space at the top like the fixed-height `h-14 items-end` wrapper has).
  defp dense_wrapper_classes("outlined", shape, []) do
    [
      "relative flex items-center border border-pp-outline transition-colors focus-within:border-2 focus-within:border-pp-primary",
      Shape.class(shape)
    ]
  end

  defp dense_wrapper_classes("outlined", shape, _errors) do
    ["relative flex items-center border-2 border-pp-error", Shape.class(shape)]
  end

  defp dense_wrapper_classes("filled", shape, []) do
    [
      "relative flex items-center border-b border-pp-outline bg-pp-surface-variant transition-colors focus-within:border-b-2 focus-within:border-pp-primary",
      Shape.class(shape, :top)
    ]
  end

  defp dense_wrapper_classes("filled", shape, _errors) do
    [
      "relative flex items-center border-b-2 border-pp-error bg-pp-surface-variant",
      Shape.class(shape, :top)
    ]
  end

  defp dense_select_classes do
    "peer block w-full cursor-pointer appearance-none bg-transparent px-3 py-2 pr-8 text-sm text-pp-on-surface outline-none disabled:cursor-not-allowed disabled:opacity-40"
  end

  defp label_classes([]) do
    "pointer-events-none absolute left-3 top-2 text-xs text-pp-outline transition-all peer-focus:text-pp-primary"
  end

  defp label_classes(_errors) do
    "pointer-events-none absolute left-3 top-2 text-xs text-pp-error transition-all"
  end
end
