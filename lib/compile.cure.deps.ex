defmodule Mix.Tasks.Compile.Cure.Deps do
  use Mix.Task
  
  @shortdoc "Compiles the C-files of all the dependencies (that use Cure)."
  
  @doc """
  Compiles the C-files from all dependencies (that also use Cure).
  """
  def run(_args) do
    # 1. Look for all dependencies of this project;
    # 2. Check if they have a cure dependency;
    # 3. If yes -> compile the program using make.

    IO.puts "Compiling Cure-based dependencies."

    get_deps |> Enum.map fn(dep) ->
      if need_to_compile?(dep) do
        compile(dep)
      end
    end
  end

  @doc false
  defp get_deps do
    if File.exists? "deps" do
      File.ls! "deps"
    else
      []
    end
  end

  @doc false
  defp need_to_compile?(dep) do
    dep_location = Path.expand("./deps") <> "/" <> dep <> "/"
    mix_exs = dep_location <> "mix.exs"
    c_src = dep_location <> "c_src/"

    if File.exists? mix_exs do
      mix_file = File.read! mix_exs
      result = Regex.run(~r/:cure/, mix_file)
      result == [":cure"] and File.exists?(c_src) and dep != "cure" 
    else 
      # Erlang programs don't have a mix.exs?
      false
    end
  end

  @doc false
  defp compile(dep) do
    dir = Path.expand("./deps") <> "/" <> dep <> "/c_src"
    if Mix.shell.cmd("make all -C " <> dir) != 0 do
      raise Mix.Error, 
            message: "Could not compile dependency, "
            <> "make sure gcc and make are installed."
    end
  end
end
