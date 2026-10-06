defmodule PhoenixPaper.AutocompleteTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  alias PhoenixPaper.Autocomplete

  @endpoint PhoenixPaper.TestEndpoint

  @options [{"Canada", "ca"}, {"México", "mx"}, {"United States", "us"}]

  defmodule Host do
    use Phoenix.LiveView

    def mount(_params, %{"opts" => opts, "test" => test}, socket) do
      {:ok,
       assign(socket,
         opts: :erlang.binary_to_term(opts),
         test: :erlang.binary_to_term(test),
         form: to_form(%{"country" => "ca"}, as: :address)
       )}
    end

    def render(assigns) do
      ~H"""
      <.form for={@form} id="address-form" phx-change="validate">
        <.live_component
          module={PhoenixPaper.Autocomplete}
          id="country"
          field={@form[:country]}
          label="Country"
          {@opts}
        />
      </.form>
      """
    end

    def handle_event("validate", params, socket) do
      send(socket.assigns.test, {:validate, params})
      {:noreply, socket}
    end

    def handle_info({:changed, value}, socket) do
      send(socket.assigns.test, {:on_change, value})
      {:noreply, socket}
    end
  end

  defp mount_autocomplete(opts \\ []) do
    test = self()

    opts =
      opts
      |> Keyword.put_new(:options, @options)
      |> Keyword.put_new(:on_change, fn value -> send(self(), {:changed, value}) end)

    {:ok, view, html} =
      live_isolated(Phoenix.ConnTest.build_conn(), Host,
        session: %{
          "opts" => :erlang.term_to_binary(Map.new(opts)),
          "test" => :erlang.term_to_binary(test)
        }
      )

    {view, html}
  end

  test "renders an MD3 text field showing the selected label, and a hidden input with the value" do
    {_view, html} = mount_autocomplete()

    [query] = Regex.run(~r/<input[^>]*id="country-query"[^>]*>/, html)
    assert query =~ ~s(value="Canada")
    assert query =~ ~s(role="combobox")
    assert query =~ ~s(aria-expanded="false")
    assert html =~ ~s(data-pp-component="text-field")

    assert html =~
             ~r/<input type="hidden" id="country-value" name="address\[country\]" value="ca"/

    refute html =~ ~s(role="listbox")
  end

  test "the text box is detached from the form: no name, a form id that doesn't exist" do
    {_view, html} = mount_autocomplete()

    refute html =~ "<form id=\"country-detached\""
    [query] = Regex.run(~r/<input[^>]*id="country-query"[^>]*>/, html)
    assert query =~ ~s(form="country-detached")
    assert query =~ ~s(phx-keyup="query")
    assert query =~ ~s(phx-focus="open")
    assert query =~ "phx-target="
    refute query =~ "name="
  end

  test "focusing opens the MD3 menu surface with every option, the selected one marked" do
    {view, _} = mount_autocomplete()

    html = view |> element("#country-query") |> render_focus()
    assert html =~ ~s(role="listbox")
    assert html =~ "bg-pp-surface-container"
    assert html =~ "rounded-pp-lg"
    # Anchored to the field box through the text field's :menu slot.
    assert html =~ ~r/<\/fieldset>\s*<div[^>]*id="country-listbox"/
    assert html =~ "absolute inset-x-0 top-full"
    assert html =~ "United States"
    assert html =~ ~r/aria-selected="true"[^>]*>\s*<span[^>]*>Canada/
  end

  test "typing filters by label, ignoring case and accents" do
    {view, _} = mount_autocomplete()

    html = view |> element("#country-query") |> render_keyup(%{"value" => "mexi"})
    assert html =~ "México"
    refute html =~ "United States"
    refute html =~ ">Canada<"

    html = view |> element("#country-query") |> render_keyup(%{"value" => "zzz"})
    assert html =~ "No results"
  end

  test "picking an option commits it, closes the list and tells the form" do
    {view, _} = mount_autocomplete()

    view |> element("#country-query") |> render_focus()
    html = view |> element("button[role=option]", "United States") |> render_click()

    refute html =~ ~s(role="listbox")
    assert html =~ ~r/id="country-value" name="address\[country\]" value="us"/
    assert html =~ "country-changed-1"
    assert_receive {:on_change, "us"}
  end

  test "clearing the text clears the value" do
    {view, _} = mount_autocomplete()

    html = view |> element("#country-query") |> render_keyup(%{"value" => ""})
    refute html =~ ~s(value="ca")
    assert_receive {:on_change, nil}
  end

  test "disabled renders a natively disabled field, which can't be focused to open" do
    {_view, html} = mount_autocomplete(disabled: true)

    [query] = Regex.run(~r/<input[^>]*id="country-query"[^>]*>/, html)
    assert query =~ ~r/\sdisabled[=\s>]/
    refute html =~ ~s(role="listbox")
  end

  test "renders statelessly too, with paperize false dropping the skin" do
    html =
      render_component(Autocomplete,
        id: "c",
        name: "c",
        label: "Country",
        options: ["Canada"],
        paperize: false,
        class: "mine"
      )

    assert html =~ "mine"
    refute html =~ "bg-pp-surface-container"
    refute html =~ "flex flex-col gap-1"
  end

  describe "multiple" do
    test "the value is a list of input chips, submitted as name[] with an empty sentinel" do
      {_view, html} = mount_autocomplete(multiple: true)

      # MD3: the chips sit inside the field box, before the text box, and
      # the label stays raised.
      assert html =~ ~r/flex-wrap items-center gap-2[^>]*>\s*<div[^>]*data-pp-component="chip"/
      assert html =~ ~r/data-pp-component="chip".*<input[^>]*id="country-query"/s
      [label] = Regex.run(~r/<label[^>]*for="country-query"[^>]*>/, html)
      assert label =~ "top-0 -translate-y-1/2"

      assert html =~ ~s(data-pp-component="chip")
      assert html =~ ~s(aria-label="Remove Canada")
      assert html =~ ~r/id="country-value" name="address\[country\]\[\]" value=""/
      assert html =~ ~r/name="address\[country\]\[\]" value="ca"/
      [query] = Regex.run(~r/<input[^>]*id="country-query"[^>]*>/, html)
      assert query =~ ~s(value="")
    end

    test "picking adds a chip and keeps the list open; picking a selected option removes it" do
      {view, _} = mount_autocomplete(multiple: true)

      view |> element("#country-query") |> render_focus()
      html = view |> element("button[role=option]", "United States") |> render_click()

      assert html =~ ~s(role="listbox")
      assert html =~ ~s(aria-multiselectable="true")
      assert html =~ ~r/name="address\[country\]\[\]" value="us"/
      assert html =~ ~r/name="address\[country\]\[\]" value="ca"/
      assert_receive {:on_change, ["ca", "us"]}

      html = view |> element("button[role=option]", "Canada") |> render_click()
      refute html =~ ~r/name="address\[country\]\[\]" value="ca"/
      assert_receive {:on_change, ["us"]}
    end

    test "a chip's remove control removes that value and tells the form" do
      {view, _} = mount_autocomplete(multiple: true)

      html = view |> element("[aria-label='Remove Canada']") |> render_click()
      refute html =~ ~s(data-pp-component="chip")
      assert html =~ ~r/id="country-value" name="address\[country\]\[\]" value=""/
      assert html =~ "country-changed-1"
      assert_receive {:on_change, []}
    end

    test "with nothing picked there's no chip row and the label rests as usual" do
      {view, _} = mount_autocomplete(multiple: true)

      html = view |> element("[aria-label='Remove Canada']") |> render_click()
      refute html =~ ~s(data-pp-component="chip")
      [label] = Regex.run(~r/<label[^>]*for="country-query"[^>]*>/, html)
      assert label =~ "top-1/2"
      refute html =~ ~r/>\s*false\s*</
    end

    test "Backspace on an empty box removes the last chip (inline keydown)" do
      {_view, html} = mount_autocomplete(multiple: true)

      assert html =~ "Backspace"
      assert html =~ "[data-pp-component=chip-delete]"
    end
  end
end
