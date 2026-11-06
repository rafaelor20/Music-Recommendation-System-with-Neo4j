# Load environment variables from .env if present
-include .env
export

NEO4J_USER ?= neo4j
NEO4J_PASSWORD ?= music_graph_pass
NEO4J_HTTP_PORT ?= 7474
NEO4J_BOLT_PORT ?= 7687

.PHONY: help up down logs shell constraints import queries basic business recommendations showcase reset

help:
	@echo "Available commands:"
	@echo "  make up              - Start Neo4j container and auto-import dataset"
	@echo "  make down            - Stop and remove Neo4j container (preserves volumes)"
	@echo "  make logs            - Follow Neo4j container logs"
	@echo "  make shell           - Open an interactive cypher-shell session"
	@echo "  make constraints     - Execute cypher/00_constraints.cypher"
	@echo "  make import          - Execute cypher/01_import_data.cypher"
	@echo "  make queries         - Show instructions for running queries in Neo4j Browser / CLI"
	@echo "  make basic           - Run cypher/02_basic_queries.cypher in terminal"
	@echo "  make business        - Run cypher/03_business_queries.cypher in terminal"
	@echo "  make recommendations - Run cypher/04_recommendations.cypher in terminal"
	@echo "  make showcase        - Run cypher/05_browser_showcase_queries.cypher in terminal"
	@echo "  make reset           - [DESTRUCTIVE] Wipe persisted volumes, recreate container, and re-import data"

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f neo4j

shell:
	docker compose exec neo4j cypher-shell -u "$(NEO4J_USER)" -p "$(NEO4J_PASSWORD)"

constraints:
	docker compose exec -T neo4j cypher-shell -u "$(NEO4J_USER)" -p "$(NEO4J_PASSWORD)" -f /cypher/00_constraints.cypher

import:
	docker compose exec -T neo4j cypher-shell -u "$(NEO4J_USER)" -p "$(NEO4J_PASSWORD)" -f /cypher/01_import_data.cypher

queries:
	@echo "================================================================================"
	@echo "Neo4j Browser is available at: http://localhost:$(NEO4J_HTTP_PORT)"
	@echo "Bolt URI:                      bolt://localhost:$(NEO4J_BOLT_PORT)"
	@echo "Username:                      $(NEO4J_USER)"
	@echo "================================================================================"
	@echo ""
	@echo "How to run the project queries in Neo4j Browser:"
	@echo "  1. Open http://localhost:$(NEO4J_HTTP_PORT) in your web browser and sign in."
	@echo "  2. For parameterized queries, first set the target user in the Browser prompt:"
	@echo "       :param userId => 'u1'"
	@echo "       :param otherUserId => 'u2'"
	@echo "  3. Copy and paste queries from:"
	@echo "       - cypher/05_browser_showcase_queries.cypher (12 self-contained visual & tabular showcase queries)"
	@echo "       - cypher/02_basic_queries.cypher            (Basic exploration queries)"
	@echo "       - cypher/03_business_queries.cypher         (Analytical & similarity queries)"
	@echo "       - cypher/04_recommendations.cypher          (3 Recommendation strategies)"
	@echo ""
	@echo "To execute query files directly via Make:"
	@echo "  make basic"
	@echo "  make business"
	@echo "  make recommendations"
	@echo "  make showcase"
	@echo ""
	@echo "Or directly via docker compose:"
	@echo "  docker compose exec -T neo4j cypher-shell -u $(NEO4J_USER) -p $(NEO4J_PASSWORD) -P \"userId => 'u1'\" -f /cypher/02_basic_queries.cypher"
	@echo "  docker compose exec -T neo4j cypher-shell -u $(NEO4J_USER) -p $(NEO4J_PASSWORD) -P \"userId => 'u1'\" -P \"otherUserId => 'u2'\" -f /cypher/03_business_queries.cypher"
	@echo "  docker compose exec -T neo4j cypher-shell -u $(NEO4J_USER) -p $(NEO4J_PASSWORD) -P \"userId => 'u1'\" -f /cypher/04_recommendations.cypher"
	@echo "  docker compose exec -T neo4j cypher-shell -u $(NEO4J_USER) -p $(NEO4J_PASSWORD) -f /cypher/05_browser_showcase_queries.cypher"

basic:
	docker compose exec -T neo4j cypher-shell -u "$(NEO4J_USER)" -p "$(NEO4J_PASSWORD)" -P "userId => 'u1'" -f /cypher/02_basic_queries.cypher

business:
	docker compose exec -T neo4j cypher-shell -u "$(NEO4J_USER)" -p "$(NEO4J_PASSWORD)" -P "userId => 'u1'" -P "otherUserId => 'u2'" -f /cypher/03_business_queries.cypher

recommendations:
	docker compose exec -T neo4j cypher-shell -u "$(NEO4J_USER)" -p "$(NEO4J_PASSWORD)" -P "userId => 'u1'" -f /cypher/04_recommendations.cypher

showcase:
	docker compose exec -T neo4j cypher-shell -u "$(NEO4J_USER)" -p "$(NEO4J_PASSWORD)" -f /cypher/05_browser_showcase_queries.cypher

# DESTRUCTIVE COMMAND: Permanently removes persisted Neo4j database and log volumes,
# then recreates the environment (neo4j-init automatically applies constraints + import).
reset:
	@echo "[WARNING] Destructive operation: removing Neo4j container and persisted volumes..."
	docker compose down -v
	docker compose up -d
	@echo "Waiting for neo4j-init to finish seeding..."
	docker compose logs -f neo4j-init
	@echo "Environment successfully reset and seeded!"
