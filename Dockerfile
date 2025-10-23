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

# Copy .gitmodules to know what submodules we need
COPY .gitmodules* ./

# Initialize git repository and add submodules
# We need to do this because Railway doesn't copy .git directory
RUN set -ex && \
    git init && \
    git config user.email "builder@railway.app" && \
    git config user.name "Railway Builder" && \
    # Add each submodule manually if .gitmodules exists
    if [ -f .gitmodules ]; then \
        # Clone typedb-web-common submodule
        git clone --depth 1 https://github.com/typedb/typedb-web-common.git dependencies/typedb-web-common || \
        git clone --depth 1 https://github.com/vaticle/typedb-web-common.git dependencies/typedb-web-common; \
    fi

# Copy the rest of the application
COPY . .

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
