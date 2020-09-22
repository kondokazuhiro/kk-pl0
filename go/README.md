# kk-PL/0 VM (Go版)

kk-PL/0 の VM(仮想マシン)をGo言語で実装したものです。
ruby版(pl0vm.rb)よりも高速です。

## Go版PL/0 VMのビルド

Goがインストールされている状態で、以下を入力します（$ はプロンプトを表します）。

```
$ go build ./cmd/pl0vm
````

ビルドが成功すると、実行形式ファイル pl0vm (Windowsの場合 pl0vm.exe)が生成されます。

## PL/0プログラムの実行

PL/0 VMのバイナリコード(pl0c.rbでコンパイルした結果)が納められたプログラムファイルを
コマンドライン引数として実行します。

実行形式ファイル pl0vm とプログラムファイル(例えば prog.pl0vm)が
カレントディレクトリにある場合は、次のように入力します。

```
$ ./pl0vm prog.pl0vm
```

## 例

以下は、付属のPL/0サンプルソース ../examples/fib.pl0 を、ruby版コンパイラ pl0c.rb で
コンパイルし、Go版VM(pl0vm)で実行する例です。

ruby版コンパイラでコンパイル。

```
$ ruby ../pl0c.rb ../examples/fib.pl0
```

../examples/fib.pl0vm が生成される。

```
$ ls ../examples/fib.pl0vm
../examples/fib.pl0vm
```

Go版VMで実行。

```
$ ./pl0vm ../examples/fib.pl0vm
1 
1 
2 
3 
5 
8 
13 
21 
34 
55 
```

## ruby版との実行速度比較

ベンチマークPL/0プログラム

```
$ cat ../examples/tarai.pl0
function tarai(x, y, z)
begin
  if x <= y then return y;
  return tarai(tarai(x-1, y, z),
               tarai(y-1, z, x),
               tarai(z-1, x, y))
end;

begin
  write tarai(12, 6, 0);
  writeln
end.
```

コンパイル

```
$ ruby ../pl0c.rb ../examples/tarai.pl0
```

ruby版PL/0 VM で実行(単位:秒)：

```
$ /usr/bin/time ruby ../pl0vm.rb ../examples/tarai.pl0vm
12 
       46.28 real        46.23 user         0.03 sys
```

Go版PL/0 VM で実行：

```
$ /usr/bin/time ./pl0vm ../examples/tarai.pl0vm
12 
        0.92 real         0.91 user         0.00 sys
```

ちなみに、同じベンチマークプログラムを ruby スクリプトとして書き
ruby で直接実行した場合：

```ruby
# tarai.rb
def tarai(x, y, z)
  return y if x <= y
  tarai(tarai(x-1, y, z),
        tarai(y-1, z, x),
        tarai(z-1, x, y))
end

print(tarai(12, 6, 0), "\n")
```

```
$ ruby --version
ruby 2.6.3p62 (2019-04-16 revision 67580) [universal.x86_64-darwin19]
$ /usr/bin/time ruby tarai.rb
12
        0.40 real         0.37 user         0.02 sys
```

実行環境

```
macOS Catalina
Intel(R) Core(TM) i5-1038NG7 CPU @ 2.00GHz
```
