# `tails` only recognizes color names for merge/conflict purposes if it's
# told about them — otherwise (e.g. combining a Tailwind font-size utility
# with one of our `text-pp-*` custom color classes in the same `class={}`)
# it can silently drop one of the two, since it can't tell they're
# different CSS properties sharing the same `text-` prefix. `tails`'s
# extension point for this (`color_classes:`) reads via
# `Application.compile_env/2`, which needs the *same* value present at two
# different times for two different reasons — both are needed together,
# neither alone is enough (see AGENTS.md, "PhoenixPaper.Tails, not plain
# Tails", for the full story of finding this out the hard way):
#
#   1. Visible when `PhoenixPaper.Tails` itself compiles (early — before
#      the compiled `.app` resource exists or the OTP application is
#      loaded) — only a plain `Application.put_env/3` run at that point
#      achieves this. A `config/config.exs` file is too late/inapplicable:
#      Mix ignores it for dependencies entirely. This is the `put_env`
#      call below — `mix.exs` is guaranteed to run before any of this
#      package's `lib/*.ex`, since Mix always evaluates a dependency's
#      `mix.exs` first to learn how to build it.
#   2. Present when the OTP application actually *starts* (later — Mix
#      validates that a `compile_env` read matches the env the started
#      application was loaded with, and application loading resets env
#      from the compiled `.app` resource, discarding the ad-hoc `put_env`
#      from step 1). Only `application/0`'s `env:` key below — baked
#      directly into that `.app` resource — achieves this.
color_classes = ~w(
  pp-primary pp-secondary pp-tertiary pp-error
  pp-surface pp-surface-variant pp-outline
  pp-on-primary pp-on-secondary pp-on-tertiary pp-on-error pp-on-surface
)

Application.put_env(:phoenix_paper, PhoenixPaper.Tails, color_classes: color_classes)

defmodule PhoenixPaper.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_paper,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      env: [{PhoenixPaper.Tails, Application.get_env(:phoenix_paper, PhoenixPaper.Tails)}]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 1.0"},
      {:tails, "~> 0.1.11"}
    ]
  end
end
