# Multi-stage Dockerfile for TypeDB Studio
# Stage 1: Build the application with git submodules initialized

FROM node:20-alpine AS builder

# Install git for submodule initialization
RUN apk add --no-cache git

# Install pnpm
RUN npm install -g pnpm

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# Initialize git (required for submodules)
COPY .git .git
COPY .gitmodules .gitmodules

# Initialize and update submodules
RUN git submodule update --init --recursive

# Copy the submodule content
COPY typedb-web ./typedb-web

# Install dependencies (this will include the typedb-web/common package)
RUN pnpm install --frozen-lockfile

# Copy application source
COPY . .

# Build the application
RUN pnpm run build:prod

# Stage 2: Serve the static files
FROM node:20-alpine

# Install serve for static file serving
RUN npm install -g serve

WORKDIR /app

# Copy built files from builder
COPY --from=builder /app/dist/typedb-studio/browser ./dist

# Expose port (Railway sets PORT env var)
EXPOSE 3000

# Start command
CMD ["serve", "-s", "dist", "-l", "3000"]
