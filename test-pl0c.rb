require 'test/unit'
require 'stringio'
require 'pl0c'
require 'pl0vm'

class TesPL0C < Test::Unit::TestCase
  
  def compile(prog_text)
    sio = StringIO.new
    sio.print(prog_text)
    sio.rewind
    c = Compiler.new(Scanner.new(sio, 'test'))
    c.compile
    c
  end
  
  def vm_run(c)
    vm = PL0VM.new
    vm.output = StringIO.new
    vm.run(c.instructions)
    vm.output.string
  end
  
  def dump_code(c)
    print "----------------\n"
    c.dump_code
  end

  def test_CompileError
    e = CompileError.new('test error')
    assert_equal('test error', e.message)

    info = {:source_name => 'test.pl0', :line_number => 8}
    e = CompileError.new('test error', info)
    assert_equal('test.pl0(8): test error', e.message)
  end

  def test_compile_empty
    assert_equal('', vm_run(compile(".")))
    assert_equal('', vm_run(compile("begin end.")))
    assert_equal('', vm_run(compile("begin begin end end.")))
    assert_equal('', vm_run(compile("begin begin begin end end end.")))
  end
  
  def test_compile_writeln
    assert_equal("\n", vm_run(compile("begin writeln end.")))
    assert_equal("\n\n", vm_run(compile("begin writeln; writeln\nend.")))
  end
  
  def test_compile_write
    assert_equal('128 ', vm_run(compile("begin write 128 end.")))
    assert_equal("128 \n", vm_run(compile("begin write 128; writeln end.")))
  end
  
  def test_compile_const
    c = compile("const a = 1, b = 2; begin write a; write b end.")
    assert_equal('1 2 ', vm_run(c))
  end

  def test_compile_var
    assert_equal('64 ', vm_run(compile("var a; begin a := 64; write a end.")))
  end

  def test_compile_const_var
    c = compile("const a = 32; var b; begin b := 64; write a; write b end.")
    assert_equal('32 64 ', vm_run(c))
  end

  def test_compile_undefined_symbol
    begin
      compile("var a; begin a := 1; write undef end.")
      flunk
    rescue CompileError => e
      assert_equal('test(1): Undefined symbol: undef', e.to_s)
    end
  end
  
  def test_compile_func_no_param
    c = compile("var a; function f() write 22; begin a := f() end.")
    assert_equal('22 ', vm_run(c))
  end

  def test_compile_func_01
    c = compile("var a; function f(a) write a; begin a := (f((100))) end.")
    assert_equal('100 ', vm_run(c))

    c = compile("var a; function f(a,b) begin write a; write b end; begin a := f(1,2) end.")
    assert_equal('1 2 ', vm_run(c))
  end

  def test_compile_func_ret
    c = compile("var a; function f(a,b) return a+b; begin write f(1,2) end.")
    assert_equal('3 ', vm_run(c))
  end

  def test_compile_add_sub
    assert_equal('12 ', vm_run(compile("begin write 10 + 2 end.")))
    assert_equal('10 ', vm_run(compile("begin write 12 - 2 end.")))
    assert_equal('-8 ', vm_run(compile("begin write -10 + 5 - 3 end.")))
  end

  def test_compile_mul_div
    assert_equal('20 ', vm_run(compile("begin write 10 * 2 end.")))
    assert_equal('50 ', vm_run(compile("begin write 100 / 2 end.")))
    assert_equal('60 ', vm_run(compile("begin write 100 / 5 * 3 end.")))
  end
  
  def test_compile_odd
    c = compile("const a = 1; begin if odd a then write a end.")
    assert_equal('1 ', vm_run(c))
    c = compile("const a = 1; begin if odd a + 1 then write a end.")
    assert_equal('', vm_run(c))
  end

  def test_compile_rel
    assert_equal('1 ', vm_run(compile("begin if 1 = 1 then write 1 end.")))
    assert_equal('',   vm_run(compile("begin if 1 = 2 then write 1 end.")))

    assert_equal('1 ', vm_run(compile("begin if 1 <> 2 then write 1 end.")))
    assert_equal('',   vm_run(compile("begin if 1 <> 1 then write 1 end.")))

    assert_equal('1 ', vm_run(compile("begin if 1 >= 1 then write 1 end.")))
    assert_equal('1 ', vm_run(compile("begin if 2 >= 1 then write 1 end.")))
    assert_equal('',   vm_run(compile("begin if 1 >= 2 then write 1 end.")))

    assert_equal('1 ', vm_run(compile("begin if 2 > 1 then write 1 end.")))
    assert_equal('',   vm_run(compile("begin if 1 > 1 then write 1 end.")))
    
    assert_equal('1 ', vm_run(compile("begin if 1 < 2 then write 1 end.")))
    assert_equal('',   vm_run(compile("begin if 1 < 1 then write 1 end.")))
      
    assert_equal('1 ', vm_run(compile("begin if 1 <= 1 then write 1 end.")))
    assert_equal('1 ', vm_run(compile("begin if 1 <= 2 then write 1 end.")))
    assert_equal('',   vm_run(compile("begin if 2 <= 1 then write 1 end.")))
  end
  
  def test_compile_while
    c = compile("var i; begin i:=0; while i<=3 do begin write i; i:=i+1 end end.")
    assert_equal('0 1 2 3 ', vm_run(c))
  end
  
  def test_compile_repeat_until
    c = compile("var i; begin i:=0; repeat begin write i; i:=i+1 end until i > 3 end.")
    assert_equal('0 1 2 3 ', vm_run(c))
  end
  
  def test_compile_if_else_01
    c = compile("begin if odd 1 then write 1 else write 2 end.")
    assert_equal('1 ', vm_run(c))
    c = compile("begin if odd 2 then write 1 else write 2 end.")
    assert_equal('2 ', vm_run(c))
  end
  
  def test_compile_if_else_02
    src = <<-EOS
    const a = 0;
    begin
      if a = 0 then
        if a = 1 then
          write 1
        else
          write 0
      else
        write 3
    end.
    EOS
    assert_equal('0 ', vm_run(compile(src)))

    src = <<-EOS
    const a = 1;
    begin
      if a = 0 then
        if a = 1 then
          write 1
        else
          write 0
      else
        write 3
    end.
    EOS
    assert_equal('3 ', vm_run(compile(src)))
  end
  
  def test_compile_scope_01
    c = compile(<<-EOS
      var a, g, dummy;
      function f1()
        var a;
        function f2()
          var a;
          begin
            a := 2;
            g := 9;
            write a;
          end;
        begin
          a := 1;
          g := 1;
          dummy := f2();
          write a;
        end;
      begin
        a := 0;
        g := 0;
        dummy := f1();
        write a;
        write g;
      end.
      EOS
      )
    assert_equal('2 1 0 9 ', vm_run(c))
  end
  
  def test_compile_scope_02
    src = <<-EOS
      var dummy;
      function f1()
        var b;
        begin
          b := 1;
        end;
      begin
        dummy := f1();
        write b;
      end.
    EOS

    begin
      compile(src)
      flunk
    rescue  CompileError => e
      assert_equal('test(9): Undefined symbol: b', e.to_s)
    end
  end
  
  def test_example_ex1
    assert_equal("7 85 \n595 \n", vm_run(compile(SRC_ex1)))
  end

  def test_example_fact
    res =
    "1 1 \n" +
    "2 2 \n" +
    "3 6 \n" +
    "4 24 \n" +
    "5 120 \n" +
    "6 720 \n" +
    "7 5040 \n" +
    "8 40320 \n" +
    "9 362880 \n"  
    assert_equal(res, vm_run(compile(SRC_fact)))
  end

  SRC_ex1 = <<-EOS
  function multiply(x, y)
  var a,b,c;
  begin
    a:=x; b:=y; c:=0;
    while b>0 do
    begin
      if odd b then c:=c+a;
      a:=2*a; b:=b/2;
    end;
    return c;
  end;
      
  const m=7,n=85;
  var x,y;
      
  begin
    x:=m; y:=n;
    write x; write y; writeln; write multiply(x,y); writeln
  end.
  EOS

  SRC_fact = <<-EOS
  function fact(n)
  begin
    if n = 1 then return 1;
    return n*fact(n-1);
  end;
      
  var x;
  begin
    x := 1;

    while x<10 do
    begin
      write x;
      write fact(x);
      writeln;
      x := x+1;
    end;
  end.
  EOS
  
end
