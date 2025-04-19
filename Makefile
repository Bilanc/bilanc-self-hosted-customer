up:
	docker-compose up --build

down:
	docker-compose down

d:
	docker-compose down

run:
	docker compose up --detach --build || docker-compose up --detach --build

r:
	docker compose up --detach --build || docker-compose up --detach --build

recompose: down up