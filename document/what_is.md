
- SSL/TLSとは
> https://www.infraexpert.com/study/security7.html
- SSL/TLS ver1.2/ver1.3の違い
> https://qiita.com/tom_S/items/f2033fd33d8821ec4f19


- nginx と PHP-FPMとは何？
> https://qiita.com/kotarella1110/items/634f6fafeb33ae0f51dc



## NGINXを用いて何がしたいのか？
- Inceptionプロジェクトにおけるnginxの3つの役割
1. HTTPSターミネーション（TLS終端処理）
```
ブラウザ ─(HTTPS/443)→ NGINX ─(HTTP/9000)→ WordPress
         [暗号化]              [平文]
```
	- 外部からの暗号化通信を受け付ける
    - TLSv1.2/1.3でSSL/TLS通信を処理
    - 内部のWordPressは暗号化を意識しなくて良い
2. リバースプロキシ
```
NGINX (ポート443) ⟷ WordPress (ポート9000)
  ↓                    ↓
静的ファイル配信      PHP処理（PHP-FPM）
```
    -  静的ファイル（CSS/JS/画像）は直接配信
    -  PHPファイルはWordPressコンテナに転送
3. ゲートウェイ（唯一の外部公開ポート）
    -  NGINXのみがホストの443ポートを公開
    -  WordPressとMariaDBは内部ネットワークのみ
	  