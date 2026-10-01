defmodule PhoenixPaper.PowerSelectTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  alias PhoenixPaper.PowerSelect

  @endpoint PhoenixPaper.TestEndpoint

  @countries [{"Canada", "ca"}, {"México", "mx"}, {"United States", "us"}]

  # A real LiveView around the component: its events are where the behavior
  # lives. `opts` (from the session) become the component's attrs; the form's
  # `validate` and `on_change` both report back to the test process.
  defmodule Host do
    use Phoenix.LiveView

    def mount(_params, %{"opts" => opts, "test" => test}, socket) do
      {:ok,
       assign(socket,
         opts: :erlang.binary_to_term(opts),
         test: :erlang.binary_to_term(test),
         form: to_form(%{}, as: :trip)
       )}
    end

    def render(assigns) do
      ~H"""
      <.form for={@form} id="trip-form" phx-change="validate">
        <.live_component module={PowerSelect} id="country" field={@form[:country]} {@opts} />
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

  defp mount_select(opts) do
    test = self()

    opts =
      Keyword.put_new(opts, :on_change, fn value -> send(self(), {:changed, value}) end)

    {:ok, view, _html} =
      live_isolated(build_conn(), Host,
        session: %{
          "opts" => :erlang.term_to_binary(Map.new(opts)),
          "test" => :erlang.term_to_binary(test)
        }
      )

    view
  end

  defp build_conn, do: Phoenix.ConnTest.build_conn()

  defp option(view, label), do: element(view, "#country-listbox button[role=option]", label)

  describe "normalize_text/1" do
    test "folds case and accents, including letters NFD doesn't split" do
      assert PowerSelect.normalize_text("MARÍA Søren Œuvre Straße") ==
               "maria soren oeuvre strasse"
    end
  end

  describe "filter_options/3" do
    setup do
      config = %{label_field: :label, value_field: :value, search_field: nil}

      tree =
        PowerSelect.normalize_options(
          [
            %{group_name: "Nordic", options: ["Søren", "Astrid"]},
            %{
              group_name: "Latin",
              options: ["María", %{group_name: "Nested", options: ["Mario"]}]
            }
          ],
          config
        )

      %{tree: tree}
    end

    test "keeps matching options and drops groups left empty", %{tree: tree} do
      assert [%{label: "Latin", options: [%{label: "María"}, %{label: "Nested"}]}] =
               PowerSelect.filter_options(tree, "mari", nil)

      assert [%{label: "Nordic", options: [%{label: "Søren"}]}] =
               PowerSelect.filter_options(tree, "soren", nil)
    end

    test "a custom matcher receives the original option and the term", %{tree: tree} do
      matcher = fn option, term -> String.ends_with?(option, term) end

      assert [%{label: "Nordic", options: [%{label: "Astrid"}]}] =
               PowerSelect.filter_options(tree, "rid", matcher)
    end
  end

  describe "static render" do
    test "a single select with a label, a selected value, and every option in the closed list" do
      html =
        render_component(PowerSelect,
          id: "country",
          name: "trip[country]",
          label: "Country",
          options: @countries,
          value: "mx"
        )

      assert html =~ ~s(data-pp-component="power-select")
      assert html =~ ~s(role="combobox")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~r/<input type="hidden" id="country-value" name="trip\[country\]" value="mx"/
      assert [_, trigger] = Regex.run(~r/id="country-trigger".*?>(.*?)<\/button>/s, html)
      assert trigger =~ "México"
      assert html =~ ~r/aria-selected="true"[^>]*>\s*México/
      assert html =~ "Canada"
      assert html =~ "absolute inset-x-0 top-full z-40 mt-1 hidden"
      refute html =~ ~s(id="country-search")
    end

    test "search_enabled adds a search box detached from any surrounding form" do
      html =
        render_component(PowerSelect,
          id: "country",
          name: "country",
          options: @countries,
          search_enabled: true,
          search_placeholder: "Find…"
        )

      [search] = Regex.run(~r/<input[^>]*data-pp-search[^>]*>/, html)
      assert search =~ ~s(form="country-detached")
      assert search =~ ~s(phx-keyup="search")
      assert search =~ ~s(phx-debounce="300")
      assert search =~ ~s(placeholder="Find…")
      refute search =~ "name="
    end

    test "groups, disabled options and disabled groups" do
      html =
        render_component(PowerSelect,
          id: "food",
          options: [
            %{group_name: "Fruit", options: ["Apple", %{label: "Durian", disabled: true}]},
            %{group_name: "Closed", disabled: true, options: ["Leek"]}
          ]
        )

      assert html =~ ~s(role="group")
      assert html =~ "Fruit"
      assert html =~ ~r/<button[^>]*\sdisabled[\s>][^>]*>\s*Durian/
      assert html =~ ~r/<button[^>]*\sdisabled[\s>][^>]*>\s*Leek/
      refute html =~ ~r/<button[^>]*\sdisabled[\s>][^>]*>\s*Apple/
    end

    test "map options use label_field/value_field" do
      html =
        render_component(PowerSelect,
          id: "user",
          name: "user_id",
          options: [%{id: 7, name: "Ada"}, %{id: 9, name: "Grace"}],
          label_field: :name,
          value_field: :id,
          value: 9
        )

      assert html =~ ~s(value="9")
      assert html =~ ~r/id="user-trigger".*?Grace/s
    end

    test "multiple renders chips and one name[] input per value" do
      html =
        render_component(PowerSelect,
          id: "tags",
          name: "tags",
          options: ["elixir", "phoenix", "tailwind"],
          multiple: true,
          search_enabled: true,
          value: ["elixir", "tailwind"]
        )

      assert html =~ ~s(id="tags-value" name="tags[]" value="elixir")
      assert html =~ ~s(name="tags[]" value="tailwind")
      assert html =~ ~s(aria-label="Remove elixir")
      assert html =~ ~s(aria-multiselectable="true")
      refute html =~ ~s(value="phoenix")
    end

    test "multiple with nothing picked submits one empty value" do
      html =
        render_component(PowerSelect, id: "tags", name: "tags", options: ["a"], multiple: true)

      assert html =~ ~s(<input type="hidden" id="tags-value" name="tags" value="")
    end

    test "paperize={false} drops built-in classes, keeps positioning and the caller class" do
      html =
        render_component(PowerSelect,
          id: "country",
          options: @countries,
          paperize: false,
          class: "my-select"
        )

      assert html =~ ~s(class="my-select")
      assert html =~ "absolute inset-x-0 top-full z-40"
      refute html =~ "border-pp-outline"
      refute html =~ "aria-selected:bg-pp-primary/10"
    end
  end

  describe "in a LiveView" do
    test "searching filters accent-insensitively and shows the no-matches message" do
      view = mount_select(options: @countries, search_enabled: true)

      html = view |> element("#country-search") |> render_keyup(%{"value" => "mex"})
      assert html =~ "México"
      refute html =~ "Canada"

      html = view |> element("#country-search") |> render_keyup(%{"value" => "zzz"})
      assert html =~ "No results found"
    end

    test "picking an option updates the hidden input, calls on_change and resets the search" do
      view = mount_select(options: @countries, search_enabled: true)

      view |> element("#country-search") |> render_keyup(%{"value" => "can"})
      html = view |> option("Canada") |> render_click()

      assert html =~ ~r/id="country-value" name="trip\[country\]" value="ca"/
      assert html =~ ~s(id="country-changed-1")
      assert html =~ "United States"
      assert_receive {:on_change, "ca"}
    end

    test "allow_clear clears the selection" do
      view = mount_select(options: @countries, allow_clear: true)

      view |> option("Canada") |> render_click()
      html = view |> element("[aria-label=Clear]") |> render_click()

      assert html =~ ~r/id="country-value" name="trip\[country\]" value=""/
      assert_receive {:on_change, nil}
    end

    test "multiple toggles options and removes chips" do
      view = mount_select(options: @countries, multiple: true, search_enabled: true)

      view |> option("Canada") |> render_click()
      html = view |> option("México") |> render_click()
      assert html =~ ~s(name="trip[country][]" value="ca")
      assert html =~ ~s(name="trip[country][]" value="mx")
      assert_receive {:on_change, ["ca", "mx"]}

      view |> option("Canada") |> render_click()
      assert_receive {:on_change, ["mx"]}

      html = view |> element("[aria-label='Remove México']") |> render_click()
      assert html =~ ~s(id="country-value" name="trip[country]" value="")
      assert_receive {:on_change, []}
    end

    test "a disabled option can't be picked" do
      view = mount_select(options: [%{label: "Off", value: "off", disabled: true}, "On"])

      view |> with_target("#country") |> render_click("select", %{"key" => "off"})
      assert render(view) =~ ~r/id="country-value" name="trip\[country\]" value=""/
      refute_receive {:on_change, _}
    end

    test "async search shows the loading message, then only the latest term's results" do
      search = fn term ->
        if term == "slow", do: Process.sleep(200)
        [{"Result for #{term}", term}]
      end

      view = mount_select(search: search)

      html = view |> element("#country-search") |> render_keyup(%{"value" => ""})
      assert html =~ "Type to search"

      html = view |> element("#country-search") |> render_keyup(%{"value" => "slow"})
      assert html =~ "Loading options…"

      view |> element("#country-search") |> render_keyup(%{"value" => "fast"})
      html = render_async(view, 1000)
      assert html =~ "Result for fast"
      refute html =~ "Result for slow"

      html = view |> option("Result for fast") |> render_click()
      assert html =~ ~r/id="country-value" name="trip\[country\]" value="fast"/
      assert_receive {:on_change, "fast"}
    end

    test "the parent's value is re-read only when it changes" do
      view = mount_select(options: @countries, value: "us")
      assert render(view) =~ ~r/value="us"/

      html = view |> option("Canada") |> render_click()
      assert html =~ ~r/id="country-value" name="trip\[country\]" value="ca"/

      # An unrelated parent re-render still passes the old value.
      send(view.pid, {:changed, :noop})
      assert render(view) =~ ~r/id="country-value" name="trip\[country\]" value="ca"/
    end
  end

  describe "JS commands" do
    test "a single pick pushes select, closes and refocuses the trigger" do
      %Phoenix.LiveView.JS{ops: ops} = PowerSelect.pick("c", 1, "ca", false, true)

      assert [
               ["push", %{event: "select", value: %{key: "ca"}, target: 1}],
               ["hide", %{to: "#c-panel"}],
               ["set_attr", %{attr: ["aria-expanded", "false"], to: "#c-trigger"}],
               ["focus", %{to: "#c-trigger"}]
             ] = ops
    end

    test "a multiple pick stays open and refocuses the search box" do
      %Phoenix.LiveView.JS{ops: ops} = PowerSelect.pick("c", 1, "ca", true, true)
      assert [["push", _], ["focus", %{to: "#c-search"}]] = ops
    end
  end
end
