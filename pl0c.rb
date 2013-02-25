#!/usr/bin/env ruby
require 'optparse'
require 'pl0common'

=begin
PL/0 Compiler
BNF
<program> ::= <block> '.'
<block> ::= [<var_decl> | <const_decl> | <func_decl>]* <statement>
<const_decl> ::= 'const' <ident> '=' <number> [',' <ident> '=' <number>]* ';'
<var_decl> ::= 'var' <var_decl_elem> [',' <var_decl_elem>]* ';'
<var_decl_elem> ::= <ident> | <ident> '[' <number> ']' | <ident> '[' <ident> ']'
<func_decl> ::= 'function' <ident> '(' [<ident> [',' <ident>]*] ')' <block> ';'
<statement> ::= #empty
              | <ident> ['[' <expr> ']'] ':=' <expr>
              | 'begin' <statement> [';' <statement>]* 'end'
              | 'if' <condition> 'then' <statement> ['else' <statement>]
              | 'while' <condition> 'do' <statement>
              | 'repeat' <statement> 'until' <condition>
              | 'return' <expr>
              | <writeln>
              | <write> <expr>
<condition> ::= 'odd' <expr>
              | <expr> <cond_op> <expr>
<cond_op> ::= '=' | '<>' | '<' | '>' | '<=' | '>='
<expr> ::= ['+' | '-'] <term> [['+' | '-'] <term>]*
<term> ::= <factor> [['*' | '/'] <factor>]*
<factor> ::= <ident>
           | <number>
           | <ident> '[' <expr> ']'
           | <ident> '(' [<expr> [',' <expr>]*] ')' 
           | '(' <expr> ')'
=end

module TokenKind
  
  ALL_KINDS = Array.new
  RESERVED_WORD_TO_KIND = Hash.new
  
  class KindEntry
    attr_reader :terminal, :represent
    
    def initialize(terminal, represent = nil)
      @terminal = terminal
      @represent = represent ? represent : terminal

      ALL_KINDS.push(self)
      RESERVED_WORD_TO_KIND[terminal] = self if terminal
    end
    
    def to_s
      @represent
    end
  end

  K_IDENT = KindEntry.new(nil, 'Identifier')
  K_NUMBER = KindEntry.new(nil, 'Number')
  K_EOF = KindEntry.new(nil, 'EOF')
  K_BEGIN = KindEntry.new('begin')
  K_END = KindEntry.new('end')
  K_CONST = KindEntry.new('const')
  K_VAR = KindEntry.new('var')
  K_FUNC = KindEntry.new('function')
  K_IF = KindEntry.new('if')
  K_ELSE = KindEntry.new('else')
  K_THEN = KindEntry.new('then')
  K_WHILE = KindEntry.new('while')
  K_DO = KindEntry.new('do')
  K_REPEAT = KindEntry.new('repeat')
  K_UNTIL = KindEntry.new('until')
  K_WRITE = KindEntry.new('write')
  K_WRITELN = KindEntry.new('writeln')
  K_RETURN = KindEntry.new('return')
  K_ODD = KindEntry.new('odd')
  K_PERIOD = KindEntry.new('.')
  K_COMMA = KindEntry.new(',')
  K_SEMICOLON = KindEntry.new(';')
  K_EQUAL = KindEntry.new('=')
  K_NOT_EQUAL = KindEntry.new('<>')
  K_GT = KindEntry.new('>')
  K_GT_EQ = KindEntry.new('>=')
  K_LT = KindEntry.new('<')
  K_LT_EQ = KindEntry.new('<=')
  K_ASSIGN = KindEntry.new(':=')
  K_PLUS = KindEntry.new('+')
  K_MINUS = KindEntry.new('-')
  K_MUL = KindEntry.new('*')
  K_DIV = KindEntry.new('/')
  K_L_PAREN = KindEntry.new('(')
  K_R_PAREN = KindEntry.new(')')
  K_L_BRACKET = KindEntry.new('[')
  K_R_BRACKET = KindEntry.new(']')
end

class Token
  attr_reader :kind, :value
  
  def initialize(kind, value = kind.terminal)
    @kind = kind
    @value = value
  end
