defmodule PhoenixPaper.NumberField do
  @moduledoc """
  A number field (`pp_number_field/1`): an MD3 text field (`type="number"`)
  with decrease/increase steppers as trailing MD3 icon buttons.

      <.pp_number_field field={@form[:quantity]} label="Quantity" min="1" max="10" />

  MD3 has no number field, so this is a composite of MD3 parts: the field
  is a `pp_text_field` (`outlined` or `filled`, floating label, supporting
  text and errors, `field=`), and the steppers are 40dp standard
  `pp_icon_button`s. The browser's own spinner is hidden.

  The steppers call the input's native `stepUp()`/`stepDown()` (so `min`,
  `max` and `step` apply) and dispatch a real `input` event, so the form's
  `phx-change` and `phx-debounce` fire as if the user had typed — a small
  inline `onclick`, no JS hook. They're `tabindex="-1"`: keyboard users
  already have Arrow Up/Down in the number input itself.

  The steppers find the input by its id, so give it an `id`, a `name` or
  a `field`.

  ## Migrating from 0.4

  The label now floats inside the field like every MD3 text field's
  (it used to sit above the box), and both steppers sit at the trailing
  end.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.IconButton, only: [pp_icon_button: 1]
  import PhoenixPaper.TextField, only: [pp_text_field: 1]

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:min, :any, default: nil)
  attr(:max, :any, default: nil)
  attr(:step, :any, default: 1)
  attr(:variant, :string, default: "outlined", values: ~w(outlined filled))
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:errors, :list, default: [])
  attr(:supporting_text, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:decrease_label, :string, default: "Decrease")
  attr(:increase_label, :string, default: "Increase")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(autocomplete autofocus form readonly required))

  @doc "Renders a number field. See the module doc."
  def pp_number_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil)
    |> assign(:name, assigns.name || field.name)
    |> assign(:id, assigns.id || field.id)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Helpers.translate_error/1))
    |> pp_number_field()
  end

  def pp_number_field(assigns) do
    assigns = assign(assigns, :input_id, assigns.id || assigns.name)

    ~H"""
    <.pp_text_field
      type="number"
      id={@input_id}
      name={@name}
      label={@label}
      value={@value}
      variant={@variant}
      errors={@errors}
      supporting_text={@supporting_text}
      disabled={@disabled}
      paperize={@paperize}
      min={@min}
      max={@max}
      step={@step}
      data-pp-component="number-field"
      class={[@paperize && spinner_classes(), @class]}
      {@rest}
    >
      <:end_adornment>
        <span class="-me-2 flex items-center">
          <.pp_icon_button
            icon="hero-minus"
            label={@decrease_label}
            ripple={false}
            disabled={@disabled}
            paperize={@paperize}
            tabindex="-1"
            onclick={step_script(@input_id, "stepDown")}
          />
          <.pp_icon_button
            icon="hero-plus"
            label={@increase_label}
            ripple={false}
            disabled={@disabled}
            paperize={@paperize}
            tabindex="-1"
            onclick={step_script(@input_id, "stepUp")}
          />
        </span>
      </:end_adornment>
    </.pp_text_field>
    """
  end

  defp step_script(id, fun) do
    "var i=document.getElementById(#{inspect(to_string(id))});i.#{fun}();i.dispatchEvent(new Event('input',{bubbles:true}))"
  end

  # Hides the browser's own number spinner, which the steppers replace.
  defp spinner_classes do
    "[&_input]:[appearance:textfield] [&_input::-webkit-inner-spin-button]:appearance-none [&_input::-webkit-outer-spin-button]:appearance-none"
  end
end
