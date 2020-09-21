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

PL/0 VMのバイナリコードが納められたプログラムファイルを
コマンドライン引数として実行します。

実行形式ファイル pl0vm とプログラムファイルが  prog.pl0vm がカレントディレクトリに
ある場合は、次のように入力します。

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
