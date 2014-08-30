defmodule Mix.Tasks.Cure.Deps.Compile do
  use Mix.Task
  
  @shortdoc "Compiles the C-files of all the dependencies (that use Cure)."
  
  @doc """
  Compiles the C-files from all dependencies (that also use Cure).
  """
  def run(_args) do
    # 1. Look for all dependencies of this project;
    # 2. Check if they have a cure dependency;
    # 3. If yes -> compile the program using make.

    IO.puts "Compiling all Cure-based dependencies."

    get_deps |> Enum.map(fn(dep) ->
      spawn(fn ->
        if need_to_compile? dep do
          IO.puts "Compiling #{dep}."
          compile(dep)
        end
      end)
    end)
  end

  @doc false
  defp get_deps do
    ls_output = File.ls! "deps"
    IO.puts "ls-output #{ls_output}"
    ls_output
  end

  @doc false
  defp need_to_compile?(dep) do
    dep_location = Path.expand("./deps") <> "/" <> dep <> "/"
    mix_exs = dep_location <> "mix.exs"
    c_src = dep_location <> "c_src/"

    mix_file = File.read! mix_exs
    result = Regex.run(~r/:cure/, mix_file)
    is_list result and File.exists? c_src
  end

  @doc false
  defp compile(dep) do
    dir = Path.expand("./deps") <> "/" <> dep <> "/c_src"
    options = [stderr_to_std_out: true]
    {output, _} = System.cmd("make", ["all", "-C", dir], options)
    IO.puts output
  end
end
