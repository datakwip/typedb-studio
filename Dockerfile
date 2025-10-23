# Multi-stage Dockerfile for TypeDB Studio
# Stage 1: Build the application

FROM node:20-alpine AS builder

# Install required packages
RUN apk add --no-cache git

# Install pnpm
RUN npm install -g pnpm

# Set working directory
WORKDIR /app

# Copy everything including git files
COPY . .

# Initialize git submodules and build
RUN set -ex && \
    echo "Initializing git submodules..." && \
    git submodule update --init --recursive && \
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
