build:
	docker-compose -f docker-compose.yml build

up: build
	docker-compose -f docker-compose.yml up -d

down:
	docker-compose -f docker-compose.yml down

fclean: down
	docker volume rm inception_db_data inception_wordpress_files || true
	docker network rm inception_wp_network || true
	docker system prune -f

re: fclean up

.PHONY: build up down fclean re
