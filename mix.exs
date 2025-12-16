defmodule Sashite.Epin.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/sashite/epin.ex"

  def project do
    [
      app: :sashite_epin,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Documentation
      name: "Sashite.Epin",
      source_url: @source_url,
      homepage_url: "https://sashite.dev/specs/epin/",
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:sashite_pin, "~> 1.1"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    EPIN (Extended Piece Identifier Notation) implementation for Elixir.
    Extends PIN by adding a derivation marker to track piece style in cross-style
    abstract strategy board games with a minimal compositional API.
    """
  end

  defp package do
    [
      name: "sashite_epin",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Specification" => "https://sashite.dev/specs/epin/1.0.0/",
        "Documentation" => "https://hexdocs.pm/sashite_epin"
      },
      maintainers: ["Cyril Kato"]
    ]
  end
end
