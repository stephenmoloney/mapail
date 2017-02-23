defmodule Mapail.Mixfile do
  use Mix.Project

  def project do
    [
    app: :mapail,
    version: version(),
    source_url: source_url(),
    name: name(),
    elixir: "~> 1.2",
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    description: description(),
    package: package(),
    deps: deps(),
    docs: docs()
    ]
  end

  defp version(), do: "0.1.0"
  defp name(), do: "Mapail"
  defp source_url(), do: "https://github.com/stephenmoloney/mapail"
  defp maintainers(), do: ["Stephen Moloney"]

  def application() do
    [applications: [:logger, :maptu]]
  end

  defp deps() do
    [
      {:maptu, github: "stephenmoloney/maptu", commit: "5c210e3d09b049c26bcc86703905099082a00f41"},

      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description() do
    ~s"""
    Convert maps with string keys to an elixir struct with Mapail.
    """
  end

  defp package() do
    %{
      licenses: ["MIT"],
      maintainers: maintainers(),
      links: %{ "GitHub" => source_url()},
      files: ~w(lib mix.exs README* LICENSE* CHANGELOG*)
     }
  end

  defp docs() do
    [
    main: "api-reference"
    ]
  end

end
