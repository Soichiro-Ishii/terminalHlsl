# 何ということでしょう！windowsのターミナルの画面をHLSLでいじることができます！
* [ps1.hlsl](/terminal/ps1.hlsl) - 水滴が落ちてくるアニメーション
* [ps2.hlsl](/terminal/ps2.hlsl) - ブラックホールの周りを回るアニメーション <br>
**注意**:ps2.hlslを使うにはexperimental.pixelShaderImagePathをセットする必要があります。
# psを適応するには
ターミナルにて設定->JSONファイルを開く、で設定ファイルを開きprofilesの中のdefaultなどに、
```
"experimental.pixelShaderPath": "psのファイルのパス"
```
を入れてください。詳しくは[Microsoftのサイト](https://learn.microsoft.com/en-us/windows/terminal/samples )で確認してください。
