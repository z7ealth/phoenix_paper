defmodule PhoenixPaper.RadioGroup do
  @moduledoc """
  A Material Design radio group (`pp_radio_group/1`) — a labeled set of
  mutually exclusive radio buttons sharing one `name`.

  Accepts either a Phoenix `Phoenix.HTML.FormField` via `field=` or plain
  `name`/`value` attrs.

  `ripple={true}` adds the Material ripple effect on click/tap, wired to
  each option's small box rather than its whole label — off by default
  (unlike `Button`/`Fab`/`ToggleButton`), since a radio's own instant
  fill/border-color change already reads as clear feedback on a target
  this small — see `PhoenixPaper.Ripple`.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Ripple}

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:options, :list, required: true, doc: "list of {label, value} tuples, or plain values")
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)

  attr(:ripple, :boolean,
    default: false,
    doc: "the Material ripple effect on click/tap (default: false) — see PhoenixPaper.Ripple"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form autofocus))

  def pp_radio_group(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:name, assigns.name || field.name)
    |> assign(:id, assigns.id || field.id)
    |> assign(:value, assigns.value || field.value)
    |> pp_radio_group()
  end

  def pp_radio_group(assigns) do
    assigns =
      assigns
      |> assign(:normalized_options, Enum.map(assigns.options, &normalize_option/1))
      |> assign(:ripple?, assigns.ripple and assigns.paperize)

    ~H"""
    <fieldset
      data-pp-component="radio-group"
      class={Helpers.classes(@paperize, "flex flex-col gap-2 border-0 p-0 m-0", @class)}
    >
      <legend :if={@label} class="mb-1 p-0 text-sm font-medium text-pp-on-surface">{@label}</legend>

      <label :for={{opt_label, opt_value} <- @normalized_options} class={Helpers.toggle_label_classes(nil)}>
        <span
          :if={@paperize}
          class="has-[:checked]:border-pp-primary has-[:disabled]:opacity-40 relative inline-flex size-5 shrink-0 items-center justify-center rounded-full border-2 border-pp-outline transition-colors"
          onclick={Ripple.on_click_centered(@ripple?)}
        >
          <input
            type="radio"
            name={@name}
            value={opt_value}
            checked={to_string(opt_value) == to_string(@value)}
            disabled={@disabled}
            class="peer absolute inset-0 m-0 cursor-pointer opacity-0 disabled:cursor-not-allowed"
            {@rest}
          />
          <span class="peer-checked:scale-100 pointer-events-none size-2.5 scale-0 rounded-full bg-pp-primary transition-transform" />
        </span>

        <input
          :if={!@paperize}
          type="radio"
          name={@name}
          value={opt_value}
          checked={to_string(opt_value) == to_string(@value)}
          disabled={@disabled}
          {@rest}
        />

        <span>{opt_label}</span>
      </label>
    </fieldset>
    """
  end

  defp normalize_option({label, value}), do: {label, value}
  defp normalize_option(value), do: {to_string(value), value}
end
