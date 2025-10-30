#!/bin/bash
# ============================================================================ #
#                       WordPress セットアップスクリプト                         #
# ============================================================================ #
# WordPress のダウンロード、設定、インストールを自動化
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
if [ -z "$WORDPRESS_DB_HOST" ]; then
	log_error "WORDPRESS_DB_HOST が設定されていません"
	exit 1
fi

if [ -z "$WORDPRESS_DB_NAME" ]; then
	log_error "WORDPRESS_DB_NAME が設定されていません"
	exit 1
fi

if [ -z "$WORDPRESS_DB_USER" ]; then
	log_error "WORDPRESS_DB_USER が設定されていません"
	exit 1
fi

if [ -z "$WORDPRESS_DB_PASSWORD" ]; then
	log_error "WORDPRESS_DB_PASSWORD が設定されていません"
	exit 1
fi

if [ -z "$WORDPRESS_SITE_URL" ]; then
	log_error "WORDPRESS_SITE_URL が設定されていません"
	exit 1
fi

if [ -z "$WORDPRESS_SITE_TITLE" ]; then
	log_error "WORDPRESS_SITE_TITLE が設定されていません"
	exit 1
fi

if [ -z "$WORDPRESS_ADMIN_USER" ]; then
	log_error "WORDPRESS_ADMIN_USER が設定されていません"
	exit 1
fi

if [ -z "$WORDPRESS_ADMIN_PASSWORD" ]; then
	log_error "WORDPRESS_ADMIN_PASSWORD が設定されていません"
	exit 1
fi

if [ -z "$WORDPRESS_ADMIN_EMAIL" ]; then
	log_error "WORDPRESS_ADMIN_EMAIL が設定されていません"
	exit 1
fi

if [ -z "$WORDPRESS_USER" ]; then
	log_error "WORDPRESS_USER が設定されていません"
	exit 1
fi

if [ -z "$WORDPRESS_USER_EMAIL" ]; then
	log_error "WORDPRESS_USER_EMAIL が設定されていません"
	exit 1
fi

if [ -z "$WORDPRESS_USER_PASSWORD" ]; then
	log_error "WORDPRESS_USER_PASSWORD が設定されていません"
	exit 1
fi

# ---------------------------------------------------------------------------- #
# 管理者ユーザー名のバリデーション
# ---------------------------------------------------------------------------- #

log_info "管理者ユーザー名を検証中..."

# 禁止されたキーワードのリスト（大文字小文字を区別しない）
FORBIDDEN_KEYWORDS=("admin" "administrator")

# 管理者ユーザー名を取得
ADMIN_USER="$WORDPRESS_ADMIN_USER"

# ユーザー名を小文字に変換してチェック
ADMIN_USER_LOWER=$(echo "$ADMIN_USER" | tr '[:upper:]' '[:lower:]')

# 禁止されたキーワードが含まれているかチェック
for keyword in "${FORBIDDEN_KEYWORDS[@]}"; do
	if echo "$ADMIN_USER_LOWER" | grep -q "$keyword"; then
		log_error "管理者ユーザー名 '${ADMIN_USER}' は使用できません"
		log_error "セキュリティ上の理由により、以下のキーワードを含むユーザー名は禁止されています："
		log_error "  - admin (etc: admin, Admin, admin-123)"
		log_error "  - administrator (etc: administrator, Administrator, Administrator-123)"
		log_error ".env ファイルで WORDPRESS_ADMIN_USER を別の名前に変更してください"
		exit 1
	fi
done

log_info "管理者ユーザー名 '${ADMIN_USER}' は有効です"

log_info "すべての必須環境変数が設定されています"

# ---------------------------------------------------------------------------- #
# データベース接続待機
# ---------------------------------------------------------------------------- #

log_info "データベースの起動を待機中..."

# データベースホストとポートを分離
DB_HOST=$(echo $WORDPRESS_DB_HOST | cut -d':' -f1)
DB_PORT=$(echo $WORDPRESS_DB_HOST | cut -d':' -f2)

# データベースが起動するまで待機（最大 60 秒）
for i in {1..60}; do
	if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; then
		log_info "データベースに接続できました"
		break
	fi
	if [ $i -eq 60 ]; then
		log_error "データベース接続がタイムアウトしました"
		exit 1
	fi
	log_warn "データベース接続待機中... (${i}/60)"
	sleep 1
done

