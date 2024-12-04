# Dothen
vimで非同期的にサブプロセスやtimerを扱う時にコールバック地獄を軽減するやつ。これはvimslideというvimでスライドを作るという変態プラグインにおけるコールバック地獄に対するために書かれた。

# 記法

```
Do 「vimのコマンド」
Sh 「Shellのコマンド」
Timer ミリ秒 「後で実行するコマンド」
```

こんな感じに書くのだけれど、これを「Then」でチェインできるようにする。つまり…

```vim
Do 「vimのコマンド」
  \Then Sh 「Shellのコマンド」
  \Then Timer 4000 ミリ秒 「後で実行するコマンド」
  \Then Sh 「Shellのコマンド」
  \Do 「vimのコマンド」
echo 'hoge'
```

みたいにすると、Do以下はチェインして、シェルやタイマーが動いている間に二行目の「echo 'hoge'」と同時に動く。もちろん、「Then」なんて一般単語をセパレータにする以上、これは変更できる。