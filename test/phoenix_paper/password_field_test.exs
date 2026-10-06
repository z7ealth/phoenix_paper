defmodule PhoenixPaper.PasswordFieldTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.PasswordField

  test "field= populates name/id/value from the form field" do
    form = Phoenix.Component.to_form(%{"password" => "s3cret"}, as: :user)
    assigns = %{form: form}

    html =
      rendered_to_string(~H"<.pp_password_field field={@form[:password]} label='Password' />")

    assert html =~ ~s(id="user_password")
    assert html =~ ~s(name="user[password]")
    assert html =~ ~s(value="s3cret")
  end

  test "an MD3 text field of type password with a trailing visibility toggle" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_password_field name='pw' label='Password' autocomplete='current-password' />"
      )

    assert html =~ ~s(data-pp-component="text-field")
    [input] = Regex.run(~r/<input[^>]*id="pw"[^>]*>/, html)
    assert input =~ ~s(type="password")
    assert input =~ ~s(autocomplete="current-password")

    assert html =~ ~s(data-pp-adornment="end")
    assert html =~ ~s(aria-label="Show password")
    assert html =~ ~s(aria-pressed="false")
    assert html =~ ~s(aria-controls="pw")
    assert html =~ "hero-eye"
    assert html =~ "hero-eye-slash"
  end

  test "the toggle flips aria-pressed and the input's type with JS commands (kept across patches)" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_password_field name='pw' label='Password' />")

    [click] = Regex.run(~r/phx-click="([^"]*)"/, html, capture: :all_but_first)
    ops = click |> String.replace("&quot;", "\"") |> Jason.decode!()

    assert ["toggle_attr", %{"attr" => ["aria-pressed", "true", "false"]}] in ops
    assert ["toggle_attr", %{"to" => "#pw", "attr" => ["type", "text", "password"]}] in ops
  end

  test "disabled disables the field and the toggle; paperize false drops the skin" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_password_field name='pw' label='P' disabled paperize={false} class='mine' />"
      )

    assert html =~ "mine"
    assert length(Regex.scan(~r/\sdisabled[=\s>]/, html)) == 2
    refute html =~ "<fieldset"
  end
end
