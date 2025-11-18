.PHONY: help up down restart logs build clean ps fix frontend backend

# Couleurs pour l'affichage
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m # No Color

help: ## Affiche cette aide
	@echo "$(GREEN)Commandes disponibles pour Novaville:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

up: ## Lance toute l'application (backend + frontend)
	@echo "$(GREEN)🚀 Lancement de l'application Novaville...$(NC)"
	docker compose up -d
	@echo "$(GREEN)✅ Application démarrée!$(NC)"
	@echo "  Frontend: http://localhost"
	@echo "  Backend:  http://localhost:8000"

down: ## Arrête toute l'application
	@echo "$(YELLOW)🛑 Arrêt de l'application...$(NC)"
	docker compose down
	@echo "$(GREEN)✅ Application arrêtée$(NC)"

restart: down up ## Redémarre toute l'application

logs: ## Affiche les logs de tous les conteneurs
	docker compose logs -f

logs-backend: ## Affiche les logs du backend uniquement
	docker compose logs -f backend

logs-frontend: ## Affiche les logs du frontend uniquement
	docker compose logs -f frontend

build: ## Build les images Docker sans cache
	@echo "$(GREEN)🔨 Build des images Docker...$(NC)"
	docker compose build --no-cache

build-backend: ## Build uniquement le backend
	@echo "$(GREEN)🔨 Build du backend...$(NC)"
	docker compose build --no-cache backend

build-frontend: ## Build uniquement le frontend
	@echo "$(GREEN)🔨 Build du frontend...$(NC)"
	docker compose build --no-cache frontend

clean: ## Nettoie les conteneurs, volumes et images
	@echo "$(YELLOW)🧹 Nettoyage...$(NC)"
	docker compose down -v --remove-orphans
	docker system prune -f
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

ps: ## Affiche l'état des conteneurs
	docker compose ps

fix: ## Corrige et formate le code (frontend + backend)
	@echo "$(GREEN)🔧 Formatage du code...$(NC)"
	@$(MAKE) -C frontend format fix
	@$(MAKE) -C backend format fix
	@echo "$(GREEN)✅ Code formaté et corrigé!$(NC)"

frontend: ## Ouvre le Makefile du frontend (usage: make frontend <commande>)
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "$(GREEN)📱 Commandes Frontend disponibles:$(NC)"; \
		$(MAKE) -C frontend help; \
	else \
		$(MAKE) -C frontend $(filter-out $@,$(MAKECMDGOALS)); \
	fi

backend: ## Ouvre le Makefile du backend (usage: make backend <commande>)
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "$(GREEN)🐍 Commandes Backend disponibles:$(NC)"; \
		$(MAKE) -C backend help; \
	else \
		$(MAKE) -C backend $(filter-out $@,$(MAKECMDGOALS)); \
	fi

# Capture les arguments pour les sous-commandes
%:
	@:
