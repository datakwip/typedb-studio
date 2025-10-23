# Multi-stage Dockerfile for TypeDB Studio
# Stage 1: Build the application

FROM node:20-alpine AS builder

# Install required packages
RUN apk add --no-cache git

# Install pnpm
RUN npm install -g pnpm

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package.json pnpm-lock.yaml .npmrc* ./

# Initialize the typedb-web submodule directory
# This is needed because Railway doesn't copy .git directory
RUN mkdir -p typedb-web

# Copy the rest of the application
COPY . .

# Clone the submodule (since Railway doesn't include .git)
RUN set -ex && \
    echo "Cloning typedb-web submodule..." && \
    rm -rf typedb-web && \
    git clone --depth 1 https://github.com/typedb/typedb-web.git typedb-web

# Install dependencies and build
RUN set -ex && \
    echo "Installing dependencies..." && \
    pnpm install --frozen-lockfile && \
    echo "Building application..." && \
    pnpm run build:prod && \
    echo "Build complete!"

# Stage 2: Serve the static files
FROM node:20-alpine

# Install serve for static file serving
RUN npm install -g serve

WORKDIR /app

# Copy built files from builder
COPY --from=builder /app/dist/typedb-studio/browser ./dist

# Expose port (Railway sets PORT env var)
EXPOSE 3000

# Start command - use Railway's PORT env var
CMD sh -c "serve -s dist -l ${PORT:-3000}"