# ---------------------------------------------------------------------------- #
# WordPress のダウンロード（初回のみ）
# ---------------------------------------------------------------------------- #

# WordPress がまだダウンロードされていない場合
if [ ! -f "/var/www/html/wp-config.php" ]; then
	log_info "WordPress をダウンロード中..."
	
	# WP-CLI を使って WordPress のコアファイルをダウンロード
	# --allow-root: root ユーザーでの実行を許可
	# --path: インストール先のパス
	wp core download --allow-root --path=/var/www/html --locale=ja
	
	log_info "WordPress のダウンロードが完了しました"
	
	# --------------------------------------------------------------------------
	# wp-config.php の生成
	# --------------------------------------------------------------------------
	
	log_info "wp-config.php を生成中..."
	
	# WP-CLI を使って wp-config.php を生成
	wp config create \
		--allow-root \
		--path=/var/www/html \
		--dbname="$WORDPRESS_DB_NAME" \
		--dbuser="$WORDPRESS_DB_USER" \
		--dbpass="$WORDPRESS_DB_PASSWORD" \
		--dbhost="$WORDPRESS_DB_HOST" \
		--dbcharset="utf8mb4" \
		--dbcollate="utf8mb4_unicode_ci" \
		--skip-check
	
	log_info "wp-config.php の生成が完了しました"
	
	# --------------------------------------------------------------------------
	# WordPress のインストール
	# --------------------------------------------------------------------------
	
	log_info "WordPress をインストール中..."
	
	# WP-CLI を使って WordPress をインストール
	wp core install \
		--allow-root \
		--path=/var/www/html \
		--url="$WORDPRESS_SITE_URL" \
		--title="$WORDPRESS_SITE_TITLE" \
		--admin_user="$WORDPRESS_ADMIN_USER" \
		--admin_password="$WORDPRESS_ADMIN_PASSWORD" \
		--admin_email="$WORDPRESS_ADMIN_EMAIL" \
		--skip-email
	
	log_info "WordPress のインストールが完了しました"
	
	# --------------------------------------------------------------------------
	# 追加ユーザーの作成
	# --------------------------------------------------------------------------
	
	log_info "一般ユーザーを作成中..."
	
	# WP-CLI を使って一般ユーザーを作成
	# role=author: 投稿者権限
	wp user create \
		"$WORDPRESS_USER" \
		"$WORDPRESS_USER_EMAIL" \
		--role=author \
		--user_pass="$WORDPRESS_USER_PASSWORD" \
		--allow-root \
		--path=/var/www/html
	
	log_info "一般ユーザーの作成が完了しました"
	
	# --------------------------------------------------------------------------
	# パーマリンク設定
	# --------------------------------------------------------------------------
	
	log_info "パーマリンク設定を変更中..."
	
	# パーマリンク構造を「投稿名」に設定
	wp rewrite structure '/%postname%/' --allow-root --path=/var/www/html
	
	log_info "パーマリンク設定が完了しました"
	
	# --------------------------------------------------------------------------
	# デフォルトコンテンツの削除（オプション）
	# --------------------------------------------------------------------------
	
	log_info "デフォルトコンテンツを削除中..."
	
	# デフォルトの投稿を削除
	wp post delete 1 --force --allow-root --path=/var/www/html 2>/dev/null || true
	
	# デフォルトのページを削除
	wp post delete 2 --force --allow-root --path=/var/www/html 2>/dev/null || true
	
	log_info "セットアップが完了しました"
else
	log_info "WordPress は既にインストールされています"
fi

# ---------------------------------------------------------------------------- #
# ファイルの所有権とパーミッションの設定
# ---------------------------------------------------------------------------- #

log_info "ファイルの所有権とパーミッションを設定中..."

# WordPress ディレクトリの所有者を www-data に変更
chown -R www-data:www-data /var/www/html

# ディレクトリのパーミッションを設定
find /var/www/html -type d -exec chmod 755 {} \;

# ファイルのパーミッションを設定
find /var/www/html -type f -exec chmod 644 {} \;

log_info "パーミッションの設定が完了しました"

# ---------------------------------------------------------------------------- #
# PHP-FPM の起動（フォアグラウンド）
# ---------------------------------------------------------------------------- #

log_info "PHP-FPM を起動しています..."

# PHP-FPM をフォアグラウンドで実行
# -F: フォアグラウンドモード
# -R: root ユーザーでの実行を許可（Docker コンテナ内では必要）
exec php-fpm7.4 -F -R
