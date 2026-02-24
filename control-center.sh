#!/bin/bash

# 🎊 DOCUMENTATION CONTROL CENTER
# Lance votre documentation Novaville en quelques secondes
# Usage: bash control-center.sh

set -e

clear

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          📚 NOVAVILLE DOCUMENTATION LAUNCHER 📚                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "✨ Docker ✨ Production-ready ✨"
echo ""

# Check requirements
check_requirements() {
    echo "🔍 Checking requirements..."
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed"
        exit 1
    fi
    echo "✅ Docker found"
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker-compose is not installed"
        exit 1
    fi
    echo "✅ Docker-compose found"
    echo ""
}

# Main menu
show_menu() {
    echo "┌────────────────────────────────────────────────────────────────┐"
    echo "│ What would you like to do?                                     │"
    echo "└────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  1️⃣  🚀 Start Documentation"
    echo "  2️⃣  🛑 Stop"
    echo "  3️⃣  📊 View Logs"
    echo "  4️⃣  🔄 Restart"
    echo "  5️⃣  🧹 Clean (remove containers & images)"
    echo ""
    echo "  6️⃣  📚 Guides & Documentation"
    echo "  7️⃣  ℹ️  System Info"
    echo ""
    echo "  0️⃣  ❌ Exit"
    echo ""
}

# Option 1: Start
start_docs() {
    echo "🚀 Starting documentation..."
    cd docs
    docker-compose up -d
    cd ..
    echo ""
    echo "✅ Documentation started!"
    echo ""
    echo "📍 Access:"
    echo "   🌐 English  : http://localhost:3000"
    echo "   🇫🇷 French   : http://localhost:3000/fr"
    echo ""
    echo "   API         : http://localhost:8000"
    echo ""
    sleep 3
}

# Option 2: Stop
stop_docs() {
    echo "🛑 Stopping documentation..."
    cd docs
    docker-compose down
    cd ..
    echo "✅ Services stopped"
    sleep 2
}

# Option 3: Logs
show_logs() {
    echo "📊 Live logs (Ctrl+C to exit)"
    cd docs
    docker-compose logs -f
    cd ..
}

# Option 4: Restart
restart_docs() {
    echo "🔄 Restarting..."
    cd docs
    docker-compose restart
    cd ..
    echo "✅ Services restarted"
    sleep 2
}

# Option 5: Clean
cleanup_docs() {
    echo "🧹 Full cleanup..."
    read -p "⚠️  Are you sure? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd docs
        docker-compose down -v
        docker rmi novaville-docs || true
        cd ..
        echo "✅ Cleanup done"
    else
        echo "❌ Cancelled"
    fi
    sleep 2
}

# Option 6: Guides
show_guides() {
    clear
    echo "┌────────────────────────────────────────────────────────────────┐"
    echo "│ 📚 GUIDES & DOCUMENTATION                                      │"
    echo "└────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  1️⃣  🚀 QUICK START (How to launch)"
    echo "     → File: QUICK_START.md"
    echo ""
    echo "  2️⃣  🐳 DOCKER GUIDE (All about Docker)"
    echo "     → File: docs/DOCKER_GUIDE.md"
    echo ""
    echo "  3️⃣  🌍 i18N GUIDE (Multiple languages)"
    echo "     → File: docs/I18N_GUIDE.md"
    echo ""
    echo "  4️⃣  📖 DOCUMENTATION GUIDE (General guide)"
    echo "     → File: DOCUMENTATION_GUIDE.md"
    echo ""
    echo "  0️⃣  Back to menu"
    echo ""
    read -p "Choose a guide (0-4): " choice
    
    case $choice in
        1)
            if [ -f "QUICK_START.md" ]; then
                less QUICK_START.md
            else
                echo "❌ File not found"
            fi
            ;;
        2)
            if [ -f "docs/DOCKER_GUIDE.md" ]; then
                less docs/DOCKER_GUIDE.md
            else
                echo "❌ File not found"
            fi
            ;;
        3)
            if [ -f "docs/I18N_GUIDE.md" ]; then
                less docs/I18N_GUIDE.md
            else
                echo "❌ File not found"
            fi
            ;;
        4)
            if [ -f "DOCUMENTATION_GUIDE.md" ]; then
                less DOCUMENTATION_GUIDE.md
            else
                echo "❌ File not found"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo "❌ Invalid choice"
            ;;
    esac
}

# Option 7: System info
show_system_info() {
    clear
    echo "┌────────────────────────────────────────────────────────────────┐"
    echo "│ ℹ️  SYSTEM & INFO                                              │"
    echo "└────────────────────────────────────────────────────────────────┘"
    echo ""
    
    echo "🐳 Docker info:"
    docker --version
    echo ""
    
    echo "🐳 Docker-compose info:"
    docker-compose --version
    echo ""
    
    echo "📦 Current services:"
    cd docs
    docker-compose ps
    cd ..
    echo ""
    
    echo "💾 Disk space (containers):"
    docker ps -s --format "table {{.ID}}\t{{.Image}}\t{{.Size}}"
    echo ""
    
    echo "📍 Ports in use:"
    echo "   3000 (Docs)      $(netstat -tuln 2>/dev/null | grep 3000 || echo '- Not found')"
    echo "   8000 (API)       $(netstat -tuln 2>/dev/null | grep 8000 || echo '- Not found')"
    echo ""
    
    echo "✅ Docker Configuration:"
    echo "   - docs/Dockerfile       ✅"
    echo "   - docs/docker-compose.yml ✅"
    echo "   - docs/nginx.conf       ✅"
    echo "   - docs/.dockerignore    ✅"
    echo ""
    
    echo "🌍 Language Support:"
    echo "   - English (EN)          ✅ Default"
    echo "   - French (FR)           ✅ Available"
    echo ""
    
    read -p "Press ENTER to continue..."
}

# Main loop
check_requirements

while true; do
    show_menu
    read -p "Your choice (0-7): " choice
    
    case $choice in
        1) start_docs ;;
        2) stop_docs ;;
        3) show_logs ;;
        4) restart_docs ;;
        5) cleanup_docs ;;
        6) show_guides ;;
        7) show_system_info ;;
        0) 
            echo ""
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice, try again"
            sleep 1
            ;;
    esac
done
