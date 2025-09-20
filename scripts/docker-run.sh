#!/bin/bash

echo "🐳 PowerGrid Network Docker Setup"
echo "=================================="
echo ""
echo "This script will build and run the PowerGrid Network in Docker containers."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available. Please ensure Docker with Compose plugin is installed."
    echo "   Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"
echo ""

# Build and run the containers
echo "🔨 Building PowerGrid Network Docker image..."
echo "This may take a few minutes on first run..."
echo ""

docker compose up --build

echo ""
echo "🎉 PowerGrid Network Docker setup completed!"
echo ""
echo "To run again: docker compose up"
echo "To rebuild: docker compose up --build"
echo "To stop: docker compose down"
echo "To clean up: docker compose down -v"