#!/bin/bash
# -----------------------------------------------------------------------------
# File: run_openlane_docker.sh
# Project: SimpleARM - A Simplified ARM Cortex-M0 Processor Core
# Purpose: Run OpenLane/LibreLane hardening using Docker
# Usage: ./scripts/run_openlane_docker.sh
# -----------------------------------------------------------------------------

set -e

echo "=========================================="
echo "SimpleARM OpenLane Docker Flow"
echo "=========================================="

# Change to project directory
cd "$(dirname "$0")/.."
PROJECT_DIR=$(pwd)

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    exit 1
fi

# Check for the Docker image
OPENLANE_IMAGE="ghcr.io/librelane/librelane:2.4.2"
if ! docker images -q "$OPENLANE_IMAGE" | grep -q .; then
    echo "Pulling LibreLane Docker image..."
    docker pull "$OPENLANE_IMAGE"
fi

echo "Using image: $OPENLANE_IMAGE"
echo "Project directory: $PROJECT_DIR"

# Create runs directory if it doesn't exist (it's gitignored so that's fine)
mkdir -p runs

# Run OpenLane in Docker
echo "Starting LibreLane flow..."
docker run --rm \
    -v "$PROJECT_DIR:/work" \
    -v "$HOME/.volare:/home/openroad/.volare" \
    -w /work \
    "$OPENLANE_IMAGE" \
    librelane \
    --pdk sky130A \
    --pdk-root /home/openroad/.volare \
    --skip Verilator.Lint \
    config.json

echo "=========================================="
echo "OpenLane flow complete!"
echo "Check runs/ directory for outputs"
echo "=========================================="