end

class CompileError < PL0Common::PL0Error
  def initialize(msg, info = nil)
    super(info ? msg_with_info(msg, info) : msg)
  end
  
  private
  
  def msg_with_info(msg, info)
    src = info[:source_name] ? info[:source_name] : ''
    line = info[:line_number] ? "(#{info[:line_number]}): " : ''
    src + line + msg
  end
end

class Scanner
  include TokenKind
  
  def initialize(input, name)
    @input = input
    @source_name = name
    @line_number = 0
    @chars = []

    @one_meta_tokens = {}
    @two_meta_tokens = {}
    ALL_KINDS.each do |kind|
      term = kind.terminal
      next if !term || term =~ /^\w/
      if term.length == 1
        @one_meta_tokens[term] = Token.new(kind)
      elsif term.length == 2
        @two_meta_tokens[term] = Token.new(kind)
      end
    end
  end
  
  def source_info
    {:source_name => @source_name, :line_number => @line_number}
  end
  
  def next_token
    while true
      ch = next_char
      return Token.new(K_EOF) unless ch
      break if ch !~ /\s/
    end
    
    if ch =~ /[a-z_]/i
      return read_ident(ch)
    elsif ch =~ /\d/
      return read_number(ch)
    else
      return read_meta(ch)
    end
  end
  
  private
  
  def error(msg)
    CompileError.new(msg, source_info)
  end
  
  def next_char
    return @chars.shift if @chars.size > 0
    line = @input.gets
    return nil unless line
    @line_number += 1
    @chars = line.split('')
    @chars.shift
  end
  
  def pushback_char(ch)
    @chars.insert(0, ch)
  end
  
  def read_ident(ch)
    word = ch
    word += ch while (ch = next_char) =~ /\w/
    pushback_char(ch)
    kind = RESERVED_WORD_TO_KIND[word]
    kind = K_IDENT unless kind
    return Token.new(kind, word)
  end
  
  def read_number(ch)
    val = ch
    val += ch while (ch = next_char) =~ /\w/
    pushback_char(ch)
    unless val =~ /^\d+$/
      raise error("Illegal number '#{val}'")
    end
    return Token.new(K_NUMBER, val.to_i)
  end
  
  def read_meta(ch)
    ch2 = next_char
    if ch2 && (token = @two_meta_tokens[ch + ch2])
      return token
    end
    pushback_char(ch2)
    return @one_meta_tokens[ch] if @one_meta_tokens.has_key?(ch)
    raise error("Unexpected character '#{ch}'")
  end
end

class SymbolDef
  VAR_SCALAR = :var_scalar
  CONST = :const
  FUNC = :func
  VAR_ARRAY = :array
  VAR_REF = :ref

  attr_reader :kind, :name, :values
    
  def initialize(kind, name, values)
    @kind = kind
    @name = name
    @values = values
  end
  
  def is_variable
    @kind == VAR_SCALAR || @kind == VAR_ARRAY || @kind == VAR_REF
  end
  
  def is_array_or_ref
    @kind == VAR_ARRAY || @kind == VAR_REF
  end
end

