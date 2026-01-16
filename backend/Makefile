.PHONY: help format fix lint test clean migrate makemigrations shell runserver createsuperuser collectstatic

# Couleurs
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m

help: ## Affiche cette aide
	@echo "$(GREEN)Commandes Django disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

format: ## Formate le code Python avec black et isort
	@echo "$(GREEN)🔧 Formatage du code Python...$(NC)"
	@if command -v black >/dev/null 2>&1; then \
		black . --exclude='/(\.git|\.venv|venv|migrations|\.eggs)/' || true; \
	else \
		echo "$(YELLOW)⚠️  black non installé. Installation: pip install black$(NC)"; \
	fi
	@if command -v isort >/dev/null 2>&1; then \
		isort . --skip-glob='*/migrations/*' --skip-glob='*/.venv/*' || true; \
	else \
		echo "$(YELLOW)⚠️  isort non installé. Installation: pip install isort$(NC)"; \
	fi
	@echo "$(GREEN)✅ Code formaté$(NC)"

fix: format ## Applique les corrections automatiques
	@echo "$(GREEN)🔧 Corrections automatiques...$(NC)"
	@if command -v autoflake >/dev/null 2>&1; then \
		autoflake --in-place --remove-all-unused-imports --remove-unused-variables --recursive . --exclude='.venv,venv,migrations' || true; \
	fi
	@echo "$(GREEN)✅ Corrections appliquées$(NC)"

lint: ## Vérifie le code avec flake8 et pylint
	@echo "$(GREEN)🔍 Analyse du code Python...$(NC)"
	@if command -v flake8 >/dev/null 2>&1; then \
		flake8 . --exclude=migrations,venv,.venv,__pycache__ --max-line-length=120 || true; \
	else \
		echo "$(YELLOW)⚠️  flake8 non installé. Installation: pip install flake8$(NC)"; \
	fi
	@if command -v pylint >/dev/null 2>&1; then \
		pylint **/*.py --ignore=migrations,venv,.venv || true; \
	fi

test: ## Lance les tests Django
	@echo "$(GREEN)🧪 Lancement des tests...$(NC)"
	@if [ -f "manage.py" ]; then \
		python manage.py test; \
	else \
		echo "$(YELLOW)⚠️  manage.py non trouvé$(NC)"; \
	fi

test-coverage: ## Lance les tests avec couverture
	@echo "$(GREEN)🧪 Tests avec couverture...$(NC)"
	@if command -v coverage >/dev/null 2>&1; then \
		coverage run --source='.' manage.py test; \
		coverage report; \
		coverage html; \
		echo "$(GREEN)Rapport HTML généré dans htmlcov/$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  coverage non installé. Installation: pip install coverage$(NC)"; \
	fi

clean: ## Nettoie les fichiers Python compilés
	@echo "$(YELLOW)🧹 Nettoyage...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache htmlcov .coverage
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

migrate: ## Applique les migrations
	@echo "$(GREEN)🗄️  Application des migrations...$(NC)"
	@if [ -f "manage.py" ]; then \
		python manage.py migrate; \
	else \
		echo "$(YELLOW)⚠️  manage.py non trouvé$(NC)"; \
	fi

makemigrations: ## Crée de nouvelles migrations
	@echo "$(GREEN)🗄️  Création des migrations...$(NC)"
	@if [ -f "manage.py" ]; then \
		python manage.py makemigrations; \
	else \
		echo "$(YELLOW)⚠️  manage.py non trouvé$(NC)"; \
	fi

shell: ## Ouvre le shell Django
	@if [ -f "manage.py" ]; then \
		python manage.py shell; \
	else \
		echo "$(YELLOW)⚠️  manage.py non trouvé$(NC)"; \
	fi

dbshell: ## Ouvre le shell de la base de données
	@if [ -f "manage.py" ]; then \
		python manage.py dbshell; \
	else \
		echo "$(YELLOW)⚠️  manage.py non trouvé$(NC)"; \
	fi

runserver: ## Lance le serveur de développement
	@echo "$(GREEN)🚀 Lancement du serveur Django...$(NC)"
	@if [ -f "manage.py" ]; then \
		python manage.py runserver 0.0.0.0:8000; \
	else \
		echo "$(YELLOW)⚠️  manage.py non trouvé$(NC)"; \
	fi

createsuperuser: ## Crée un superuser
	@if [ -f "manage.py" ]; then \
		python manage.py createsuperuser; \
	else \
		echo "$(YELLOW)⚠️  manage.py non trouvé$(NC)"; \
	fi

collectstatic: ## Collecte les fichiers statiques
	@echo "$(GREEN)📦 Collection des fichiers statiques...$(NC)"
	@if [ -f "manage.py" ]; then \
		python manage.py collectstatic --noinput; \
	else \
		echo "$(YELLOW)⚠️  manage.py non trouvé$(NC)"; \
	fi

check: ## Vérifie le projet Django
	@if [ -f "manage.py" ]; then \
		python manage.py check; \
	else \
		echo "$(YELLOW)⚠️  manage.py non trouvé$(NC)"; \
	fi

showmigrations: ## Affiche l'état des migrations
	@if [ -f "manage.py" ]; then \
		python manage.py showmigrations; \
	else \
		echo "$(YELLOW)⚠️  manage.py non trouvé$(NC)"; \
	fi

install: ## Installe les dépendances
	@echo "$(GREEN)📦 Installation des dépendances...$(NC)"
	@if [ -f "requirements.txt" ]; then \
		pip install -r requirements.txt; \
	elif [ -f "pyproject.toml" ]; then \
		pip install .; \
	else \
		echo "$(YELLOW)⚠️  Aucun fichier de dépendances trouvé$(NC)"; \
	fi

install-dev: ## Installe les dépendances de développement
	@echo "$(GREEN)📦 Installation des outils de développement...$(NC)"
	pip install black isort flake8 pylint autoflake coverage pytest pytest-django

freeze: ## Génère requirements.txt
	pip freeze > requirements.txt
	@echo "$(GREEN)✅ requirements.txt généré$(NC)"

all: format lint test ## Exécute format, lint et test
	@echo "$(GREEN)✅ Toutes les vérifications passées!$(NC)"
