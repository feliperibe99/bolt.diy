# Build stage
FROM node:20.18.0 AS builder

WORKDIR /app

# Copy dependency files
COPY package.json pnpm-lock.yaml ./

# Install pnpm
RUN npm install -g pnpm@9.14.4

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build application with increased memory
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN pnpm run build

# Runtime stage
FROM node:20.18.0-slim AS runtime

WORKDIR /app

# Install pnpm FIRST
RUN npm install -g pnpm@9.14.4

# Copy package files
COPY --from=builder /app/package.json /app/pnpm-lock.yaml ./

# Copy built application
COPY --from=builder /app/build ./build
COPY --from=builder /app/public ./public

# Install only production dependencies (after pnpm is installed)
RUN pnpm install --prod --frozen-lockfile --ignore-scripts

# Environment variables
ENV NODE_ENV=production
ENV PORT=5173

# Expose port
EXPOSE 5173

# Start command
CMD ["node", "./build/server/index.js"]
