#!/bin/sh
set -e

echo "Initializing git submodules..."
git submodule update --init --recursive

echo "Installing dependencies..."
pnpm install --frozen-lockfile

echo "Building application..."
pnpm run build:prod

echo "Build complete!"
