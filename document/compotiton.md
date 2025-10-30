プロジェクトの構成を理解するため、まずディレクトリ構造を確認させていただきます。

[18 tools called]

それでは、このInceptionプロジェクトの構成図と、ポート制限、Dockerの内外のデータの結びつきについて、コードと見比べながら詳しく説明します。

## 📊 プロジェクト全体構成図

```
┌─────────────────────────────────────────────────────────────────┐
│                         ホストマシン                               │
│                     (linux WSL2 環境)                            │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              Docker Compose 環境                        │    │
│  │                                                         │    │
│  │  ┌──────────────────────────────────────────────┐      │    │
│  │  │  NGINX コンテナ (ポート 443)                  │      │    │
│  │  │  ┌──────────────────────────┐                │      │    │
│  │  │  │  - TLSv1.2/1.3 のみ      │                │      │    │
│  │  │  │  - リバースプロキシ      │                │      │    │
│  │  │  │  - 自己署名証明書        │                │      │    │
│  │  │  └──────────────────────────┘                │      │    │
│  │  └───────────┬──────────────────────────────────┘      │    │
│  │              │ FastCGI (wordpress:9000)                │    │
│  │              ↓                                         │    │
│  │  ┌──────────────────────────────────────────────┐      │    │
│  │  │  WordPress コンテナ (ポート 9000)            │      │    │
│  │  │  ┌──────────────────────────┐                │      │    │
│  │  │  │  - PHP-FPM 7.4           │                │      │    │
│  │  │  │  - WP-CLI                │                │      │    │
│  │  │  │  - WordPress 本体        │                │      │    │
│  │  │  └──────────────────────────┘                │      │    │
│  │  └───────────┬──────────────────────────────────┘      │    │
│  │              │ MySQL接続 (mariadb:3306)                │    │
│  │              ↓                                         │    │
│  │  ┌──────────────────────────────────────────────┐      │    │
│  │  │  MariaDB コンテナ (ポート 3306)              │      │    │
│  │  │  ┌──────────────────────────┐                │      │    │
│  │  │  │  - MariaDB Server        │                │      │    │
│  │  │  │  - UTF-8 (utf8mb4)       │                │      │    │
│  │  │  │  - データベース           │                │      │    │
│  │  │  └──────────────────────────┘                │      │    │
│  │  └──────────────────────────────────────────────┘      │    │
│  │                                                         │    │
│  │  すべてのコンテナは inception-network で接続             │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              ホストのデータディレクトリ                    │    │
│  │                                                         │    │
│  │  /home/hana/data/wordpress  ←→ WordPress データ        │    │
│  │  /home/hana/data/mariadb    ←→ MariaDB データ          │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

外部からのアクセス: https://hmori.42.fr:443
```

## 🔌 ポート構成の詳細

### 1. **NGINX コンテナ（ポート 443）**

```40:40:srcs/docker-compose.yml
      - "443:443"
```

- **ホスト側**: ポート 443（HTTPS）
- **コンテナ側**: ポート 443
- **公開範囲**: **外部に公開される唯一のポート**
- **プロトコル**: HTTPS (TLSv1.2/1.3 のみ)

```90:91:srcs/requirements/nginx/conf/nginx.conf
        listen 443 ssl;
        listen [::]:443 ssl;
```

```107:107:srcs/requirements/nginx/conf/nginx.conf
        ssl_protocols TLSv1.2 TLSv1.3;
```

**重要**: このプロジェクトでは、**ポート443のみが外部に公開**されています。HTTPポート80は使用せず、完全にHTTPSのみでの運用となっています。

### 2. **WordPress コンテナ（ポート 9000）**

```107:108:srcs/requirements/wordpress/Dockerfile
# PHP-FPM のデフォルトポート 9000 を公開
EXPOSE 9000
```

```26:26:srcs/requirements/wordpress/conf/www.conf
listen = 0.0.0.0:9000
```

- **内部ポート**: 9000 (PHP-FPM)
- **公開範囲**: **コンテナ間通信のみ**（外部には非公開）
- **接続元**: NGINXコンテナからのみ

```150:150:srcs/requirements/nginx/conf/nginx.conf
            fastcgi_pass wordpress:9000;
```

### 3. **MariaDB コンテナ（ポート 3306）**

```64:65:srcs/requirements/mariadb/Dockerfile
# MySQL/MariaDB のデフォルトポート 3306 を公開
EXPOSE 3306
```

```23:24:srcs/requirements/mariadb/conf/50-server.cnf
# ポート番号
port = 3306
```

- **内部ポート**: 3306 (MySQL/MariaDB)
- **公開範囲**: **コンテナ間通信のみ**（外部には非公開）
- **接続元**: WordPressコンテナからのみ

```38:38:srcs/env.sample
WORDPRESS_DB_HOST=mariadb:3306
```

## 💾 データの永続化とバインドマウント

### 1. **WordPress データ**

```145:151:srcs/docker-compose.yml
  wordpress-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      # ホストマシンのパス（要件：/home/login/data）
      device: /home/hana/data/wordpress
```

**マウント構成:**

```48:48:srcs/docker-compose.yml
      - wordpress-data:/var/www/html:ro
```
（NGINX コンテナ: 読み取り専用）

