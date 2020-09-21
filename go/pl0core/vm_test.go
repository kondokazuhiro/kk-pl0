package pl0core

import (
	"bytes"
	"strings"
	"testing"
)

// Porting from test-pl0c.rb
var inspectionTargets = []struct {
	source string
	input  string
	want   string
}{
	{ // #0
		source: `
		      const size = 10;
			  var i, a[size], n;
			  begin
				i := 1;
				while i <= size do
				begin
				  a[i - 1] := i * 10 / 2;
				  a[i - 1] := a[i - 1] * 2;
				  i := i + 1;
				end;
				n := 0;
				while n < size do
				begin
				  write a[n + (n - n)];
				  n := n + 1;
				end;
			  end.
		`,
		input: "\x08\x00\x01\x07\x00\x0e\x0a\x00\x00\x00\x02\x01\x00\x00\x00\x01\x02" +
			"\x10\x03\x00\x00\x00\x02\x01\x00\x00\x00\x0a\x02\x0b\x09\x00\x28" +
			"\x0a\x00\x00\x00\x03\x03\x00\x00\x00\x02\x01\x00\x00\x00\x01\x02" +
			"\x03\x02\x02\x03\x00\x00\x00\x02\x01\x00\x00\x00\x0a\x02\x04\x01" +
			"\x00\x00\x00\x02\x02\x05\x02\x10\x0a\x00\x00\x00\x03\x03\x00\x00" +
			"\x00\x02\x01\x00\x00\x00\x01\x02\x03\x02\x02\x0a\x00\x00\x00\x03" +
			"\x03\x00\x00\x00\x02\x01\x00\x00\x00\x01\x02\x03\x02\x02\x02\x0f" +
			"\x01\x00\x00\x00\x02\x02\x04\x02\x10\x0a\x00\x00\x00\x02\x03\x00" +
			"\x00\x00\x02\x01\x00\x00\x00\x01\x02\x02\x02\x10\x08\x00\x05\x0a" +
			"\x00\x00\x00\x0d\x01\x00\x00\x00\x00\x02\x10\x03\x00\x00\x00\x0d" +
			"\x01\x00\x00\x00\x0a\x02\x08\x09\x00\x3e\x0a\x00\x00\x00\x03\x03" +
			"\x00\x00\x00\x0d\x03\x00\x00\x00\x0d\x03\x00\x00\x00\x0d\x02\x03" +
			"\x02\x02\x02\x02\x02\x0f\x02\x0d\x0a\x00\x00\x00\x0d\x03\x00\x00" +
			"\x00\x0d\x01\x00\x00\x00\x01\x02\x02\x02\x10\x08\x00\x2b\x06\x00" +
			"\x00\x00\x00",
		want: "10 20 30 40 50 60 70 80 90 100 "},
	{ // #1
		source: `
		      function f(ap[], len)
				var i;
				begin
				  i := 0;
				  while i < len do
				  begin
					ap[i] := i;
					i := i + 1;
				  end;
				end;
			  const size = 5;
			  var a[size], i, dummy;
			  begin
				dummy := f(a, size);
				i := 0;
				while i < size do
				begin
				  write a[i];
				  i := i + 1;
				end;
			  end.
		`,
		input: "\x08\x00\x16\x08\x00\x02\x07\x00\x03\x0a\x00\x01\x00\x02\x01\x00\x00" +
			"\x00\x00\x02\x10\x03\x00\x01\x00\x02\x03\x00\x01\xff\xff\x02\x08" +
			"\x09\x00\x15\x03\x00\x01\xff\xfe\x03\x00\x01\x00\x02\x02\x02\x03" +
			"\x00\x01\x00\x02\x02\x10\x0a\x00\x01\x00\x02\x03\x00\x01\x00\x02" +
			"\x01\x00\x00\x00\x01\x02\x02\x02\x10\x08\x00\x06\x06\x00\x01\x00" +
			"\x02\x07\x00\x09\x0a\x00\x00\x00\x08\x0a\x00\x00\x00\x02\x01\x00" +
			"\x00\x00\x05\x05\x00\x00\x00\x02\x02\x10\x0a\x00\x00\x00\x07\x01" +
			"\x00\x00\x00\x00\x02\x10\x03\x00\x00\x00\x07\x01\x00\x00\x00\x05" +
			"\x02\x08\x09\x00\x2e\x0a\x00\x00\x00\x02\x03\x00\x00\x00\x07\x02" +
			"\x02\x02\x0f\x02\x0d\x0a\x00\x00\x00\x07\x03\x00\x00\x00\x07\x01" +
			"\x00\x00\x00\x01\x02\x02\x02\x10\x08\x00\x1f\x06\x00\x00\x00\x00" +
			"",
		want: "0 1 2 3 4 "},
	{ // #2
		source: `begin write 10 + 2 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x0a\x01\x00\x00\x00\x02\x02" +
			"\x02\x02\x0d\x06\x00\x00\x00\x00",
		want: "12 "},
	{ // #3
		source: `begin write 12 - 2 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x0c\x01\x00\x00\x00\x02\x02" +
			"\x03\x02\x0d\x06\x00\x00\x00\x00",
		want: "10 "},
	{ // #4
		source: `begin write -10 + 5 - 3 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x0a\x02\x01\x01\x00\x00\x00" +
			"\x05\x02\x02\x01\x00\x00\x00\x03\x02\x03\x02\x0d\x06\x00\x00\x00" +
			"\x00",
		want: "-8 "},
	{ // #5
		source: `const a = 1, b = 2; begin write a; write b end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x02\x0d\x01\x00\x00\x00" +
			"\x02\x02\x0d\x06\x00\x00\x00\x00",
		want: "1 2 "},
	{ // #6
		source: `const a = 32; var b; begin b := 64; write a; write b end.`,
		input: "\x08\x00\x01\x07\x00\x03\x0a\x00\x00\x00\x02\x01\x00\x00\x00\x40\x02" +
			"\x10\x01\x00\x00\x00\x20\x02\x0d\x03\x00\x00\x00\x02\x02\x0d\x06" +
			"\x00\x00\x00\x00",
		want: "32 64 "},
	{ // #7
		source: `begin end.`,
		input:  "\x08\x00\x01\x07\x00\x02\x06\x00\x00\x00\x00",
		want:   ""},
	{ // #8
		source: `var a; function f(a) write a; begin a := (f((100))) end.`,
		input: "\x08\x00\x06\x08\x00\x02\x07\x00\x02\x03\x00\x01\xff\xff\x02\x0d\x06" +
			"\x00\x01\x00\x01\x07\x00\x03\x0a\x00\x00\x00\x02\x01\x00\x00\x00" +
			"\x64\x05\x00\x00\x00\x02\x02\x10\x06\x00\x00\x00\x00",
		want: "100 "},
	{ // #9
		source: `var a; function f(a,b) begin write a; write b end; begin a := f(1,2) end.`,
		input: "\x08\x00\x08\x08\x00\x02\x07\x00\x02\x03\x00\x01\xff\xfe\x02\x0d\x03" +
			"\x00\x01\xff\xff\x02\x0d\x06\x00\x01\x00\x02\x07\x00\x03\x0a\x00" +
			"\x00\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x02\x05\x00\x00" +
			"\x00\x02\x02\x10\x06\x00\x00\x00\x00",
		want: "1 2 "},
	{ // #10
		source: `var a; function f() write 22; begin a := f() end.`,
		input: "\x08\x00\x06\x08\x00\x02\x07\x00\x02\x01\x00\x00\x00\x16\x02\x0d\x06" +
			"\x00\x01\x00\x00\x07\x00\x03\x0a\x00\x00\x00\x02\x05\x00\x00\x00" +
			"\x02\x02\x10\x06\x00\x00\x00\x00",
		want: "22 "},
	{ // #11
		source: `var a; function f(a,b) return a+b; begin write f(1,2) end.`,
		input: "\x08\x00\x07\x08\x00\x02\x07\x00\x02\x03\x00\x01\xff\xfe\x03\x00\x01" +
			"\xff\xff\x02\x02\x06\x00\x01\x00\x02\x07\x00\x03\x01\x00\x00\x00" +
			"\x01\x01\x00\x00\x00\x02\x05\x00\x00\x00\x02\x02\x0d\x06\x00\x00" +
			"\x00\x00",
		want: "3 "},
	{ // #12
		source: `begin if odd 1 then write 1 else write 2 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x02\x06\x09\x00\x08\x01" +
			"\x00\x00\x00\x01\x02\x0d\x08\x00\x0a\x01\x00\x00\x00\x02\x02\x0d" +
			"\x06\x00\x00\x00\x00",
		want: "1 "},
	{ // #13
		source: `begin if odd 2 then write 1 else write 2 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x02\x02\x06\x09\x00\x08\x01" +
			"\x00\x00\x00\x01\x02\x0d\x08\x00\x0a\x01\x00\x00\x00\x02\x02\x0d" +
			"\x06\x00\x00\x00\x00",
		want: "2 "},
	{ // #14
		source: `
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
		`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x00\x01\x00\x00\x00\x00\x02" +
			"\x07\x09\x00\x10\x01\x00\x00\x00\x00\x01\x00\x00\x00\x01\x02\x07" +
			"\x09\x00\x0d\x01\x00\x00\x00\x01\x02\x0d\x08\x00\x0f\x01\x00\x00" +
			"\x00\x00\x02\x0d\x08\x00\x12\x01\x00\x00\x00\x03\x02\x0d\x06\x00" +
			"\x00\x00\x00",
		want: "0 "},
	{ // #15
		source: `
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
		`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x00\x02" +
			"\x07\x09\x00\x10\x01\x00\x00\x00\x01\x01\x00\x00\x00\x01\x02\x07" +
			"\x09\x00\x0d\x01\x00\x00\x00\x01\x02\x0d\x08\x00\x0f\x01\x00\x00" +
			"\x00\x00\x02\x0d\x08\x00\x12\x01\x00\x00\x00\x03\x02\x0d\x06\x00" +
			"\x00\x00\x00",
		want: "3 "},
	{ // #16
		source: `begin write 10 * 2 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x0a\x01\x00\x00\x00\x02\x02" +
			"\x04\x02\x0d\x06\x00\x00\x00\x00",
		want: "20 "},
	{ // #17
		source: `begin write 100 / 2 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x64\x01\x00\x00\x00\x02\x02" +
			"\x05\x02\x0d\x06\x00\x00\x00\x00",
		want: "50 "},
	{ // #18
		source: `begin write 100 / 5 * 3 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x64\x01\x00\x00\x00\x05\x02" +
			"\x05\x01\x00\x00\x00\x03\x02\x04\x02\x0d\x06\x00\x00\x00\x00",
		want: "60 "},
	{ // #19
		source: `const a = 1; begin if odd a then write a end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x02\x06\x09\x00\x07\x01" +
			"\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00",
		want: "1 "},
	{ // #20
		source: `const a = 1; begin if odd a + 1 then write a end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x01\x02" +
			"\x02\x02\x06\x09\x00\x09\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00" +
			"\x00\x00",
		want: ""},
	{ // #21
		source: `begin if 1 = 1 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x01\x02" +
			"\x07\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: "1 "},
	{ // #22
		source: `begin if 1 = 2 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x02\x02" +
			"\x07\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: ""},
	{ // #23
		source: `begin if 1 <> 2 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x02\x02" +
			"\x0a\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: "1 "},
	{ // #24
		source: `begin if 1 <> 1 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x01\x02" +
			"\x0a\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: ""},
	{ // #25
		source: `begin if 1 >= 1 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x01\x02" +
			"\x0c\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: "1 "},
	{ // #26
		source: `begin if 2 >= 1 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x02\x01\x00\x00\x00\x01\x02" +
			"\x0c\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: "1 "},
	{ // #27
		source: `begin if 1 >= 2 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x02\x02" +
			"\x0c\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: ""},
	{ // #28
		source: `begin if 2 > 1 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x02\x01\x00\x00\x00\x01\x02" +
			"\x09\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: "1 "},
	{ // #29
		source: `begin if 1 > 1 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x01\x02" +
			"\x09\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: ""},
	{ // #30
		source: `begin if 1 < 2 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x02\x02" +
			"\x08\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: "1 "},
	{ // #31
		source: `begin if 1 < 1 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x01\x02" +
			"\x08\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: ""},
	{ // #32
		source: `begin if 1 <= 1 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x01\x02" +
			"\x0b\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: "1 "},
	{ // #33
		source: `begin if 1 <= 2 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x01\x01\x00\x00\x00\x02\x02" +
			"\x0b\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: "1 "},
	{ // #34
		source: `begin if 2 <= 1 then write 1 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x02\x01\x00\x00\x00\x01\x02" +
			"\x0b\x09\x00\x08\x01\x00\x00\x00\x01\x02\x0d\x06\x00\x00\x00\x00" +
			"",
		want: ""},
	{ // #35
		source: `var i; begin i:=0; repeat begin write i; i:=i+1 end until i > 3 end.`,
		input: "\x08\x00\x01\x07\x00\x03\x0a\x00\x00\x00\x02\x01\x00\x00\x00\x00\x02" +
			"\x10\x03\x00\x00\x00\x02\x02\x0d\x0a\x00\x00\x00\x02\x03\x00\x00" +
			"\x00\x02\x01\x00\x00\x00\x01\x02\x02\x02\x10\x03\x00\x00\x00\x02" +
			"\x01\x00\x00\x00\x03\x02\x09\x09\x00\x05\x06\x00\x00\x00\x00",
		want: "0 1 2 3 "},
	{ // #36
		source: `
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
		`,
		input: "\x08\x00\x1a\x08\x00\x0d\x08\x00\x03\x07\x00\x03\x0a\x00\x02\x00\x02" +
			"\x01\x00\x00\x00\x02\x02\x10\x0a\x00\x00\x00\x03\x01\x00\x00\x00" +
			"\x09\x02\x10\x03\x00\x02\x00\x02\x02\x0d\x06\x00\x02\x00\x00\x07" +
			"\x00\x03\x0a\x00\x01\x00\x02\x01\x00\x00\x00\x01\x02\x10\x0a\x00" +
			"\x00\x00\x03\x01\x00\x00\x00\x01\x02\x10\x0a\x00\x00\x00\x04\x05" +
			"\x00\x01\x00\x03\x02\x10\x03\x00\x01\x00\x02\x02\x0d\x06\x00\x01" +
			"\x00\x00\x07\x00\x05\x0a\x00\x00\x00\x02\x01\x00\x00\x00\x00\x02" +
			"\x10\x0a\x00\x00\x00\x03\x01\x00\x00\x00\x00\x02\x10\x0a\x00\x00" +
			"\x00\x04\x05\x00\x00\x00\x0d\x02\x10\x03\x00\x00\x00\x02\x02\x0d" +
			"\x03\x00\x00\x00\x03\x02\x0d\x06\x00\x00\x00\x00",
		want: "2 1 0 9 "},
	{ // #37
		source: `var a; begin a := 64; write a end.`,
		input: "\x08\x00\x01\x07\x00\x03\x0a\x00\x00\x00\x02\x01\x00\x00\x00\x40\x02" +
			"\x10\x03\x00\x00\x00\x02\x02\x0d\x06\x00\x00\x00\x00",
		want: "64 "},
	{ // #38
		source: `var i; begin i:=0; while i<=3 do begin write i; i:=i+1 end end.`,
		input: "\x08\x00\x01\x07\x00\x03\x0a\x00\x00\x00\x02\x01\x00\x00\x00\x00\x02" +
			"\x10\x03\x00\x00\x00\x02\x01\x00\x00\x00\x03\x02\x0b\x09\x00\x11" +
			"\x03\x00\x00\x00\x02\x02\x0d\x0a\x00\x00\x00\x02\x03\x00\x00\x00" +
			"\x02\x01\x00\x00\x00\x01\x02\x02\x02\x10\x08\x00\x05\x06\x00\x00" +
			"\x00\x00",
		want: "0 1 2 3 "},
	{ // #39
		source: `begin write 128 end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x80\x02\x0d\x06\x00\x00\x00" +
			"\x00",
		want: "128 "},
	{ // #40
		source: `begin write 128; writeln end.`,
		input: "\x08\x00\x01\x07\x00\x02\x01\x00\x00\x00\x80\x02\x0d\x02\x0e\x06\x00" +
			"\x00\x00\x00",
		want: "128 \n"},
	{ // #41
		source: `begin writeln end.`,
		input:  "\x08\x00\x01\x07\x00\x02\x02\x0e\x06\x00\x00\x00\x00",
		want:   "\n"},
	{ // #42
		source: `begin writeln; writeln
		end.`,
		input: "\x08\x00\x01\x07\x00\x02\x02\x0e\x02\x0e\x06\x00\x00\x00\x00",
		want:  "\n\n"},
	{ // #43
		source: `
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
		`,
		input: "\x08\x00\x25\x08\x00\x02\x07\x00\x05\x0a\x00\x01\x00\x02\x03\x00\x01" +
			"\xff\xfe\x02\x10\x0a\x00\x01\x00\x03\x03\x00\x01\xff\xff\x02\x10" +
			"\x0a\x00\x01\x00\x04\x01\x00\x00\x00\x00\x02\x10\x03\x00\x01\x00" +
			"\x03\x01\x00\x00\x00\x00\x02\x09\x09\x00\x23\x03\x00\x01\x00\x03" +
			"\x02\x06\x09\x00\x18\x0a\x00\x01\x00\x04\x03\x00\x01\x00\x04\x03" +
			"\x00\x01\x00\x02\x02\x02\x02\x10\x0a\x00\x01\x00\x02\x01\x00\x00" +
			"\x00\x02\x03\x00\x01\x00\x02\x02\x04\x02\x10\x0a\x00\x01\x00\x03" +
			"\x03\x00\x01\x00\x03\x01\x00\x00\x00\x02\x02\x05\x02\x10\x08\x00" +
			"\x0c\x03\x00\x01\x00\x04\x06\x00\x01\x00\x02\x07\x00\x04\x0a\x00" +
			"\x00\x00\x02\x01\x00\x00\x00\x07\x02\x10\x0a\x00\x00\x00\x03\x01" +
			"\x00\x00\x00\x55\x02\x10\x03\x00\x00\x00\x02\x02\x0d\x03\x00\x00" +
			"\x00\x03\x02\x0d\x02\x0e\x03\x00\x00\x00\x02\x03\x00\x00\x00\x03" +
			"\x05\x00\x00\x00\x02\x02\x0d\x02\x0e\x06\x00\x00\x00\x00",
		want: "7 85 \n595 \n"},
	{ // #44
		source: `
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
		`,
		input: "\x08\x00\x10\x08\x00\x02\x07\x00\x02\x03\x00\x01\xff\xff\x01\x00\x00" +
			"\x00\x01\x02\x07\x09\x00\x09\x01\x00\x00\x00\x01\x06\x00\x01\x00" +
			"\x01\x03\x00\x01\xff\xff\x03\x00\x01\xff\xff\x01\x00\x00\x00\x01" +
			"\x02\x03\x05\x00\x00\x00\x02\x02\x04\x06\x00\x01\x00\x01\x07\x00" +
			"\x03\x0a\x00\x00\x00\x02\x01\x00\x00\x00\x01\x02\x10\x03\x00\x00" +
			"\x00\x02\x01\x00\x00\x00\x0a\x02\x08\x09\x00\x24\x03\x00\x00\x00" +
			"\x02\x02\x0d\x03\x00\x00\x00\x02\x05\x00\x00\x00\x02\x02\x0d\x02" +
			"\x0e\x0a\x00\x00\x00\x02\x03\x00\x00\x00\x02\x01\x00\x00\x00\x01" +
			"\x02\x02\x02\x10\x08\x00\x14\x06\x00\x00\x00\x00",
		want: "1 1 \n2 2 \n3 6 \n4 24 \n5 120 \n6 720 \n7 5040 \n8 40320 \n9 362880 \n"},
}

func readAndRun(binInput string) (string, error) {
	instructions, err := ReadInstructions(strings.NewReader(binInput))
	if err != nil {
		return "", err
	}
	outBuf := bytes.NewBufferString("")
	vm := NewPL0VM()
	vm.Output = outBuf
	err = vm.Run(instructions)
	return outBuf.String(), err
}

func TestInspectionTargets(t *testing.T) {
	for nth, target := range inspectionTargets {
		got, err := readAndRun(target.input)
		if err != nil {
			t.Errorf("#%d: Error: %s\nSource: %s", nth, err, target.source)
		} else if got != target.want {
			t.Errorf("#%d: Got: %s\nWant: %s\nSouece: %s",
				nth, got, target.want, target.source)
		}
	}
}

func TestExamplesFib(t *testing.T) {
	// examples/fib.pl0
	input :=
		"\x08\x00\x13\x08\x00\x02\x07\x00\x02\x03\x00\x01\xff\xff\x01\x00" +
			"\x00\x00\x02\x02\x0b\x09\x00\x09\x01\x00\x00\x00\x01\x06\x00\x01" +
			"\x00\x01\x03\x00\x01\xff\xff\x01\x00\x00\x00\x01\x02\x03\x05\x00" +
			"\x00\x00\x02\x03\x00\x01\xff\xff\x01\x00\x00\x00\x02\x02\x03\x05" +
			"\x00\x00\x00\x02\x02\x02\x06\x00\x01\x00\x01\x07\x00\x03\x0a\x00" +
			"\x00\x00\x02\x01\x00\x00\x00\x01\x02\x10\x03\x00\x00\x00\x02\x01" +
			"\x00\x00\x00\x0a\x02\x0b\x09\x00\x25\x03\x00\x00\x00\x02\x05\x00" +
			"\x00\x00\x02\x02\x0d\x02\x0e\x0a\x00\x00\x00\x02\x03\x00\x00\x00" +
			"\x02\x01\x00\x00\x00\x01\x02\x02\x02\x10\x08\x00\x17\x06\x00\x00" +
			"\x00\x00"
	want := "1 \n1 \n2 \n3 \n5 \n8 \n13 \n21 \n34 \n55 \n"

	got, err := readAndRun(input)
	if err != nil {
		t.Error(err)
	} else if got != want {
		t.Errorf("Got: %s\nWant: %s", got, want)
	}
}

func TestUnknownInstructionCode(t *testing.T) {
	wantMsg := "Unknown instruction code: 0"
	instructions := []Instruction{&ValueInstruction{0, 0}}
	vm := NewPL0VM()
	err := vm.Run(instructions)

	if err == nil {
		t.Error("No error")
	} else if err.Error() != wantMsg {
		t.Errorf("Got: %s\nWant: %s", err.Error(), wantMsg)
	}
}

func TestUnknownOperationType(t *testing.T) {
	wantMsg := "Unknown operation type: 0"
	instructions := []Instruction{&OperationInstruction{InstructOPR, 0}}
	vm := NewPL0VM()
	err := vm.Run(instructions)

	if err == nil {
		t.Error("No error")
	} else if err.Error() != wantMsg {
		t.Errorf("Got: %s\nWant: %s", err.Error(), wantMsg)
	}
}