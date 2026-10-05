defmodule PhoenixPaper.RadioGroup do
  @moduledoc """
  A Material Design radio group (`pp_radio_group/1`) — a labeled set of
  mutually exclusive radio buttons sharing one `name`.

  Accepts either a Phoenix `Phoenix.HTML.FormField` via `field=` or plain
  `name`/`value` attrs.

  MD3 look: a 20dp ring (2dp `on-surface-variant`, `primary` when
  selected) whose 10dp dot springs in, inside a 40dp state layer that
  reacts anywhere on the option's label. `error` paints it in the error
  role. The group label is `title-small`, options `body-large`.

  `ripple={true}` adds the centered ripple on click — off by default,
  since the dot is feedback enough — see `PhoenixPaper.Ripple`.
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
  attr(:error, :boolean, default: false)
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
      <legend :if={@label} class={Helpers.classes(@paperize, "mb-1 p-0 pp-title-small text-pp-on-surface-variant", nil)}>
        {@label}
      </legend>

      <label :for={{opt_label, opt_value} <- @normalized_options} class={Helpers.toggle_label_classes(nil)}>
        <span
          :if={@paperize}
          class="relative -m-2.5 inline-flex size-10 shrink-0 items-center justify-center rounded-full has-[:disabled]:opacity-38"
          onclick={Ripple.on_click_centered(@ripple?)}
        >
          <input
            type="radio"
            name={@name}
            value={opt_value}
            checked={to_string(opt_value) == to_string(@value)}
            disabled={@disabled}
            aria-invalid={@error && "true"}
            class="peer absolute inset-0 z-10 m-0 cursor-pointer opacity-0 disabled:cursor-default"
            {@rest}
          />
          <span class={["pp-state-layer-target absolute inset-0 rounded-full", layer_color(@error)]} />
          <span class={ring_classes(@error)}>
            <span class={dot_classes(@error)} />
          </span>
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

        <span class={@paperize && "pp-body-large text-pp-on-surface"}>{opt_label}</span>
      </label>
    </fieldset>
    """
  end

  defp layer_color(false), do: "text-pp-on-surface peer-checked:text-pp-primary"
  defp layer_color(true), do: "text-pp-error"

  # MD3: a 20dp ring (2dp on-surface-variant, primary when selected) with a
  # 10dp dot that springs in.
  defp ring_classes(false),
    do:
      "pointer-events-none relative inline-flex size-5 items-center justify-center rounded-full border-2 border-pp-on-surface-variant transition-colors peer-checked:border-pp-primary"

  defp ring_classes(true),
    do:
      "pointer-events-none relative inline-flex size-5 items-center justify-center rounded-full border-2 border-pp-error"

  defp dot_classes(false),
    do:
      "size-2.5 scale-0 rounded-full bg-pp-primary pp-motion-spatial-fast [:checked~span>&]:scale-100"

  defp dot_classes(true),
    do:
      "size-2.5 scale-0 rounded-full bg-pp-error pp-motion-spatial-fast [:checked~span>&]:scale-100"

  defp normalize_option({label, value}), do: {label, value}
  defp normalize_option(value), do: {to_string(value), value}
end
