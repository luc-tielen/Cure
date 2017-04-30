defmodule Mix.Tasks.Cure.Bootstrap do
  use Mix.Task

  @shortdoc "Generates files to bootstrap the C-development."

  @cure_source_dir Path.expand("./c_src/")
  @own_source_dir Path.expand("../../c_src")
  
  @doc """
  Creates the c_src directory along with a Makefile and a few basic C-files to
  streamline the C-development.
  """
  def run(_args) do
    File.mkdir @own_source_dir
    IO.puts "Created ./c_src/"

    generate_files()
    IO.puts "Done bootstrapping."
  end

  defp generate_files do 
    generate_main()
    generate_makefile()
  end

  defp generate_main do
    unless File.exists?(@own_source_dir <> "/main.h") do
      contents_main_h = """
      #ifndef MAIN_H
      #define MAIN_H
      #include <elixir_comm.h>
      
      // TODO put your own functions/includes here.

      #endif
      """
      File.write!(@own_source_dir <> "/main.h", contents_main_h)
      IO.puts "Created #{@own_source_dir}/main.h"
    end

    unless File.exists?(@own_source_dir <> "/main.c") do
      contents_main_c = """
      #include "main.h"

      int main(void)
      {
          int bytes_read;
          byte buffer[MAX_BUFFER_SIZE];
          
          while((bytes_read = read_msg(buffer)) > 0)
          {
              // TODO put C-code here, right now it only echos data back
              // to Elixir.

              send_msg(buffer, bytes_read);
          }

          return 0;
      }
      """
      File.write!(@own_source_dir <> "/main.c", contents_main_c)
      IO.puts "Created #{@own_source_dir}/main.c"
    end
  end

  defp generate_makefile do
    unless File.exists?(@own_source_dir <> "/Makefile") do
      contents = """
      # This Makefile is automatically generated with "mix cure.bootstrap"!
      # Please do not remove the following variables as they point to 
      # the necessary source-files.

      INC_PARAMS = #{@cure_source_dir}
      ELIXIR_COMM_C = $(INC_PARAMS)/elixir_comm.c
      C_FLAGS = -I$(INC_PARAMS) -O3
      
      # You can add other build targets on the next line:
      ALL = program

      # Targets:
      all: $(ALL)
      program:\n\tgcc -o program main.c $(ELIXIR_COMM_C) $(C_FLAGS)
      """
      File.write!(@own_source_dir <> "/Makefile", contents)

      IO.puts "Created #{@own_source_dir <> "/Makefile"}."
    end
  end
end
