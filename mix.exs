defmodule Cure.Mixfile do
  use Mix.Project

  def project do
    [app: :cure,
     version: "0.5.0",
     elixir: ">= 1.1.1",
     description: description(),
     deps: deps(),
     package: package()]
  end

  def application do
    [applications: [:logger],
     registered: [Cure.Supervisor],
     mod: {Cure, []}]
  end

  defp description do
    """
    Interfaces Elixir with C/C++ code in a user-friendly way! Based on Erlang-ports.
    Provides a few Mix-tasks to kickstart the development process.
    """
  end

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [files: ~w(lib c_src mix.exs README* LICENSE* ),
     maintainers: ["Luc Tielen", "Joel Feldberg"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/luc-tielen/Cure.git"}]
  end
end
