# 🚀 クイックスタートガイド

## 前提条件

- Docker と Docker Compose がインストールされていること
- sudo 権限があること

## セットアップ（5ステップ）

### 1️⃣ 環境変数の設定

```bash
# srcs/.env ファイルは既に作成済みです
# パスワードやドメイン名を編集してください
nano srcs/.env
```

**重要な設定項目:**
- `DOMAIN_NAME` → あなたのログイン名に変更（例：hmori.42.fr）
- すべての `PASSWORD` 項目 → 安全なパスワードに変更

### 2️⃣ /etc/hosts の設定

```bash
# ドメイン名を追加
echo "127.0.0.1    hmori.42.fr" | sudo tee -a /etc/hosts
```

### 3️⃣ データディレクトリの作成

```bash
# Makefile が自動で作成しますが、手動でも可能
sudo mkdir -p /home/hana/data/{wordpress,mariadb}
```

### 4️⃣ ビルドと起動

```bash
# プロジェクトルートで実行
make
```

これで以下が実行されます：
1. データディレクトリ作成
2. Docker イメージビルド
3. コンテナ起動

### 5️⃣ アクセス確認

ブラウザで以下にアクセス：
```
https://hmori.42.fr
```

## 📝 よく使うコマンド

```bash
# ログを確認
make logs

# ステータス確認
make status

# 再起動
make restart

# 停止
make down

# すべて削除して再構築
make re
```

## ⚠️ トラブルシューティング

### コンテナが起動しない

```bash
# ログを確認
make logs

# 特定のサービスのログを確認
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### ポート 443 が使用中

```bash
# ポートを使用しているプロセスを確認
sudo lsof -i :443

# 該当プロセスを停止してから再度 make
```

### データベース接続エラー

```bash
# MariaDB コンテナに入る
docker exec -it mariadb bash

# MariaDB に接続
mysql -uroot -p  # .env の MYSQL_ROOT_PASSWORD を入力

# データベースとユーザーを確認
SHOW DATABASES;
SELECT User, Host FROM mysql.user;
```

## 🎉 成功の確認

以下が表示されれば成功です：

1. ✅ `make status` で 3 つのコンテナが "Up" 状態
2. ✅ ブラウザで WordPress のセットアップ画面が表示される
3. ✅ `.env` で設定した管理者でログイン可能

## 🔧 詳細設定

### HTTPS 証明書

自己署名証明書が自動生成されます。本番環境では Let's Encrypt などを使用してください。

### WordPress プラグイン

WordPress 管理画面からプラグインをインストール・有効化できます。

### データのバックアップ

```bash
# WordPress ファイル
sudo tar czf wordpress-backup.tar.gz /home/hana/data/wordpress

# データベース
docker exec mariadb mysqldump -uroot -p[PASSWORD] wordpress_db > db-backup.sql
```

---

**質問やエラーが発生した場合は、`make logs` でログを確認してください！**

