defmodule Cure.Mixfile do
  use Mix.Project

  def project do
    [app: :cure,
     version: "0.2.0",
     elixir: "~> 0.15.1",
     description: description,
     deps: deps,
     package: package]
  end

  def application do
    [applications: [:logger],
    registered: [Cure.Supervisor],
    mod: {Cure, []}]
  end
  
  defp description do 
    """
    Interfaces Elixir with C-code in a user-friendly way! Based on Erlang-ports.
    Provides a few Mix-tasks to kickstart the development process.
    """
  end

  defp deps do
    []
  end

  defp package do
    [files: ~w(lib priv c_src mix.exs README* readme* LICENSE* license*),
    contributors: ["Luc Tielen"],
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/Primordus/Cure.git"}]
  end
end
