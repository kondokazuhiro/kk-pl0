module PL0Common
  
  module InstructionCode
    LIT = 1
    OPR = 2
    LOD = 3
    STO = 4
    CAL = 5
    RET = 6
    ICT = 7
    JMP = 8
    JPC = 9
    
    INSTRUCTION_CODE_TO_S = {
      LIT => 'lit',
      OPR => 'opr',
      LOD => 'lod',
      STO => 'sto',
      CAL => 'cal',
      RET => 'ret',
      ICT => 'ict',
      JMP => 'jmp',
      JPC => 'jpc',
    }
    S_TO_INSTRUCTION_CODE = INSTRUCTION_CODE_TO_S.invert

    def instruction_code_to_s(num)
      INSTRUCTION_CODE_TO_S[num]
    end
    module_function :instruction_code_to_s

    def s_to_instruction_code(text)
      S_TO_INSTRUCTION_CODE[text.downcase]
    end
    module_function :s_to_instruction_code
  end
  
  module OperationType
    NEG = 1
    ADD = 2
    SUB = 3
    MUL = 4
    DIV = 5
    ODD = 6
    EQ  = 7
    LS  = 8
    GR  = 9
    NEQ = 10
    LSEQ = 11
    GREQ = 12
    WRT  = 13
    WRL  = 14
    
    OPERATION_TYPE_TO_S = {
      NEG => 'neg',
      ADD => 'add',
      SUB => 'sub',
      MUL => 'mul',
      DIV => 'div',
      ODD => 'odd',
      EQ  => 'eq',
      LS  => 'ls',
      GR  => 'gr',
      NEQ => 'neq',
      LSEQ => 'lseq',
      GREQ => 'greq',
      WRT  => 'wrt',
      WRL  => 'wrl',
    }
    S_TO_OPERATION_TYPE = OPERATION_TYPE_TO_S.invert

    def operation_type_to_s(num)
      OPERATION_TYPE_TO_S[num]
    end
    module_function :operation_type_to_s

    def s_to_operation_type(text)
      S_TO_OPERATION_TYPE[text.downcase]
    end
    module_function :s_to_operation_type
  end
  
  class PL0Error < StandardError
    def initialize(msg)
      super(msg)
    end
  end
  
  class Address
    attr_reader :level, :offset
    
    def initialize(level, offset)
      @level = level
      @offset = offset
    end
    
    def modify_offset(offset)
      @offset = offset
    end
  end

  class Instruction
    include InstructionCode
    
    attr_reader :code
    
    def initialize(code)
      @code = code
    end
    
    def to_s
      instruction_code_to_s(@code)
    end
  end
  
  class AddrInstruction < Instruction
    attr_reader :addr
    
    def initialize(code, addr)
      super(code)
      @addr = addr
    end
    
    def to_s
      super.to_s + ",#{@addr.level},#{@addr.offset}"
    end
  end

  class ValueInstruction < Instruction
    attr_reader :value
    
    def initialize(code, value)
      super(code)
      @value = value
    end
    
    def modify_value(value)
      @value = value
    end

    def to_s
      super.to_s + ",#{@value}"
    end
  end

  class OperationInstruction < Instruction
    include OperationType
    
    attr_reader :op_type
    
    def initialize(op_type)
      super(OPR)
      @op_type = op_type
    end

    def to_s
      super.to_s + ",#{operation_type_to_s(@op_type)}"
    end
  end
 
  class InstructionFactory
    include InstructionCode

    def create(code, arg)
      case code
      when LIT, ICT, JMP, JPC
        return ValueInstruction.new(code, arg)
      when LOD, STO, CAL, RET
        return AddrInstruction.new(code, arg)
      when OPR
        return OperationInstruction.new(arg)
      else
        raise PL0Error.new("Unknown instruction code: #{code}")
      end
    end
  end
  
  class InstructionIO
    include InstructionCode

    def initialize(port)
      @port = port
      @factory = InstructionFactory.new
    end
    
    def close
      @port.close
    end

    def read_all
      instructions = []
      each {|inst| instructions.push(inst)}
      instructions
    end
    
    def each
      while inst = fetch
        yield inst
      end  
    end
    
    def fetch
      raise 'Internal Error'
    end
    
    def write_all(instructions)
      instructions.each_index {|nth| write_nth(nth, instructions[nth])}
    end
    
    def write_nth(nth, instruction)
      @port.print("#{nth}\t#{instruction.to_s}\n")
    end
  end

  class BinaryInstructionIO < InstructionIO
    def fetch
      code = read_byte
      return nil unless code
      
      case code
      when LIT, ICT, JMP, JPC
        @factory.create(code, (code == LIT) ? read_int : read_short)
      when LOD, STO, CAL, RET
        @factory.create(code, Address.new(read_short, read_short))
      when OPR
        @factory.create(code, read_byte)
      else
        raise PL0Error.new("Unknown instruction code: #{code}")
      end
    end

    def write_nth(nth, inst)
      write_byte(inst.code)
      case inst.code
      when LIT, ICT, JMP, JPC
        if inst.code == LIT
          write_int(inst.value)
        else
          write_short(inst.value)
        end
      when LOD, STO, CAL, RET
        write_short(inst.addr.level)
        write_short(inst.addr.offset)
      when OPR
        write_byte(inst.op_type)
      else
        raise PL0Error.new("Unknown instruction code: #{instruction.code}")
      end
    end

    def read_byte
      ch = @port.read(1)
      ch ? ch.unpack('c')[0] : nil
    end

    def read_short
      b0 = read_byte
      b1 = read_byte
      (b0 << 8) | b1
    end

    def read_int
      b0 = read_byte
      b1 = read_byte
      b2 = read_byte
      b3 = read_byte
      (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    end
    
    def write_byte(b)
      @port.write([b].pack('c'))
    end
    
    def write_short(n)
      write_byte((n >> 8) & 0xff)
      write_byte(n & 0xff)
    end

    def write_int(n)
      write_byte((n >> 24) & 0xff)
      write_byte((n >> 16) & 0xff)
      write_byte((n >> 8) & 0xff)
      write_byte(n & 0xff)
    end
  end

  class TextInstructionIO < InstructionIO
    def fetch
      line = @port.gets
      while line && line =~ /^\s*(#|$)/
        line = @port.gets
      end
      return nil unless line
      TextInstructionIO.line_to_instruction(@factory, line)
    end

    def write_nth(nth, instruction)
      @port.print(nth, ":\t", instruction.to_s, "\n")
    end

    def self.line_to_instruction(factory, line)
      toks = line.chomp.sub(/^\d+:\s+/, '').split(/\s*,\s*/)
      code = InstructionCode.s_to_instruction_code(toks[0])

      case code
      when LIT, ICT, JMP, JPC
        factory.create(code, toks[1].to_i)
      when LOD, STO, CAL, RET
        factory.create(code, Address.new(toks[1].to_i, toks[2].to_i))
      when OPR
        factory.create(code, OperationType.s_to_operation_type(toks[1]))
      else
        raise PL0Error.new("Unknown instruction code: #{code}")
      end
    end
  end
  
end
