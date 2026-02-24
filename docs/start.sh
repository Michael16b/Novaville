#!/bin/bash
# Script de démarrage rapide de la documentation

set -e

function print_header() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        📚 Documentation Novaville - Démarrage rapide       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

function print_options() {
    echo "Choisissez la méthode de lancement :"
    echo ""
    echo "  [1] 🖥️  npm (développement local avec hot-reload)"
    echo "  [2] 🐳 Docker Compose (depuis docs/)"
    echo "  [3] 🐳 Docker Compose (depuis racine avec profile)"
    echo "  [4] 📖 Voir les guides complets"
    echo ""
}

function method_npm() {
    echo "✨ Démarrage avec npm..."
    echo ""
    cd docs
    echo "📦 Installation des dépendances..."
    npm install
    echo ""
    echo "🚀 Lancement du serveur..."
    echo ""
    echo "   La documentation sera accessible sur : http://localhost:3000"
    echo ""
    echo "   Langues disponibles :"
    echo "   - 🇫🇷 Français (défaut) : http://localhost:3000/"
    echo "   - 🇬🇧 Anglais : http://localhost:3000/en/"
    echo ""
    npm start
}

function method_docker_local() {
    echo "✨ Démarrage avec Docker (depuis docs/)..."
    echo ""
    cd docs
    echo "🐳 Démarrage du conteneur Docker..."
    docker-compose up -d
    echo ""
    echo "✅ Service démarré !"
    echo ""
    echo "   La documentation sera accessible sur : http://localhost:3000"
    echo ""
    echo "   Langues disponibles :"
    echo "   - 🇫🇷 Français (défaut) : http://localhost:3000/"
    echo "   - 🇬🇧 Anglais : http://localhost:3000/en/"
    echo ""
    echo "   Commandes utiles :"
    echo "   - Logs : docker-compose logs -f"
    echo "   - Arrêt : docker-compose down"
    echo "   - Rebuild : docker-compose build --no-cache"
    echo ""
}

function method_docker_root() {
    echo "✨ Démarrage avec Docker (depuis racine)..."
    echo ""
    echo "🐳 Démarrage avec le profile docs..."
    docker-compose --profile docs up -d
    echo ""
    echo "✅ Services démarrés !"
    echo ""
    echo "   La documentation sera accessible sur : http://localhost:3000"
    echo ""
    echo "   Services lancés :"
    echo "   - 📱 Frontend : http://localhost:80"
    echo "   - 🔧 Backend : http://localhost:8000"
    echo "   - 📚 Documentation : http://localhost:3000"
    echo ""
    echo "   Langues disponibles :"
    echo "   - 🇫🇷 Français (défaut) : http://localhost:3000/"
    echo "   - 🇬🇧 Anglais : http://localhost:3000/en/"
    echo ""
    echo "   Commandes utiles :"
    echo "   - Logs docs : docker-compose logs -f docs"
    echo "   - Arrêt : docker-compose down"
    echo "   - Arrêt docs seulement : docker-compose stop docs"
    echo ""
}

function show_guides() {
    echo "📖 Guides disponibles :"
    echo ""
    echo "  • DOCUMENTATION_GUIDE.md - Guide general de la documentation"
    echo "  • docs/README.md - README du dossier docs"
    echo "  • docs/DOCKER_GUIDE.md - Guide Docker complet"
    echo "  • docs/I18N_GUIDE.md - Guide des traductions"
    echo "  • DOCUMENTATION_STATUS.md - Statut et roadmap"
    echo "  • DOCKER_I18N_UPDATE.md - Résumé de cette mise à jour"
    echo ""
    echo "  Pour lire un guide, utilisez : cat [fichier.md]"
    echo ""
}

# Main script
print_header

if [ -z "$1" ]; then
    print_options
    read -p "Votre choix (1-4): " choice
else
    choice=$1
fi

case $choice in
    1)
        method_npm
        ;;
    2)
        method_docker_local
        ;;
    3)
        method_docker_root
        ;;
    4)
        show_guides
        ;;
    *)
        echo "❌ Choix invalide"
        exit 1
        ;;
esac