class SymbolManager
  include PL0Common
  
  # FIRST_VAR_OFFSET/@offset: see PL0VM::do_CAL, do_RET, do_ICT
  # ex. call func(p1, p2); var v1,v2;
  # Stack             Offset
  #   p1               -2
  #   p2               -1
  #   display[level]    0 (top-of-stack)
  #   pc                1 return address
  #   v1                2 FIRST_VAR_OFFSET 
  #   v2                3
  #                     4 @offset (top-of-stack after ict)
  
  FIRST_VAR_OFFSET = 2
  
  attr_reader :level, :offset
  
  def initialize(src_context)
    @src_context = src_context
    @level = -1
    @offset = FIRST_VAR_OFFSET
    @offset_stack = Array.new
    @tables = Array.new
    @tables.push(Hash.new)
  end
  
  def block_begin
    @offset_stack.push(@offset)
    @offset = FIRST_VAR_OFFSET
    @tables.push(Hash.new)
    @level += 1
  end

  def block_end
    @level -= 1
    @offset = @offset_stack.pop
    @tables.pop
  end
  
  def get(name)
    @tables.reverse_each do |t|
      return t[name] if t.has_key?(name)
    end
    raise error("Undefined symbol: #{name}")
  end
  
  def enter_var_scalar(name)
    values = {:addr => Address.new(@level, @offset)}
    @tables.last[name] = SymbolDef.new(SymbolDef::VAR_SCALAR, name, values)
    @offset += 1
  end

  def enter_array(name, size)
    values = {:addr => Address.new(@level, @offset), :size => size}
    @tables.last[name] = SymbolDef.new(SymbolDef::VAR_ARRAY, name, values)
    @offset += size
  end
  
  def enter_const(name, value)
    values = {:value => value}
    @tables.last[name] = SymbolDef.new(SymbolDef::CONST, name, values)
  end
  
  def enter_func(name, inst_index)
    values = {:addr => Address.new(@level, inst_index), :params => []}
    @tables.last[name] = SymbolDef.new(SymbolDef::FUNC, name, values)
  end
  
  def fix_func_addr(func_sym, inst_index)
    func_sym.values[:addr].modify_offset(inst_index)
  end
  
  def enter_func_param(func_sym, name, kind)
    values = {:addr => Address.new(@level, 0)}
    param_sym = SymbolDef.new(kind, name, values)
    @tables.last[name] = param_sym
    func_sym.values[:params].push(param_sym)
  end
  
  def fix_func_param_offsets(func_sym)
    offset = -1
    func_sym.values[:params].reverse_each do |sym|
      sym.values[:addr].modify_offset(offset)
      offset -= 1
    end
  end
  
  private

  def error(msg)
    CompileError.new(msg, @src_context.source_info)
  end
end

class CodeGenerator
  include PL0Common
  
  attr_reader :instructions
  
  def initialize(sym_mgr)
    @sym_mgr = sym_mgr
    @factory = InstructionFactory.new
    @instructions = Array.new
  end
  
  def gen_value(op, value)
    @instructions.push(@factory.create(op, value))
    @instructions.size - 1
  end
  
  def gen_addr(op, addr)
    @instructions.push(@factory.create(op, addr))
    @instructions.size - 1
  end
  
  def gen_opr(op_type)
    @instructions.push(@factory.create(InstructionCode::OPR, op_type))
    @instructions.size - 1
  end
  
  def back_patch(index)
    @instructions[index].modify_value(@instructions.size)
  end
  
  def gen_ret(func_sym)
    if @instructions.last.code != InstructionCode::RET
      offset = func_sym ? func_sym.values[:params].size : 0
      addr = Address.new(@sym_mgr.level, offset)
      @instructions.push(@factory.create(InstructionCode::RET, addr))
    end
    @instructions.size - 1
  end
  
  def next_inst_index
    @instructions.size
  end
end

