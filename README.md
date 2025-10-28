# Inception プロジェクト

Docker Compose を使用して、NGINX、WordPress、MariaDB を構築する 42 スクールのプロジェクトです。

## 📋 プロジェクト概要

このプロジェクトは、以下の 3 つのサービスを Docker コンテナとして構築します：

- **NGINX**: TLSv1.2/1.3 対応のリバースプロキシサーバー
- **WordPress**: PHP-FPM で動作する CMS
- **MariaDB**: WordPress のデータベース

## 🏗️ プロジェクト構造

```
Inception/
├── Makefile                      # プロジェクトのビルド・起動・停止コマンド
├── .gitignore                    # Git 除外ファイル
├── README.md                     # このファイル
└── srcs/
    ├── docker-compose.yml        # Docker Compose 設定
    ├── env.sample                # 環境変数のサンプル（.env にコピーして使用）
    └── requirements/
        ├── nginx/                # NGINX サービス
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        ├── wordpress/            # WordPress サービス
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── www.conf
        │   └── tools/
        │       └── setup-wordpress.sh
        └── mariadb/              # MariaDB サービス
            ├── Dockerfile
            ├── conf/
            │   └── 50-server.cnf
            └── tools/
                └── init-db.sh
```

## 🚀 セットアップ手順

### 1. 環境変数ファイルの作成

```bash
cd srcs
cp env.sample .env
```

`.env` ファイルを編集して、以下の項目を自分の環境に合わせて変更してください：

- `DOMAIN_NAME`: ドメイン名（例：hmori.42.fr）
- `MYSQL_ROOT_PASSWORD`: MariaDB のルートパスワード
- `MYSQL_PASSWORD`: WordPress 用のデータベースパスワード
- `WORDPRESS_ADMIN_USER`: WordPress 管理者ユーザー名（'admin' は禁止）
- `WORDPRESS_ADMIN_PASSWORD`: WordPress 管理者パスワード
- その他のパスワードや設定

### 2. ホストファイルの編集

`/etc/hosts` にドメイン名を追加します：

```bash
sudo nano /etc/hosts
```

以下の行を追加（ドメイン名を自分のものに変更）：

```
127.0.0.1    hmori.42.fr
```

### 3. データディレクトリの作成

プロジェクトのビルド前に、データディレクトリを作成します（Makefile が自動で実行）：

```bash
make create_dirs
```

または手動で：

```bash
mkdir -p /home/hana/data/wordpress
mkdir -p /home/hana/data/mariadb
```

### 4. プロジェクトのビルドと起動

```bash
make
```

このコマンドは以下を実行します：
1. データディレクトリの作成
2. Docker イメージのビルド
3. コンテナの起動

## 📝 Makefile コマンド

| コマンド | 説明 |
|---------|------|
| `make` または `make all` | すべてをビルドして起動 |
| `make build` | Docker イメージをビルド |
| `make up` | コンテナを起動 |
| `make down` | コンテナを停止 |
| `make restart` | コンテナを再起動 |
| `make clean` | コンテナとネットワークを削除 |
| `make fclean` | すべて削除（イメージ、データ含む） |
| `make re` | 完全に再構築 |
| `make status` | コンテナの状態を表示 |
| `make logs` | ログを表示 |

## 🌐 アクセス方法

プロジェクトが起動したら、ブラウザで以下にアクセスします：

```
https://hmori.42.fr
```

（自己署名証明書を使用しているため、ブラウザに警告が表示されますが、「詳細」→「続行」で進めます）

## 🔐 セキュリティ要件

- ✅ すべてのパスワードは `.env` ファイルで管理
- ✅ `.env` ファイルは `.gitignore` に含まれている
- ✅ Dockerfile にパスワードを直接記述していない
- ✅ TLSv1.2/1.3 のみを使用
- ✅ ポート 443 のみを公開

## 📦 技術スタック

- **ベースイメージ**: Debian 11 (Bullseye)
- **NGINX**: 最新の Debian パッケージ版
- **PHP**: 7.4-FPM
- **MariaDB**: 最新の Debian パッケージ版
- **WordPress**: WP-CLI で自動インストール

## ⚠️ 注意事項

### プロジェクト要件の遵守

- ✅ `latest` タグを使用していない
- ✅ Docker Hub からの既製イメージを使用していない（Alpine/Debian を除く）
- ✅ `network: host`, `--link`, `links:` を使用していない
- ✅ 無限ループ（`tail -f`, `while true`, `sleep infinity` など）を使用していない
- ✅ すべてのコンテナは適切なプロセスをフォアグラウンドで実行
- ✅ クラッシュ時に自動再起動（`restart: always`）

### WordPress ユーザー

プロジェクト要件により、WordPress に 2 人のユーザーが作成されます：

1. **管理者ユーザー**: `.env` の `WORDPRESS_ADMIN_USER` で設定（'admin' は禁止）
2. **一般ユーザー**: `.env` の `WORDPRESS_USER` で設定

## 🐛 トラブルシューティング

### コンテナが起動しない

```bash
make logs
```

でログを確認してください。

### ポートが既に使用されている

```bash
sudo lsof -i :443
```

でポート 443 を使用しているプロセスを確認し、停止してください。

### データベース接続エラー

`.env` ファイルの以下の項目が一致しているか確認してください：

- `MYSQL_DATABASE` = `WORDPRESS_DB_NAME`
- `MYSQL_USER` = `WORDPRESS_DB_USER`
- `MYSQL_PASSWORD` = `WORDPRESS_DB_PASSWORD`

### すべてをリセットしたい

```bash
make fclean
make
```

## 📚 参考資料

- [Docker ドキュメント](https://docs.docker.com/)
- [Docker Compose ドキュメント](https://docs.docker.com/compose/)
- [NGINX ドキュメント](https://nginx.org/en/docs/)
- [WordPress ドキュメント](https://wordpress.org/support/)
- [MariaDB ドキュメント](https://mariadb.org/documentation/)
- [WP-CLI ドキュメント](https://wp-cli.org/)

## 👤 作成者

hana - 42 Tokyo

## 📄 ライセンス

このプロジェクトは 42 スクールの課題として作成されました。

