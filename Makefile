
# Docker Compose ファイルのパス
COMPOSE_FILE	= srcs/docker-compose.yml

# データボリュームのパス（ログイン名を実際の名前に置き換えてください）
DATA_PATH		= /home/hana/data

# Docker Compose コマンド
DOCKER_COMPOSE	= docker-compose -f $(COMPOSE_FILE)

# color code
RED				=	"\033[1;31m"
GREEN			= 	"\033[1;32m"
YELLOW			=	"\033[1;33m"
CYAN			=	"\033[1;36m"
WHITE			=	"\033[1;37m"
RESET			=	"\033[0m"

# デフォルトターゲット：すべてを構築して起動
all: create_dirs build up

# データディレクトリを作成（WordPress ファイルとデータベースデータ用）
create_dirs:
	@echo "データディレクトリを作成中..."
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@echo $(GREEN)"ディレクトリ作成完了"$(RESET)

# Docker イメージをビルド
build:
	@echo "Docker イメージをビルド中..."
	@$(DOCKER_COMPOSE) build
	@echo $(GREEN)"ビルド完了"$(RESET)

# コンテナをバックグラウンドで起動
up:
	@echo "コンテナを起動中..."
	@$(DOCKER_COMPOSE) up -d
	@echo $(GREEN)"コンテナ起動完了"$(RESET)

# コンテナを停止
down:
	@echo "コンテナを停止中..."
	@$(DOCKER_COMPOSE) down
	@echo $(GREEN)"コンテナ停止完了"$(RESET)

# コンテナを再起動
restart: down up

# コンテナとネットワークを削除
clean:
	@echo "コンテナ、ネットワーク、ボリュームをクリーンアップ中..."
	@$(DOCKER_COMPOSE) down -v
	@echo $(CYAN)"クリーンアップ完了"$(RESET)

# すべてを削除（イメージ、コンテナ、ボリューム、データ）
fclean: clean
	@echo "すべてのイメージとデータを削除中..."
	@docker system prune -af --volumes
	@sudo rm -rf $(DATA_PATH)/wordpress/*
	@sudo rm -rf $(DATA_PATH)/mariadb/*
	@echo $(RED)"完全削除完了"$(RESET)

# 完全に再構築
re: fclean all

# コンテナの状態を表示
status:
	@$(DOCKER_COMPOSE) ps

# コンテナのログを表示
logs:
	@$(DOCKER_COMPOSE) logs -f

# 再起動回数
count-restart:
	@echo "mariadb->   $$(docker inspect mariadb --format='RestartCount: {{.RestartCount}}')"
	@echo "nginx->     $$(docker inspect nginx --format='RestartCount: {{.RestartCount}}')"
	@echo "wordpress-> $$(docker inspect wordpress --format='RestartCount: {{.RestartCount}}')"

# 強制クラッシュ
kill-db:
	@echo $(RED)"pkill mariadb in myspl"$(RESET)
	@docker exec mariadb bash -c "apt-get update && apt-get install -y procps && pkill -9 mysql"

kill-ng:
	@echo $(RED)"pkill nginx in nginx"$(RESET)
	@docker exec nginx bash -c "apt-get update && apt-get install -y procps && pkill -9 nginx"

# キャッシュ削除
rm-cashes:
	@echo $(RED)"unused cashes remove"$(RESET)
	@docker image prune -f

# .PHONY 宣言：これらのターゲットはファイル名ではないことを明示
.PHONY: all create_dirs build up down restart clean fclean re status logs restart-count