class Compiler
  include PL0Common
  include TokenKind
  
  def initialize(scanner)
    @scanner = scanner
    @sym_mgr = SymbolManager.new(@scanner)
    @generator = CodeGenerator.new(@sym_mgr)
    @token = nil
    @back_token = nil
  end
  
  def compile
    next_token
    @sym_mgr.block_begin
    parse_block(nil)
    if @token.kind != K_PERIOD
      raise error("'.' required.")
    end
  end
  
  def instructions
    @generator.instructions
  end
  
  def dump_code
    io = InstructionIO.new(STDOUT)
    io.write_all(instructions)
  end

  private
  
  def error(msg)
    CompileError.new(msg, @scanner.source_info)
  end
  
  def next_token
    if @back_token
      @token = @back_token
      @back_token = nil
    else
      @token = @scanner.next_token
    end
    @token
  end
  
  def pushback_token(token)
    @back_token = token
  end

  def expect_token(token, expected_kind)
    if token.kind != expected_kind
      raise error("Expected '#{expected_kind}' but was '#{token.value}'")
    end
  end

  def expect_token_in(token, expected_kinds)
    if !expected_kinds.include?(token.kind)
      cand = expected_kinds[0..-2].join("', '") + "' or '#{expected_kinds.last}"
      raise error("Expected '#{cand}' but was '#{token.value}'")
    end
  end
  
  def expect_and_next_token(token, expected_kind)
    expect_token(token, expected_kind)
    next_token
  end
  
  def parse_block(func_sym)
    backp_index = @generator.gen_value(InstructionCode::JMP, 0)
    
    while true
      if @token.kind == K_VAR
        next_token
        parse_var_decl
      elsif @token.kind == K_CONST
        next_token
        parse_const_decl
      elsif @token.kind == K_FUNC
        next_token
        parse_func_decl
      else
        break
      end
    end
    
    @generator.back_patch(backp_index)
    @sym_mgr.fix_func_addr(func_sym, @generator.next_inst_index) if func_sym
    @generator.gen_value(InstructionCode::ICT, @sym_mgr.offset)
    parse_statement(func_sym)
    @generator.gen_ret(func_sym)
    @sym_mgr.block_end
  end
  
  def parse_const_decl
    while true
      expect_token(@token, K_IDENT)
      name = @token.value
      expect_and_next_token(next_token, K_EQUAL)
      expect_token(@token, K_NUMBER)
      @sym_mgr.enter_const(name, @token.value)
      next_token
      break if @token.kind != K_COMMA
      next_token
    end
    expect_and_next_token(@token, K_SEMICOLON)
  end

  def parse_var_decl
    while true
      expect_token(@token, K_IDENT)
      var_name = @token.value
      next_token
      if @token.kind == K_L_BRACKET
        # array variable
        next_token
        expect_token_in(@token, [K_NUMBER, K_IDENT])
        if (@token.kind == K_NUMBER)
          size = @token.value
        else
          sym = @sym_mgr.get(@token.value)
          if sym.kind != SymbolDef::CONST
            raise error("size '#{sym.name}' of array '#{var_name}' is not constant")
          end
          size = sym.values[:value];
        end
        if size <= 0
          raise error("size #{size} of array '#{var_name}' is invalid.")
        end
        expect_and_next_token(next_token, K_R_BRACKET)
        @sym_mgr.enter_array(var_name, size)
      else
        @sym_mgr.enter_var_scalar(var_name)
      end
      break if @token.kind != K_COMMA
      next_token
    end
    expect_and_next_token(@token, K_SEMICOLON)
  end
  
  def parse_func_decl
    expect_token(@token, K_IDENT)
    func_sym = @sym_mgr.enter_func(@token.value, @generator.next_inst_index)
    expect_and_next_token(next_token, K_L_PAREN)
    @sym_mgr.block_begin
    if @token.kind == K_IDENT
      while true
        param_name = @token.value
        next_token
        if @token.kind == K_L_BRACKET
          kind = SymbolDef::VAR_REF
          expect_and_next_token(next_token, K_R_BRACKET)
        else
          kind = SymbolDef::VAR_SCALAR
        end
        @sym_mgr.enter_func_param(func_sym, param_name, kind)
        break if @token.kind != K_COMMA
        expect_token(next_token, K_IDENT)
      end
    end
    expect_and_next_token(@token, K_R_PAREN)
    @sym_mgr.fix_func_param_offsets(func_sym)
    parse_block(func_sym)
    expect_and_next_token(@token, K_SEMICOLON)
  end
  
  def parse_statement(func_sym)
    case @token.kind
    when K_END, K_PERIOD
      # pass through
    when K_IDENT
      sym = @sym_mgr.get(@token.value)
      unless sym.is_variable
        raise error("Symbol #{sym.name} is not assignable.")
      end
      if sym.kind == SymbolDef::VAR_REF
        @generator.gen_addr(InstructionCode::LOD, sym.values[:addr])
      else
        @generator.gen_addr(InstructionCode::LDA, sym.values[:addr])
      end
      next_token
      if @token.kind == K_L_BRACKET
        if !sym.is_array_or_ref
          raise error("Symbol #{sym.name} is not an array.")
        end
        next_token
        parse_expr
        expect_and_next_token(@token, K_R_BRACKET)
        @generator.gen_opr(OperationType::ADD)
      else
        if sym.is_array_or_ref
          raise error("Symbol #{sym.name} is an array.")
        end
      end
      expect_and_next_token(@token, K_ASSIGN)
      parse_expr
      # @generator.gen_addr(InstructionCode::STO, sym.values[:addr])
      @generator.gen_opr(OperationType::SID)
    when K_BEGIN
      next_token
      parse_statement(func_sym)
      while @token.kind == K_SEMICOLON
        next_token
        parse_statement(func_sym)
      end
      expect_token_in(@token, [K_SEMICOLON, K_END])
      next_token
    when K_IF
      next_token
      parse_condition
      expect_and_next_token(@token, K_THEN)
      jpc_index = @generator.gen_value(InstructionCode::JPC, 0)
      parse_statement(func_sym)
      if @token.kind != K_ELSE
        @generator.back_patch(jpc_index)
      else
        jmp_index = @generator.gen_value(InstructionCode::JMP, 0)
        @generator.back_patch(jpc_index)
        next_token
        parse_statement(func_sym)
        @generator.back_patch(jmp_index)
      end
    when K_WHILE
      next_token
      cond_index = @generator.next_inst_index
      parse_condition
      expect_and_next_token(@token, K_DO)
      jpc_index = @generator.gen_value(InstructionCode::JPC, 0)
      parse_statement(func_sym)
      @generator.gen_value(InstructionCode::JMP, cond_index)
      @generator.back_patch(jpc_index)
    when K_REPEAT
      next_token
      stmt_index = @generator.next_inst_index
      parse_statement(func_sym)
      expect_and_next_token(@token, K_UNTIL)
      parse_condition
      @generator.gen_value(InstructionCode::JPC, stmt_index)
    when K_RETURN
      next_token
      parse_expr
      @generator.gen_ret(func_sym)
    when K_WRITE
      next_token
      parse_expr
      @generator.gen_opr(OperationType::WRT)
    when K_WRITELN
      @generator.gen_opr(OperationType::WRL)
      next_token
    else
      raise error("Unexpected token: #{@token.value}")
    end
  end
  
  def parse_condition
    if @token.kind == K_ODD
      next_token
      parse_expr
      @generator.gen_opr(OperationType::ODD)
    else
      parse_expr
      expect_token_in(@token,
        [K_EQUAL, K_NOT_EQUAL, K_GT, K_GT_EQ, K_LT, K_LT_EQ])
      k_opr = @token.kind
      next_token
      parse_expr
      case k_opr
      when K_EQUAL
        @generator.gen_opr(OperationType::EQ)
      when K_NOT_EQUAL
        @generator.gen_opr(OperationType::NEQ)
      when K_GT
        @generator.gen_opr(OperationType::GR)
      when K_GT_EQ
        @generator.gen_opr(OperationType::GREQ)
      when K_LT
        @generator.gen_opr(OperationType::LS)
      when K_LT_EQ
        @generator.gen_opr(OperationType::LSEQ)
      end
    end
  end
  
  def parse_expr
    kind = @token.kind
    if kind == K_PLUS || kind == K_MINUS
      next_token
      parse_term
      @generator.gen_opr(OperationType::NEG) if kind == K_MINUS
    else
      parse_term
    end

    kind = @token.kind
    while kind == K_PLUS || kind == K_MINUS
      next_token
      parse_term
      @generator.gen_opr(kind == K_PLUS ? OperationType::ADD : OperationType::SUB)
      kind = @token.kind
    end
  end

  def parse_term
    parse_factor
    kind = @token.kind
    while kind == K_MUL || kind == K_DIV
      next_token
      parse_factor
      @generator.gen_opr(kind == K_MUL ? OperationType::MUL : OperationType::DIV)
      kind = @token.kind
    end
  end

  def parse_factor
    case @token.kind
    when K_IDENT
      parse_factor_ident(false)
    when K_NUMBER
      @generator.gen_value(InstructionCode::LIT, @token.value)
      next_token
    when K_L_PAREN
      next_token
      parse_expr
      expect_and_next_token(@token, K_R_PAREN)
    else
      raise error("Unexpected token '#{@token.value}'")
    end
  end
  
  def parse_factor_ident(allow_ref)
    sym = @sym_mgr.get(@token.value)
    case sym.kind
    when SymbolDef::VAR_SCALAR
      @generator.gen_addr(InstructionCode::LOD, sym.values[:addr])
      next_token
    when SymbolDef::CONST
      @generator.gen_value(InstructionCode::LIT, sym.values[:value])
      next_token
    when SymbolDef::FUNC
      next_token
      parse_func_call(sym)
    when SymbolDef::VAR_ARRAY, SymbolDef::VAR_REF
      next_token
      if @token.kind == K_L_BRACKET
        # array element
        if sym.kind == SymbolDef::VAR_REF
          @generator.gen_addr(InstructionCode::LOD, sym.values[:addr])
        else
          @generator.gen_addr(InstructionCode::LDA, sym.values[:addr])
        end
        next_token
        parse_expr
        expect_and_next_token(@token, K_R_BRACKET)
        @generator.gen_opr(OperationType::ADD)
        @generator.gen_opr(OperationType::LID)
      else
        # array reference
        if !allow_ref
          raise error("Reference of array #{sym.name} is not allowed here.")
        end
        if sym.kind == SymbolDef::VAR_REF
          @generator.gen_addr(InstructionCode::LOD, sym.values[:addr])
        else
          @generator.gen_addr(InstructionCode::LDA, sym.values[:addr])
        end
      end
    end
  end
  
  def parse_func_call(func_sym)
    expect_and_next_token(@token, K_L_PAREN)
    num_params = 0
    if @token.kind != K_R_PAREN
      while true
        token1 = @token
        token2 = next_token
        pushback_token(token2)
        @token = token1
        if token1.kind == K_IDENT &&
            (token2.kind == K_COMMA || token2.kind == K_R_PAREN)
          parse_factor_ident(true)
        else
          parse_expr
        end
        num_params += 1
        break if @token.kind != K_COMMA
        next_token
      end
    end
    expect_and_next_token(@token, K_R_PAREN)
    if num_params != func_sym.values[:params].size
      raise error("#{func_sym.name}: number of parameters mismatch.")
    end
    @generator.gen_addr(InstructionCode::CAL, func_sym.values[:addr])
  end
