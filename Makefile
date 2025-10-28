
# Docker Compose ファイルのパス
COMPOSE_FILE	= srcs/docker-compose.yml

# データボリュームのパス（ログイン名を実際の名前に置き換えてください）
DATA_PATH		= /home/hana/data

# Docker Compose コマンド
DOCKER_COMPOSE	= docker-compose -f $(COMPOSE_FILE)

# デフォルトターゲット：すべてを構築して起動
all: create_dirs build up

# データディレクトリを作成（WordPress ファイルとデータベースデータ用）
create_dirs:
	@echo "📁 データディレクトリを作成中..."
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@echo "✅ ディレクトリ作成完了"

# Docker イメージをビルド
build:
	@echo "🔨 Docker イメージをビルド中..."
	@$(DOCKER_COMPOSE) build
	@echo "✅ ビルド完了"

# コンテナをバックグラウンドで起動
up:
	@echo "🚀 コンテナを起動中..."
	@$(DOCKER_COMPOSE) up -d
	@echo "✅ コンテナ起動完了"

# コンテナを停止
down:
	@echo "🛑 コンテナを停止中..."
	@$(DOCKER_COMPOSE) down
	@echo "✅ コンテナ停止完了"

# コンテナを再起動
restart: down up

# コンテナとネットワークを削除
clean:
	@echo "🧹 コンテナ、ネットワーク、ボリュームをクリーンアップ中..."
	@$(DOCKER_COMPOSE) down -v
	@echo "✅ クリーンアップ完了"

# すべてを削除（イメージ、コンテナ、ボリューム、データ）
fclean: clean
	@echo "🗑️  すべてのイメージとデータを削除中..."
	@docker system prune -af
	@sudo rm -rf $(DATA_PATH)/wordpress/*
	@sudo rm -rf $(DATA_PATH)/mariadb/*
	@echo "✅ 完全削除完了"

# 完全に再構築
re: fclean all

# コンテナの状態を表示
status:
	@echo "📊 コンテナのステータス:"
	@$(DOCKER_COMPOSE) ps

# コンテナのログを表示
logs:
	@$(DOCKER_COMPOSE) logs -f

# .PHONY 宣言：これらのターゲットはファイル名ではないことを明示
.PHONY: all create_dirs build up down restart clean fclean re status logs

