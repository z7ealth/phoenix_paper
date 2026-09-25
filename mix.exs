defmodule PhoenixPaper.MixProject do
  use Mix.Project

  @version "0.2.7"
  @source_url "https://github.com/z7ealth/phoenix_paper"
  @description "A Material Design component library for Phoenix and LiveView, styled with Tailwind CSS."

  def project do
    [
      app: :phoenix_paper,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: @description,
      package: package(),
      docs: docs(),
      name: "PhoenixPaper",
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 1.0"},
      # `phoenix_live_view` only lists `jason` as an *optional* dependency,
      # but `Phoenix.LiveView.JS.to_iodata/1` needs it at runtime to encode
      # its command payloads — used by `Tabs`/`Dialog`. This library used
      # to get `jason` for free transitively through `tails` (which
      # required it); now that `tails` is gone, it needs to be a direct
      # dependency here or those components break at render time in any
      # consuming app that doesn't happen to pull `jason` in some other way.
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Héctor Salinas"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @source_url <> "/blob/master/CHANGELOG.md"
      },
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md AGENTS.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md", "AGENTS.md", "LICENSE"]
    ]
  end
end
