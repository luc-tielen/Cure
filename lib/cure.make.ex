defmodule Mix.Tasks.Cure.Make do
  use Mix.Task

  @shortdoc "Uses Makefile (in c_src dir) to compile your C-source code."
  
  @source_dir Path.expand("./c_src")
  @opts [stderr_to_stdout: true]
  
  def run([]) do
    {output, _} = System.cmd("make", ["-C", @source_dir], @opts)
    IO.puts output
  end
  def run([target]) do
    {output, _} = System.cmd("make", [target, "-C", @source_dir], @opts)
    IO.puts output
  end
  def run([target | rest]) do
    run([target])
    run(rest)
  end
end
