#!/bin/bash

IMAGE_NAME="packet-harvester"

print_help() {
    echo "📦 PacketHarvester - Docker Setup"
    echo
    echo "Usage:"
    echo "  ./setup.sh [command]"
    echo
    echo "Commands:"
    echo "  build         Build the Docker image"
    echo "  clean         Remove the Docker image"
    echo "  help, -h      Show this help message"
    echo
}

case "$1" in
    build)
        echo "🔍 Checking environment..."
        if ! command -v docker &> /dev/null; then
            echo "❌ Docker is not installed."
            exit 1
        fi

        if [[ ! -f "docker/Dockerfile" ]]; then
            echo "❌ docker/Dockerfile not found. Are you in the correct directory?"
            exit 1
        fi

        echo "🔧 Building Docker image '$IMAGE_NAME'..."
        docker build -t "$IMAGE_NAME" ./docker

        if [[ $? -eq 0 ]]; then
            echo "✅ Build successful!"
        else
            echo "❌ Build failed."
            exit 1
        fi
        ;;
    
    clean)
        echo "🧹 Removing Docker image '$IMAGE_NAME'..."
        docker rmi "$IMAGE_NAME"
        ;;
    
    help|-h|--help|"")
        print_help
        ;;
    
    *)
        echo "❌ Unknown command: $1"
        print_help
        exit 1
        ;;
esac