```85:85:srcs/docker-compose.yml
      - wordpress-data:/var/www/html
```
（WordPress コンテナ: 読み書き可能）

**データの流れ:**
```
ホスト: /home/hana/data/wordpress
              ↕ (バインドマウント)
Docker ボリューム: wordpress-data
              ↕
WordPress コンテナ: /var/www/html (読み書き)
              ↕
NGINX コンテナ: /var/www/html (読み取りのみ)
```

**セキュリティポイント**: NGINXは`:ro`（読み取り専用）でマウントしており、WordPressファイルの改ざんを防いでいます。

### 2. **MariaDB データ**

```153:160:srcs/docker-compose.yml
  mariadb-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      # ホストマシンのパス（要件：/home/login/data）
      device: /home/hana/data/mariadb
```

```118:118:srcs/docker-compose.yml
      - mariadb-data:/var/lib/mysql
```

**データの流れ:**
```
ホスト: /home/hana/data/mariadb
              ↕ (バインドマウント)
Docker ボリューム: mariadb-data
              ↕
MariaDB コンテナ: /var/lib/mysql (データベースファイル)
```

## 🔐 セキュリティ設定

### 1. **ネットワーク分離**

```132:136:srcs/docker-compose.yml
networks:
  # カスタムネットワーク名
  inception-network:
    # ブリッジドライバーを使用（デフォルト）
    driver: bridge
```

すべてのコンテナは`inception-network`という独立したネットワーク内で通信し、外部からの直接アクセスは遮断されています。

### 2. **MariaDB のバインドアドレス**

```42:44:srcs/requirements/mariadb/conf/50-server.cnf
# バインドアドレス：0.0.0.0 で全てのネットワークインターフェースからの接続を許可
# Docker コンテナ間通信のために必要
bind-address = 0.0.0.0
```

**重要**: `bind-address = 0.0.0.0`に設定されていますが、これはコンテナ間通信のためです。外部ポートとしては公開されていないため、ホストマシンの外部からはアクセスできません。

### 3. **データベースユーザー権限**

```134:138:srcs/requirements/mariadb/tools/init-db.sh
        -- WordPress 用のユーザーを作成（任意のホストから接続可能）
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        
        -- WordPress ユーザーにデータベースへのすべての権限を付与
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
```

## 🔄 データフローの詳細

### リクエスト処理の流れ:

```
1. クライアント (ブラウザ)
   ↓ HTTPS リクエスト (ポート 443)
   
2. NGINX コンテナ
   - TLS 証明書で暗号化通信
   - 静的ファイル (.css, .js, 画像等) → 直接レスポンス
   - PHP ファイル → WordPress コンテナへ転送
   ↓ FastCGI プロトコル (ポート 9000)
   
3. WordPress コンテナ (PHP-FPM)
   - PHP スクリプトを実行
   - データベースへの問い合わせが必要な場合
   ↓ MySQL プロトコル (ポート 3306)
   
4. MariaDB コンテナ
   - データベースクエリを実行
   - 結果を返す
   ↑
   
3. WordPress コンテナ
   - HTML を生成
   ↑
   
2. NGINX コンテナ
   - レスポンスをクライアントに返す
   ↑ HTTPS レスポンス
   
1. クライアント (ブラウザ)
```

### 初期化の流れ:

```
1. MariaDB コンテナ起動
   ├─ mysql_install_db でデータベース初期化
   ├─ データベース作成 (wordpress_db)
   ├─ ユーザー作成 (wp_user)
   └─ 権限付与
   
2. WordPress コンテナ起動 (depends_on: mariadb)
   ├─ データベース接続待機 (最大60秒)
   ├─ WordPress コアダウンロード (WP-CLI)
   ├─ wp-config.php 生成
   ├─ WordPress インストール
   ├─ 管理者ユーザー作成
   ├─ 一般ユーザー作成
   └─ PHP-FPM 起動
   
3. NGINX コンテナ起動 (depends_on: wordpress)
   ├─ SSL証明書生成 (自己署名)
   └─ NGINX 起動
```

## 📝 環境変数による設定

環境変数ファイル（`.env`）を使用して、全コンテナの設定を一元管理しています:

```15:15:srcs/env.sample
DOMAIN_NAME=hmori.42.fr
```

```22:31:srcs/env.sample
MYSQL_ROOT_PASSWORD=root_secure_password_12345

# WordPress が使用するデータベース名
MYSQL_DATABASE=wordpress_db

# WordPress が使用する MariaDB ユーザー名
MYSQL_USER=wp_user

# WordPress が使用する MariaDB ユーザーのパスワード
MYSQL_PASSWORD=wp_secure_password_67890
```

この設計により、機密情報をコードから分離し、セキュリティを向上させています。

---

この構成は、**42 Tokyoの Inception プロジェクト**の要件に従って設計されており、以下の特徴があります:

✅ TLSv1.2/1.3のみのHTTPS通信  
✅ 外部公開はポート443のみ  
✅ コンテナ間は独立したネットワークで通信  
✅ データはホストマシンに永続化  
✅ 各コンテナは単一のサービスのみを実行  
✅ 自動再起動設定 (`restart: always`)

ご質問があれば、さらに詳しく説明します！