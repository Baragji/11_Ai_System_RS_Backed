# syntax=docker/dockerfile:1.6

# Build stage: install deps (incl. dev), build, then prune to production-only
FROM node:20.11-bullseye-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY apps ./apps
# Build the API application
RUN npm run build
# Remove devDependencies to keep only production deps for runtime
RUN npm prune --omit=dev

# Runtime stage: distroless Node.js (smaller, fewer GPL/LGPL-licensed OS packages)
FROM gcr.io/distroless/nodejs20-debian12 AS runtime
WORKDIR /app
ENV NODE_ENV=production
# Copy production dependencies and built artifacts
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/apps/api/dist ./apps/api/dist
COPY apps/api/package.json ./apps/api/package.json
# Distroless node image has entrypoint set to `node`. Provide only the script path.
CMD ["apps/api/dist/index.js"]
