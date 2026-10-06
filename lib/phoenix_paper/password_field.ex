defmodule PhoenixPaper.PasswordField do
  @moduledoc """
  A password field (`pp_password_field/1`): an MD3 text field
  (`type="password"`) with MD3's trailing visibility toggle.

      <.pp_password_field field={@form[:password]} label="Password" autocomplete="current-password" />

  It's a `pp_text_field` (`outlined` or `filled`, floating label,
  supporting text, errors, `field=`) whose trailing icon is a
  `pp_icon_button` toggle: `hero-eye` while hidden, `hero-eye-slash`
  while shown, with `aria-pressed` saying which. MD3 shows exactly this
  pattern in its text field guidance (a visibility icon as the trailing
  icon).

  The toggle runs on the client with no round trip: the icon button's
  own `toggle` flips `aria-pressed`, and its `on_toggle` flips the
  input's `type` between `password` and `text` with
  `JS.toggle_attribute/2`. LiveView keeps attributes set by JS commands
  across patches, so a re-render (a validation error, say) doesn't hide
  the password again behind the user's back.

  The toggle finds the input by its id, so give it an `id`, a `name` or a
  `field`. `show_label` (default `"Show password"`) is the toggle's
  accessible name.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.Helpers
  import PhoenixPaper.IconButton, only: [pp_icon_button: 1]
  import PhoenixPaper.TextField, only: [pp_text_field: 1]

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:variant, :string, default: "outlined", values: ~w(outlined filled))
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:errors, :list, default: [])
  attr(:supporting_text, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:show_label, :string, default: "Show password")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include: ~w(autocomplete autofocus form maxlength minlength pattern readonly required)
  )

  @doc "Renders a password field. See the module doc."
  def pp_password_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil)
    |> assign(:name, assigns.name || field.name)
    |> assign(:id, assigns.id || field.id)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Helpers.translate_error/1))
    |> pp_password_field()
  end

  def pp_password_field(assigns) do
    assigns = assign(assigns, :input_id, assigns.id || assigns.name)

    ~H"""
    <.pp_text_field
      type="password"
      id={@input_id}
      name={@name}
      label={@label}
      value={@value}
      variant={@variant}
      errors={@errors}
      supporting_text={@supporting_text}
      disabled={@disabled}
      paperize={@paperize}
      class={@class}
      {@rest}
    >
      <:end_adornment>
        <span class="-me-2 flex items-center">
          <.pp_icon_button
            icon="hero-eye"
            selected_icon="hero-eye-slash"
            label={@show_label}
            toggle
            selected={false}
            on_toggle={JS.toggle_attribute({"type", "text", "password"}, to: "##{@input_id}")}
            disabled={@disabled}
            paperize={@paperize}
            aria-controls={@input_id}
          />
        </span>
      </:end_adornment>
    </.pp_text_field>
    """
  end
end
