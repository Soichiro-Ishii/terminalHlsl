# 何ということでしょう！windowsのターミナルの画面をHLSLでいじることができます！
* [ps1.hlsl](/terminal/ps1.hlsl) - 水滴が落ちてくるアニメーション<br>
  ![gif](gif2.gif)![gif](gif3.gif)
* [ps2.hlsl](/terminal/ps2.hlsl) - ブラックホールの周りを回るアニメーション<br>
  ![gif](gif1.gif)![gif](gif4.gif)<br>
  [背景の画像](https://svs.gsfc.nasa.gov/4851/)はNASAの天の川銀河のskyMapを使用しています。<br>
  (NASAありがとう⸜(*ˊᵕˋ*)⸝‬ｱﾘｶﾞﾄｳ♡)<br>
* 設定でアクリル素材を有効にするとモダンになります。
* 一応ps2.hlslの処理のコストとして例を上げると、
	- IntelのN150と内蔵GPUではコマンド操作はラグいけど、背景処理のアニメーションはそれほどカクついてはいない
	- i3-10100FとRTX3050では快適
# PSを適用するには
ターミナルにて設定->JSONファイルを開く、で設定ファイルを開きprofilesの中のdefaultなどに、
```
"experimental.pixelShaderPath": "psのファイルのパス"
```
を入れてください。詳しくは[Microsoftのサイト](https://learn.microsoft.com/en-us/windows/terminal/samples )で確認してください。
追加でexperimental.pixelShaderImagePathで画像のパスを設定しないといけません。
## 動作環境

- Windows Terminal
- Windows 11 (Windows 10は未確認)
- NVIDIA GPU: 動作確認済み
- Intel 内蔵GPU: 動作確認済み
- AMD GPU: 未確認
# Credits

Background sky texture based on imagery from NASA Scientific Visualization Studio:
https://svs.gsfc.nasa.gov/4851/
# ライセンス(守らなくても怒らないけど守ってね)
[MITライセンス](LICENSE)
