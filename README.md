# kk-PL/0 - PL/0 Compiler

書籍*『コンパイラ 』新コンピュータサイエンス講座, 中田育男, オーム社, 1995*
（以下『コンパイラ』）を読みつつ、Ruby で実装してみた PL/0 コンパイラです。
おもに『コンパイラ』に掲載されている PL/0' のＣ言語ソースコードを元にしま
したが、多少の省略と拡張とアレンジがあります。


## プログラム構成

次の Rubyスクリプトにより構成されます。

* **`pl0c.rb`**

  PL/0 コンパイラ。
  PL/0 ソースファイルをコンパイルし、PL/0 VM（仮想マシン）のバイナリコードを
  生成します。

* **`pl0vm.rb`**

  PL/0 VM （仮想マシン）。

* **`pl0as.rb`**

  PL/0 アセンブラ。
  PL/0 アセンブリコードをアセンブルし、PL/0 VM（仮想マシン）のバイナリコードを
  生成します。

* **`pl0common.rb`**

  上記各スクリプトの共通モジュール。


## 使いかた

### コンパイルと実行

まず、PL/0 で書かれたソースファイルを用意しておきます。
以下、PL/0 で書かれたソースファイル を prog.pl0 とします。
prog.pl0 をコンパイルするには、コマンドプロンプトから次のように
入力します（$ はプロンプトを表します）。

    $ ruby pl0c.rb prog.pl0

エラーなくコンパイルされると、PL/0 VM(仮想マシン)のバイナリコード
が納められたプログラムファイル prog.pl0vm が生成されます。

プログラム ファイル prog.pl0vm を実行するには、次のように入力します。

    $ ruby pl0vm.rb prog.pl0vm


### アセンブリコードの出力とアセンブル

次のようにコンパイラ pl0c.rb へ --as オプションを付けて実行すると、
コンパイル結果としてアセンブリコードを納めたファイル prog.pl0as が
生成されます。

    $ ruby pl0c.rb --as prog.pl0

アセンブリコード  prog.pl0as から、PL/0 VMバイナリコード を
生成するには次のように、アセンブラ pl0as.rb を実行します。

    $ ruby pl0as.rb prog.pl0as

エラーがなければプログラムファイル prog.pl0vm が生成されます。


### 確認済みの動作環境

次の OS と Ruby のバージョンで動作確認しました。

* Linux(CentOS5.7): Ruby 1.8.5
* Windows XP/Vista/7: Ruby 1.8.7, 1.9.2
* Mac OS X Lion: Ruby 1.8.7


## オリジナル PL/0 と書籍『コンパイラ』の PL/0'

オリジナルの PL/0 は絶版書籍*『アルゴリズム＋データ構造＝プログラム』
Niklaus Wirth(著), 片山卓也(訳),日本コンピュータ協会, 1979* の第５章
「言語構造とコンパイラ」で解説されている学習を目的としたコンパイラです。
『コンパイラ』で解説されている PL/0' は、オリジナルPL/0 に
若干の変更が加えられています。

オリジナル PL/0 と PL/0' のおもな違いは次の通り。

* パラメータなしの手続き（procedure）をパラメータ付きの関数（function）へ
  変更。これにともない、構文規則上 statement から call 文がなくなり、
  その代わりに式として factor へ関数呼び出しが追加されている。
* write 文(式を評価した値とスペースの出力)の追加。
* writeln 文(改行の出力)の追加。


## 書籍『コンパイラ』の PL/0' と kk-PL/0 の違い

書籍『コンパイラ』の PL/0' と kk-PL/0 のおもな違いは次の通りです。

### 第８章 P147 の演習問題を実装済み

* 演習問題 1: if 文に else 節を追加。
* 演習問題 2: repeat..until 文を追加。
* 演習問題 3: 配列を追加。
  配列を追加するにあたり、目的コードに必要な命令語は、
  書籍*『スモールコンパイラの制作で学ぶプログラムのしくみ』,石田 綾,
  技術評論社, 2004* で解説されている lda, lid, sid を使用しました。

### プログラム構成の違い

* 『コンパイラ』のPL/0' はコンパイラとＶＭが一体となっていますが、kk-PL/0では
  コンパイラとＶＭを分離して別々に実行するようになっています。

### エラー処理の違い

* 第７章「誤りの処理」に相当する実装は省略しています。
* kk-PL/0では、コンパイルエラーを検出した時点で行番号とメッセージを出力して
  終了します。

### 実装上の違い

* 字句解析とシンボル管理の実装は簡略化しています。
* その他、独自にアレンジしています。
