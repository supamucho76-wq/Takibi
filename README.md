# くべる

歩数で薪を集め、決して消えない焚き火を育てるiOS 17向けSwiftUIアプリです。フェーズ1は端末内だけで動作し、HealthKit、サーバー、ログイン、外部ライブラリを使用しません。

## 構成

- SwiftUI: 画面、環境光、薪レイヤー
- MetalKit: fBm、2段ドメインワープ、移流を使った炎、熾火、火の粉
- Core Motion: `CMPedometer`による履歴照会とリアルタイム歩数
- JSON: Application Supportへの原子的な状態保存
- XcodeGen: Xcodeプロジェクト生成
- Codemagic: シミュレータ検証とTestFlight配布

## Macでのローカルビルド

```sh
brew install xcodegen
cd Takibi
xcodegen generate
xcodebuild test \
  -project Takibi.xcodeproj \
  -scheme Takibi \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

`Takibi.xcodeproj`は生成物のためGitへコミットしません。

## Windows + Codemagic + iPhone

1. `project.yml`の`PRODUCT_BUNDLE_IDENTIFIER`を自分の一意なBundle IDへ変更します。
2. GitHubへリポジトリをpushし、Codemagicでリポジトリを追加します。
3. `ios-simulator`ワークフローで署名なしビルドとテストを確認します。
4. Apple Developer ProgramとApp Store Connectで同じBundle IDのApp ID・アプリレコードを作成します。
5. App Store ConnectのAPIキーを作成し、Codemagicの`appstore_credentials`グループへ次をSecretとして登録します。
   - `APP_STORE_CONNECT_PRIVATE_KEY`
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - `APP_STORE_CONNECT_ISSUER_ID`
6. `ios_config`グループへ`BUNDLE_ID`を登録します。
7. Git tagをpushするか、Codemagic画面から`ios-testflight`を手動実行します。
8. 処理後、iPhoneのTestFlightからインストールします。

秘密鍵や証明書はリポジトリへ保存しないでください。

## 実機確認

- 初回説明の後にモーション権限ダイアログが出ること
- アプリ終了中に歩いた分が次回起動時に加算されること
- 500歩をまたぐと薪が1本増え、端数が次回へ繰り越されること
- 「くべる」で薪が減り、炎・環境光・火の粉が連続的に強くなること
- 長時間放置後も`heat = 8`の熾火が残ること
- 通常時60fps、低電力モード時30fpsになること
- 30秒ごとの`FireRenderer`ログでfps、粒子数、品質係数、熱状態、バッテリー残量を確認すること

## フェーズ1で意図的に含めないもの

複数の薪、レアリティ、背景アンロック、通知、実績、統計、iCloud同期、課金は将来拡張用です。
