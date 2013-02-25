#!/usr/bin/env ruby
require 'optparse'
require 'pl0common'

class PL0VM
  include PL0Common
  include PL0Common::InstructionCode
  include PL0Common::OperationType
  
  STACK_SIZE = 2048
  
  attr_accessor :output, :debug
  
  def initialize
    @debug = false
    @output = $stdout
    @stack = Array.new(STACK_SIZE)
    @display = Array.new
    @top = 0
    @pc = 0
  end
  
  def run(instructions)
    @top = 0
    @pc = 0
    @display[0] = 0
    @stack[@top] = @display[0]
    @stack[@top + 1] = @pc
    
    while true
      inst = instructions[@pc]
      @pc += 1
      
      execute_instruction(inst)
      
      print_state(inst) if @debug
      
      break if @pc == 0
    end
  end
  
  private
  
  def print_state(inst)
    print "#{inst.to_s}\n"
    print "  pc=#{@pc}\n"
  end
  
  def execute_instruction(inst)
    case inst.code
    when LOD
      do_LOD(inst)
    when STO
      do_STO(inst)
    when LIT
      do_LIT(inst)
    when CAL
      do_CAL(inst)
    when RET
      do_RET(inst)
    when ICT
      do_ICT(inst)
    when JMP
      do_JMP(inst)
    when JPC
      do_JPC(inst)
    when OPR
      do_OPR(inst)
    else
      raise PL0Error.new("Unknown Instruction Code: #{inst.code}")
    end
  end
  
  def do_LOD(inst)
    push(@stack[@display[inst.addr.level] + inst.addr.offset])
  end
  
  def do_STO(inst)
    @stack[@display[inst.addr.level] + inst.addr.offset] = pop()
  end
  
  def do_LIT(inst)
    push(inst.value)
  end

  # Stack Frame:
  # ex. call func(p1, p2); var v1,v2;
  #
  # @stack            offset(after do_CAL)
  #   p1               -2
  #   p2               -1
  #   prev_@display[n]  0 @top (== next_@display[n]) 
  #   @pc               1 return address
  #   v1                2 
  #   v2                3
  #                     4 (@top after do_ICT)
  
  def do_CAL(inst)
    callee_level = inst.addr.level + 1

    @stack[@top] = @display[callee_level]
    @stack[@top + 1] = @pc
    @display[callee_level] = @top
    @pc = inst.addr.offset
  end

  def do_ICT(inst)
    @top += inst.value
    examine_top
  end

  def do_RET(inst)
    callee_level = inst.addr.level
    num_func_params = inst.addr.offset

    ret_value = pop()
    @top = @display[callee_level]
    @display[callee_level] = @stack[@top]
    @pc = @stack[@top + 1]
    @top -= num_func_params
    push(ret_value)
  end

  def do_JMP(inst)
    @pc = inst.value
  end
  
  def do_JPC(inst)
    @pc = inst.value if pop() == 0
  end
  
  def do_OPR(inst)
    case inst.op_type
    when NEG
      operate_unary {|a| -a}
    when ODD
      operate_unary {|a| a & 1}
    when ADD
      operate_binary {|a, b| a + b}
    when SUB
      operate_binary {|a, b| a - b}
    when MUL
      operate_binary {|a, b| a * b}
    when DIV
      operate_binary {|a, b| (a / b).to_i}
    when EQ
      operate_binary {|a, b| a == b ? 1 : 0}
    when LS
      operate_binary {|a, b| a < b ? 1 : 0}
    when GR
      operate_binary {|a, b| a > b ? 1 : 0}
    when NEQ
      operate_binary {|a, b| a != b ? 1 : 0}
    when LSEQ
      operate_binary {|a, b| a <= b ? 1 : 0}
    when GREQ
      operate_binary {|a, b| a >= b ? 1 : 0}
    when WRT
      @output.print(pop(), ' ')
    when WRL
      @output.print("\n")
    else
      raise PL0Error.new("Unknown operation type: #{inst.op_type}")
    end
  end
  
  def operate_unary
    @stack[@top - 1] = yield @stack[@top - 1]
  end
  
  def operate_binary
    pop()
    @stack[@top - 1] = yield @stack[@top - 1], @stack[@top]
  end
  
  def push(value)
    @stack[@top] = value
    @top += 1
    examine_top
  end

  def pop
    @top -= 1
    @stack[@top] 
  end
  
  def examine_top
    if @top + 1 >= STACK_SIZE
      raise PL0Error.new("stack overflow")
    end
    @top
  end
end

class PL0VMDriver
  include PL0Common

  def initialize(cmd_name)
    @cmd_name = cmd_name
    @vm = PL0VM.new
    @conf = {
      :src_file => nil,
      :as_in => false,
    }
  end
  
  def config_by_argv(argv)
    opt = OptionParser.new
    opt.on('--debug') {|v| @vm.debug = v}
    opt.on('--as') {|v| @conf[:as_in] = v}
    opt.parse!(argv)
    
    if argv.size != 1
      raise PL0Error.new(usage_text)
    end
    @conf[:src_file] = argv[0]
  end
  
  def usage_text
    "Usage: #{@cmd_name} file"
  end

  def run
    inst_in = @conf[:as_in] ?
      TextInstructionIO.new(File.open(@conf[:src_file])) :
      BinaryInstructionIO.new(File.open(@conf[:src_file], 'rb'))
    @vm.run(inst_in.read_all)
    inst_in.close
  end
end

def run_pl0vm
  driver = PL0VMDriver.new($0)
  begin
    driver.config_by_argv(ARGV)
    driver.run
  rescue OptionParser::ParseError => e
    STDERR.print(e.to_s, "\n")
  rescue PL0Common::PL0Error => e
    STDERR.print(e.to_s, "\n")
  end
end

if __FILE__ == $0
  run_pl0vm
end
