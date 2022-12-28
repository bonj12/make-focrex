ALL = clean_build set_local start/containers start/setup_admin start/setup_webapp start/setup_member start/serve/dev/webapp start/serve/dev/front start/serve/dev/admin 8080 clear_logs

build_local: $(ALL)
.PHONY: $(ALL) bash/focrex-member artisan/focrex-webapp cache/clear/focrex-webapp

clean_build:
	sudo rm -rf focrex-local-env && \
    mkdir focrex-local-env && \
    cd focrex-local-env && \
	git clone git@bitbucket.org:glbbestinc/focrex-dev-docker.git
set_local:
	cd focrex-local-env/focrex-dev-docker && \
	git clone git@bitbucket.org:glbbestinc/focrex-member.git focrex-member && \
	git clone git@bitbucket.org:glbbestinc/focrex-admin.git focrex-admin && \
	git clone git@bitbucket.org:glbbestinc/focrex-webapp.git focrex-webapp && \
	git clone git@bitbucket.org:glbbestinc/focrextrade.git focrex-trade && \
	git clone git@bitbucket.org:glbbestinc/focrex-settlement.git focrex-settlement && \
	git clone git@bitbucket.org:glbbestinc/focrex-pusher.git focrex-pusher && \
	git clone git@bitbucket.org:glbbestinc/focrex-chart.git focrex-chart && \
	git clone git@bitbucket.org:glbbestinc/focrex-bot.git focrex-bot && \
	cd focrex-member/public && \
	git clone git@bitbucket.org:glbbestinc/tradingview_charting_library.git && \
	cd ~/focrex-local-env/focrex-dev-docker && \
	sed -i 's/COMPOSE_PROJECT_NAME=focrex-dev-docker/COMPOSE_PROJECT_NAME=focrex-local-env-linux/g' .env.example && \
	cp ~/focrex-local-env/focrex-dev-docker/.env.example ~/focrex-local-env/focrex-dev-docker/.env && \
	sed -i 's/php:8.1-fpm-alpine/php:8.0.2-fpm-alpine/g' ~/focrex-local-env/focrex-dev-docker/docker/dev/cryptos-staking/Dockerfile ~/focrex-local-env/focrex-dev-docker/docker/dev/focrex-bxfg/Dockerfile ~/focrex-local-env/focrex-dev-docker/docker/dev/focrex-admin/Dockerfile ~/focrex-local-env/focrex-dev-docker/docker/dev/focrex-webapp/Dockerfile && \
	sed -i 's/DB_CONNECTION=sqlite/#DB_CONNECTION=sqlite/g' focrex-admin/laravel/.env.example && \
	sed -i 's/#DB_CONNECTION=mysql/DB_CONNECTION=mysql/g' focrex-admin/laravel/.env.example && \
	sed -i 's/#DB_HOST=db/DB_HOST=db/g' focrex-admin/laravel/.env.example && \
	sed -i 's/#DB_PORT=3306/DB_PORT=3306/g' focrex-admin/laravel/.env.example && \
	sed -i 's/#DB_DATABASE=focrex/DB_DATABASE=focrex/g' focrex-admin/laravel/.env.example && \
	sed -i 's/#DB_USERNAME=develop/DB_USERNAME=develop/g' focrex-admin/laravel/.env.example && \
	sed -i 's/#DB_PASSWORD=secret/DB_PASSWORD=secret/g' focrex-admin/laravel/.env.example && \
	sed -i 's/#DB_READ_HOST=db/DB_READ_HOST=db/g' focrex-admin/laravel/.env.example && \
	cd ../ && \
	sudo chmod 777 -R ~/focrex-local-env/focrex-dev-docker/ && \
	sudo rm -rf ~/focrex-local-env/focrex-dev-docker/focrex-member/.env/ && \
	sed -i 's/https\:\/\/localhost\:8080\/api\/v1\/xxx/http\:\/\/localhost\:8082\/api\/v1/g' ~/focrex-local-env/focrex-dev-docker/focrex-member/.env.sample && \
	sed -i "6iVUE_APP_FOCREX_FRONT_URL='http://localhost:8080'" ~/focrex-local-env/focrex-dev-docker/focrex-member/.env.sample
8080:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker-compose exec -d focrex-member yarn serve:dev
clear_logs:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker-compose exec focrex-webapp rm storage/logs/laravel.log
	docker-compose exec focrex-admin rm storage/logs/laravel.log
	#docker-compose exec focrex-member rm storage/logs/laravel.log
start/setup_admin:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker-compose exec focrex-admin cp .env.example .env && \
	docker-compose exec focrex-admin apk add yarn composer npm && \
	docker-compose exec focrex-admin composer install && \
	docker-compose exec focrex-admin yarn && \
	docker-compose exec focrex-admin script/empty_sqlitedb.sh && \
	docker-compose exec focrex-admin php artisan key:generate && \
	docker-compose exec focrex-admin php artisan migrate:refresh --seed
	#docker exec focrex-admin php artisan migrate:fresh --seed
	#docker exec focrex-admin php artisan migrate --path=database/migrations/focrex_report/
start/setup_webapp:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker-compose exec focrex-webapp cp .env.example .env && \
	docker-compose exec focrex-webapp apk add composer yarn npm && \
	docker-compose exec focrex-webapp composer install && \
	docker-compose exec focrex-webapp yarn && \
	docker-compose exec focrex-webapp php artisan key:generate && \
	docker-compose exec focrex-webapp php artisan migrate:refresh --seed
start/setup_member:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker-compose exec focrex-member cp .env.sample .env && \
	docker-compose exec focrex-member yarn
start/trade/usdt:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker exec -d focrex-trade go run cmd/daemon/main.go -s btcusdt && \
	docker exec -d focrex-trade go run cmd/daemon/main.go -s ethusdt && \
	docker exec -d focrex-trade go run cmd/daemon/main.go -s btcjpy
start/settlement:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker exec -d focrex-settlement go run cmd/daemon/main.go
start/pusher:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker exec -d focrex-pusher go run cmd/main.go
start/containers:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker-compose -f docker-compose.yml -f docker-compose.backend.yml down && \
	docker-compose -f docker-compose.yml -f docker-compose.backend.yml up -d
start/serve/dev/front:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker-compose exec focrex-member yarn build:dev
start/serve/dev/webapp:
	cd ~/focrex-local-env/focrex-dev-docker/  && \
	docker exec -d focrex-webapp yarn dev
start/serve/dev/admin:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker-compose exec focrex-admin yarn dev && \
	docker exec -d focrex-admin php artisan serve && \
	docker-compose -f docker-compose.yml -f docker-compose.backend.yml stop && \
	docker-compose build --no-cache && \
	docker-compose up -d
down/containers:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker-compose -f docker-compose.yml -f docker-compose.backend.yml down

modernize/trade:
	cd ~/focrex-local-env/focrex-dev-docker/focrex-trade && \
	git fetch && \
	git checkout development && \
	git pull
modernize/settlement:
	cd ~/focrex-local-env/focrex-dev-docker/focrex-settlement && \
	git fetch && \
	git checkout development && \
	git pull
#focrex-member
bash/focrex-member:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker exec -it focrex-member bash
#make yarn/focrex-member args="yarnで実行したいコマンド"
yarn/focrex-member:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker exec focrex-member yarn ${args}

yarn/install/focrex-member:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker exec focrex-member yarn install

#focrex-webapp
artisan/focrex-webapp:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
	docker exec focrex-webapp php artisan ${args}

cache/clear/focrex-webapp:
	cd ~/focrex-local-env/focrex-dev-docker/ && \
    docker exec focrex-webapp php artisan cache:clear
