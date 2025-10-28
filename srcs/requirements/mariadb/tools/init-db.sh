#!/bin/bash
# ============================================================================ #
#                       MariaDB 初期化スクリプト                                #
# ============================================================================ #
# データベース、ユーザー、権限を初期化し、MariaDB を起動
# ============================================================================ #

set -e  # エラーが発生したら即座にスクリプトを終了

# ---------------------------------------------------------------------------- #
# 色定義（ログ出力用）
# ---------------------------------------------------------------------------- #

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ---------------------------------------------------------------------------- #
# ログ出力関数
# ---------------------------------------------------------------------------- #

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ---------------------------------------------------------------------------- #
# 環境変数の確認
# ---------------------------------------------------------------------------- #

log_info "環境変数を確認中..."

# 必須の環境変数が設定されているか確認
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    log_error "MYSQL_ROOT_PASSWORD が設定されていません"
    exit 1
fi

if [ -z "$MYSQL_DATABASE" ]; then
    log_error "MYSQL_DATABASE が設定されていません"
    exit 1
fi

if [ -z "$MYSQL_USER" ]; then
    log_error "MYSQL_USER が設定されていません"
    exit 1
fi

if [ -z "$MYSQL_PASSWORD" ]; then
    log_error "MYSQL_PASSWORD が設定されていません"
    exit 1
fi

log_info "すべての必須環境変数が設定されています"

# ---------------------------------------------------------------------------- #
# MariaDB の初期化（初回起動時のみ）
# ---------------------------------------------------------------------------- #

# MariaDB が初期化済みかどうかを確認
# wordpress_db ディレクトリが存在しない場合は初期化する
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    log_info "データベースが初期化されていません。セットアップを開始します..."
    
    # データディレクトリが完全に空の場合は mysql_install_db を実行
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        log_info "データディレクトリが空です。MariaDB を初期化します..."
        
        # MariaDB のデータディレクトリを初期化
        mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
        
        log_info "MariaDB の初期化が完了しました"
    fi
    
    # --------------------------------------------------------------------------
    # 一時的に MariaDB を起動して初期設定を行う
    # --------------------------------------------------------------------------
    
    log_info "一時的に MariaDB を起動しています..."
    
    # バックグラウンドで MariaDB を起動
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    
    # MariaDB のプロセス ID を保存
    MYSQL_PID=$!
    
    log_info "MariaDB の起動を待機中..."
    
    # MariaDB が起動するまで待機（最大 30 秒）
    for i in {1..30}; do
        if mysqladmin ping --silent 2>/dev/null; then
            log_info "MariaDB が起動しました"
            break
        fi
        if [ $i -eq 30 ]; then
            log_error "MariaDB の起動がタイムアウトしました"
            exit 1
        fi
        sleep 1
    done
    
    # --------------------------------------------------------------------------
    # データベースとユーザーの作成
    # --------------------------------------------------------------------------
    
    log_info "データベースとユーザーを作成中..."
    
    # SQL コマンドを実行
    mysql <<-EOSQL
        -- ルートパスワードを設定
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        
        -- リモートルートアクセスを削除（セキュリティ）
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        
        -- 匿名ユーザーを削除（セキュリティ）
        DELETE FROM mysql.user WHERE User='';
        
        -- test データベースを削除（セキュリティ）
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
        
        -- WordPress 用のデータベースを作成
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        
        -- WordPress 用のユーザーを作成（任意のホストから接続可能）
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        
        -- WordPress ユーザーにデータベースへのすべての権限を付与
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        
        -- 権限テーブルを再読み込み
        FLUSH PRIVILEGES;
EOSQL
    
    log_info "データベースとユーザーの作成が完了しました"
    
    # --------------------------------------------------------------------------
    # 一時的な MariaDB プロセスを停止
    # --------------------------------------------------------------------------
    
    log_info "一時的な MariaDB プロセスを停止中..."
    
    # MariaDB をシャットダウン
    if ! mysqladmin shutdown -p"${MYSQL_ROOT_PASSWORD}" 2>/dev/null; then
        log_warn "正常なシャットダウンに失敗しました。プロセスを強制終了します..."
        kill -TERM $MYSQL_PID
        wait $MYSQL_PID
    fi
    
    log_info "初期化が完了しました"
else
    log_info "データベースは既に初期化されています。セットアップをスキップします"
fi

# ---------------------------------------------------------------------------- #
# MariaDB を起動（フォアグラウンド）
# ---------------------------------------------------------------------------- #

log_info "MariaDB を起動しています..."

# MariaDB をフォアグラウンドで実行
# --user=mysql: mysql ユーザーで実行
# --datadir=/var/lib/mysql: データディレクトリを指定
# --bind-address=0.0.0.0: すべてのネットワークインターフェースでリッスン
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0

