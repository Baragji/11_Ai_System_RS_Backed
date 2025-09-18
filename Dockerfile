# syntax=docker/dockerfile:1.6
FROM node:20.11-bullseye-slim AS base
WORKDIR /usr/src/app
COPY package.json package-lock.json ./
RUN npm install --omit=dev

FROM node:20.11-bullseye-slim AS build
WORKDIR /usr/src/app
COPY package.json package-lock.json ./
RUN npm install
COPY apps ./apps
RUN npm run build

FROM node:20.11-bullseye-slim AS production
WORKDIR /usr/src/app
ENV NODE_ENV=production
COPY --from=base /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/apps/api/dist ./apps/api/dist
COPY apps/api/package.json ./apps/api/package.json
CMD ["node", "apps/api/dist/index.js"]
