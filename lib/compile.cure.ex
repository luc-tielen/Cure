defmodule Mix.Tasks.Compile.Cure do
  use Mix.Task

  @shortdoc "Uses Makefile (in c_src directory) to compile your C-source code."
  
  @source_dir Path.expand("../../c_src")
  
  @doc """
  Compiles the C-files located in the ./c_src directory.
  """
  def run(_args) do
    if File.exists? @source_dir do
      if Mix.shell.cmd("make all -C " <> @source_dir) != 0 do
        raise Mix.Error, 
          message: "Could not run make all -C " <> @source_dir 
              <> ". Make sure you have gcc and make installed."
      end
    else
      IO.puts "Compile.cure: Could not find a c_src directory."
    end
  end
end
