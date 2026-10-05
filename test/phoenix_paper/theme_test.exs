defmodule PhoenixPaper.ThemeTest do
  use ExUnit.Case, async: true

  alias PhoenixPaper.Theme
  alias PhoenixPaper.Theme.Hct

  doctest PhoenixPaper.Theme.Hct

  describe "Hct" do
    test "matches material-color-utilities' reference values" do
      for {hex, {h, c, t}} <- [
            {"#ff0000", {27.41, 113.36, 53.24}},
            {"#00ff00", {142.14, 108.41, 87.74}},
            {"#0000ff", {282.79, 87.23, 32.30}}
          ] do
        {gh, gc, gt} = Hct.from_hex(hex)
        assert_in_delta gh, h, 0.1
        assert_in_delta gc, c, 0.1
        assert_in_delta gt, t, 0.1
      end
    end

    test "round-trips in-gamut colors" do
      for hex <- ~w(#6750a4 #ff0000 #00ff00 #123456 #fafafa #0b57d0) do
        {h, c, t} = Hct.from_hex(hex)
        assert Hct.to_hex(h, c, t) == hex
      end
    end

    test "to_hex hits the requested tone, reducing chroma to stay in gamut" do
      for tone <- [10, 30, 40, 50, 80, 90, 98] do
        {_h, _c, got} = Hct.from_hex(Hct.to_hex(282.0, 200.0, tone))
        assert_in_delta got, tone, 0.5
      end
    end

    test "grays, black and white" do
      assert Hct.to_hex(0, 0, 0) == "#000000"
      assert Hct.to_hex(0, 0, 100) == "#ffffff"
      gray = Hct.to_hex(120, 0, 50)
      {r, g, b} = Hct.parse_hex(gray)
      assert r == g and g == b
      {_h, _c, t} = Hct.from_hex(gray)
      assert_in_delta t, 50, 0.5
    end

    test "parse_hex accepts #rgb and #rrggbb, rejects junk" do
      assert Hct.parse_hex("#fff") == {255, 255, 255}
      assert Hct.parse_hex("6750A4") == {103, 80, 164}
      assert_raise ArgumentError, fn -> Hct.parse_hex("nope") end
    end
  end

  describe "schemes" do
    test "tonal spot from the MD3 baseline seed matches Material Theme Builder" do
      light = Theme.scheme("#6750a4", :light)

      assert light["primary"] == "#65558f"
      assert light["secondary"] == "#625b71"
      assert light["tertiary"] == "#7e5260"
      assert light["error"] == "#ba1a1a"
      assert light["on-error-container"] == "#93000a"
    end

    test "every role is the right tone, in light and dark" do
      for {mode, role, tone} <- [
            {:light, "primary", 40},
            {:light, "on-primary-container", 30},
            {:light, "surface-container", 94},
            {:light, "outline", 50},
            {:dark, "primary", 80},
            {:dark, "surface", 6},
            {:dark, "surface-container-highest", 22},
            {:dark, "on-surface-variant", 80}
          ] do
        {_h, _c, t} = Hct.from_hex(Theme.scheme("#0b57d0", mode)[role])
        assert_in_delta t, tone, 0.6, "#{mode} #{role}"
      end
    end

    test "variants change chroma; monochrome is gray" do
      {_, vibrant, _} =
        Hct.from_hex(Theme.scheme("#0b57d0", :light, variant: :vibrant)["primary"])

      {_, tonal, _} = Hct.from_hex(Theme.scheme("#0b57d0", :light)["primary"])
      {r, g, b} = Hct.parse_hex(Theme.scheme("#0b57d0", :light, variant: :monochrome)["primary"])

      assert vibrant > tonal
      assert r == g and g == b
    end

    test "pinned core colors replace that palette" do
      pinned = Theme.scheme("#0b57d0", :light, tertiary: "#00ff00")["tertiary"]
      {h, _c, _t} = Hct.from_hex(pinned)
      assert_in_delta h, 142.1, 3
    end

    test "status roles are included unless status: false" do
      assert Theme.scheme("#0b57d0", :light)["success-container"]
      refute Theme.scheme("#0b57d0", :light, status: false)["success"]
    end

    test "css/2 writes light, dark and the system fallback" do
      css = Theme.css("#0b57d0")

      assert css =~ ":root {"
      assert css =~ ~s([data-theme="dark"] {)
      assert css =~ "@media (prefers-color-scheme: dark)"
      assert css =~ "--color-pp-surface-container-high:"
      assert length(String.split(css, "--color-pp-primary:")) == 4
    end
  end

  describe "mix phoenix_paper.gen.theme" do
    setup do
      dir = Path.join(System.tmp_dir!(), "pp-theme-#{System.unique_integer([:positive])}")
      on_exit(fn -> File.rm_rf!(dir) end)
      Mix.shell(Mix.Shell.Process)
      on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
      %{path: Path.join(dir, "theme.css")}
    end

    test "writes the theme file, refuses to overwrite without --force", %{path: path} do
      Mix.Tasks.PhoenixPaper.Gen.Theme.run(["--seed", "#0b57d0", "--output", path])
      assert File.read!(path) =~ "--color-pp-primary:"

      assert_raise Mix.Error, ~r/already exists/, fn ->
        Mix.Tasks.PhoenixPaper.Gen.Theme.run(["--seed", "#0b57d0", "--output", path])
      end

      Mix.Tasks.PhoenixPaper.Gen.Theme.run([
        "--seed",
        "#ff0000",
        "--scheme",
        "vibrant",
        "--output",
        path,
        "--force"
      ])

      assert File.read!(path) =~ "vibrant scheme"
    end

    test "validates its options" do
      assert_raise Mix.Error, ~r/--seed is required/, fn ->
        Mix.Tasks.PhoenixPaper.Gen.Theme.run([])
      end

      assert_raise Mix.Error, ~r/hex color/, fn ->
        Mix.Tasks.PhoenixPaper.Gen.Theme.run(["--seed", "blue"])
      end

      assert_raise Mix.Error, ~r/--scheme must be/, fn ->
        Mix.Tasks.PhoenixPaper.Gen.Theme.run(["--seed", "#0b57d0", "--scheme", "rainbow"])
      end
    end
  end
end