end

class CompilerDriver
  include PL0Common
  
  attr_reader :conf
  
  def initialize(cmd_name)
    @cmd_name = cmd_name
    @conf = {
      :src_file => nil,
      :out_file => nil,
      :as_out => false,
      :debug => false,
    }
  end
  
  def config_by_argv(argv)
    opt = OptionParser.new
    opt.on('--as') {|v| @conf[:as_out] = v}
    opt.on('--debug') {|v| @conf[:debug] = v}
    opt.parse!(argv)
    
    if argv.size != 1
      raise PL0Error.new(usage_text)
    end
    @conf[:src_file] = argv[0]
    @conf[:out_file] = @conf[:src_file].sub(/\.pl0$/, '')
    @conf[:out_file].concat(@conf[:as_out] ? '.pl0as' : '.pl0vm')
  end
  
  def usage_text
    "Usage: #{@cmd_name} [--as] source"
  end

  def run
    input = File.open(@conf[:src_file])
    compiler = Compiler.new(Scanner.new(input, @conf[:src_file]))
    compiler.compile
    input.close
  
    out = File.open(@conf[:out_file], @conf[:as_out] ? 'w' : 'wb')
    inst_out = @conf[:as_out] ?
      TextInstructionIO.new(out) : BinaryInstructionIO.new(out)
    inst_out.write_all(compiler.instructions)
    out.close
  end
end

def run_pl0c
  driver = CompilerDriver.new($0)
  begin
    driver.config_by_argv(ARGV)
    driver.run
  rescue OptionParser::ParseError => e
    STDERR.print(e.to_s, "\n")
  rescue PL0Common::PL0Error => e
    STDERR.print(e.to_s, "\n")
    STDERR.print(e.backtrace.join("\n"), "\n") if driver.conf[:debug]
  end
end

if __FILE__ == $0
  run_pl0c
end
