defmodule Mix.Tasks.Cure.Make do
  use Mix.Task

  @shortdoc "Uses Makefile (in c_src directory) to compile your C-source code."
  
  @source_dir Path.expand("../../c_src")
  @opts [stderr_to_stdout: true]
  
  @doc """
  Compiles the C-files located in the ./c_src directory.
  """
  def run(_args) do
    {output, _} = System.cmd("make", ["all", "-C", @source_dir], @opts)
    IO.puts output
  end
end
