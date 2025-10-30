#!/bin/bash
# ============================================================================ #
#                       NGINX セットアップスクリプト                             #
# ============================================================================ #
# SSL/TLS 証明書を生成し、NGINX を起動
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

# DOMAIN_NAME が設定されているか確認
if [ -z "$DOMAIN_NAME" ]; then
	log_warn "DOMAIN_NAME が設定されていません。デフォルト値を使用します"
	DOMAIN_NAME="localhost"
fi

log_info "ドメイン名: ${DOMAIN_NAME}"

# ---------------------------------------------------------------------------- #
# SSL/TLS 証明書の生成（初回起動時のみ）
# ---------------------------------------------------------------------------- #

# SSL ディレクトリの確認
if [ ! -d "/etc/nginx/ssl" ]; then
	log_info "SSL ディレクトリを作成中..."
	mkdir -p /etc/nginx/ssl
fi

# 証明書が既に存在するか確認
if [ -f "/etc/nginx/ssl/nginx.crt" ] && [ -f "/etc/nginx/ssl/nginx.key" ]; then
	log_info "SSL/TLS 証明書は既に存在します。生成をスキップします"
else
	log_info "SSL/TLS 証明書を生成中..."
	
	# デフォルト値の設定
	SSL_COUNTRY="${SSL_COUNTRY:-JP}"
	SSL_STATE="${SSL_STATE:-Tokyo}"
	SSL_CITY="${SSL_CITY:-Tokyo}"
	SSL_ORGANIZATION="${SSL_ORGANIZATION:-42Tokyo}"
	SSL_ORG_UNIT="${SSL_ORG_UNIT:-Student}"
	
	# 証明書情報を表示
	log_info "証明書情報:"
	log_info "  Country: ${SSL_COUNTRY}"
	log_info "  State: ${SSL_STATE}"
	log_info "  City: ${SSL_CITY}"
	log_info "  Organization: ${SSL_ORGANIZATION}"
	log_info "  Organizational Unit: ${SSL_ORG_UNIT}"
	log_info "  Common Name: ${DOMAIN_NAME}"
	
	# 自己署名証明書を生成
	# -x509: X.509 証明書を生成
	# -nodes: パスフレーズなし（no DES encryption）
	# -days 365: 有効期限 365 日
	# -newkey rsa:2048: 2048 ビットの RSA 鍵を生成
	# -keyout: 秘密鍵の出力先
	# -out: 証明書の出力先
	# -subj: 証明書のサブジェクト情報
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout /etc/nginx/ssl/nginx.key \
		-out /etc/nginx/ssl/nginx.crt \
		-subj "/C=${SSL_COUNTRY}/ST=${SSL_STATE}/L=${SSL_CITY}/O=${SSL_ORGANIZATION}/OU=${SSL_ORG_UNIT}/CN=${DOMAIN_NAME}"
	
	# 証明書ファイルのパーミッションを設定
	chmod 644 /etc/nginx/ssl/nginx.crt
	chmod 600 /etc/nginx/ssl/nginx.key
	
	log_info "SSL/TLS 証明書の生成が完了しました"
fi

# ---------------------------------------------------------------------------- #
# NGINX 設定ファイルの検証
# ---------------------------------------------------------------------------- #

log_info "NGINX 設定ファイルを検証中..."

# NGINX の設定ファイルをテスト
if nginx -t 2>&1 | grep -q "successful"; then
	log_info "NGINX 設定ファイルは正常です"
else
	log_error "NGINX 設定ファイルにエラーがあります"
	nginx -t
	exit 1
fi

# ---------------------------------------------------------------------------- #
# NGINX の起動（フォアグラウンド）
# ---------------------------------------------------------------------------- #

log_info "NGINX を起動しています..."

# NGINX をフォアグラウンドで実行
# daemon off: バックグラウンドではなくフォアグラウンドで実行（Docker 要件）
exec nginx -g "daemon off;"

