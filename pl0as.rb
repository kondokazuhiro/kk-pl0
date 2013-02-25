#!/usr/bin/env ruby
require 'pl0common'

class AssemblerDriver
  include PL0Common
  
  def initialize(cmd_name)
    @cmd_name = cmd_name
    @conf = {
      :src_file => nil,
      :out_file => nil,
    }
  end
  
  def config_by_argv(argv)
    if argv.size != 1
      raise PL0Error.new(usage_text)
    end
    @conf[:src_file] = argv[0]
    @conf[:out_file] = @conf[:src_file].sub(/\.pl0as$/, '') + '.pl0vm'
  end
  
  def usage_text
    "Usage: #{@cmd_name} file"
  end

  def run
    inst_in = TextInstructionIO.new(File.open(@conf[:src_file]))
    instructions = inst_in.read_all
    inst_in.close
  
    inst_out = BinaryInstructionIO.new(File.open(@conf[:out_file], 'wb'))
    inst_out.write_all(instructions)
    inst_out.close
  end
end

def run_pl0as
  driver = AssemblerDriver.new($0)
  begin
    driver.config_by_argv(ARGV)
    driver.run
  rescue PL0Common::PL0Error => e
    STDERR.print(e.to_s, "\n")
  end
end

if __FILE__ == $0
  run_pl0as
end
