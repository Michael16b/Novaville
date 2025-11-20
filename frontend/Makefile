.PHONY: help format fix lint test clean analyze build-web build-apk build-ios run dev pub-get

# Couleurs
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m

help: ## Affiche cette aide
	@echo "$(GREEN)Commandes Flutter disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

format: ## Formate le code Dart (via Docker)
	@echo "$(GREEN)🔧 Formatage du code Dart (via Docker)...$(NC)"
	@docker run --rm -v "$(CURDIR):/app" -w /app ghcr.io/cirruslabs/flutter:stable sh -c "flutter pub get && dart format ."
	@echo "$(GREEN)✅ Code formaté$(NC)"

fix: ## Applique les corrections automatiques (via Docker)
	@echo "$(GREEN)🔧 Application des corrections Dart (via Docker)...$(NC)"
	dart fix --apply && dart format .
	@echo "$(GREEN)✅ Corrections appliquées$(NC)"

lint: analyze ## Alias pour analyze

analyze: ## Analyse le code Flutter
	@echo "$(GREEN)🔍 Analyse du code Flutter...$(NC)"
	flutter analyze

test: ## Lance les tests Flutter
	@echo "$(GREEN)🧪 Lancement des tests...$(NC)"
	flutter test

test-coverage: ## Lance les tests avec couverture
	@echo "$(GREEN)🧪 Tests avec couverture...$(NC)"
	flutter test --coverage
	@if command -v lcov >/dev/null 2>&1; then \
		lcov --summary coverage/lcov.info; \
	fi

clean: ## Nettoie les fichiers build
	@echo "$(YELLOW)🧹 Nettoyage...$(NC)"
	flutter clean
	rm -rf .dart_tool build
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

pub-get: ## Récupère les dépendances
	@echo "$(GREEN)📦 Récupération des dépendances...$(NC)"
	flutter pub get

pub-upgrade: ## Met à jour les dépendances
	@echo "$(GREEN)📦 Mise à jour des dépendances...$(NC)"
	flutter pub upgrade

pub-outdated: ## Vérifie les dépendances obsolètes
	flutter pub outdated

build-web: ## Build pour le web
	@echo "$(GREEN)🌐 Build Web...$(NC)"
	flutter build web --release

build-apk: ## Build APK Android
	@echo "$(GREEN)🤖 Build APK Android...$(NC)"
	flutter build apk --release

build-ios: ## Build iOS
	@echo "$(GREEN)🍎 Build iOS...$(NC)"
	flutter build ios --release

run: ## Lance l'application en mode debug
	@echo "$(GREEN)🚀 Lancement de l'application...$(NC)"
	flutter run

run-web: ## Lance l'application web
	@echo "$(GREEN)🌐 Lancement web...$(NC)"
	flutter run -d chrome

dev: run ## Alias pour run

watch: ## Mode watch pour les tests
	@echo "$(GREEN)👀 Mode watch activé...$(NC)"
	flutter test --watch

generate: ## Génère le code (build_runner, freezed, etc.)
	@echo "$(GREEN)⚙️  Génération du code...$(NC)"
	flutter pub run build_runner build --delete-conflicting-outputs

doctor: ## Vérifie l'installation Flutter
	flutter doctor -v

upgrade-flutter: ## Met à jour Flutter
	flutter upgrade

bloc-create: ## Crée un nouveau BLoC (usage: make bloc-create name=MyFeature)
	@if [ -z "$(name)" ]; then \
		echo "$(YELLOW)Usage: make bloc-create name=MyFeature$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)📦 Création du BLoC $(name)...$(NC)"
	@mkdir -p lib/blocs/$(shell echo $(name) | tr A-Z a-z)
	@echo "// TODO: Implement $(name) BLoC" > lib/blocs/$(shell echo $(name) | tr A-Z a-z)/$(shell echo $(name) | tr A-Z a-z)_bloc.dart
	@echo "// TODO: Implement $(name) Events" > lib/blocs/$(shell echo $(name) | tr A-Z a-z)/$(shell echo $(name) | tr A-Z a-z)_event.dart
	@echo "// TODO: Implement $(name) State" > lib/blocs/$(shell echo $(name) | tr A-Z a-z)/$(shell echo $(name) | tr A-Z a-z)_state.dart
	@echo "$(GREEN)✅ BLoC $(name) créé dans lib/blocs/$(shell echo $(name) | tr A-Z a-z)/$(NC)"

all: format fix analyze test ## Exécute format, fix, analyze et test
	@echo "$(GREEN)✅ Toutes les vérifications passées!$(NC)"
