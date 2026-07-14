# ---- Stage 1: Build Frontend ----
FROM node:22-alpine AS frontend-builder
WORKDIR /app
COPY package.json package-lock.json ./
COPY frontend/package.json frontend/
RUN npm install
COPY frontend/ frontend/
RUN npm run build --workspace frontend

# ---- Stage 2: Build Backend ----
FROM node:22-alpine AS backend-builder
WORKDIR /app
COPY package.json package-lock.json ./
COPY backend/package.json backend/
RUN npm install
COPY backend/ backend/
RUN npm run build --workspace backend

# ---- Stage 3: Production Runtime ----
FROM node:22-alpine
WORKDIR /app

# Copy built backend and its production deps
COPY --from=backend-builder /app/package.json /app/package-lock.json ./
COPY --from=backend-builder /app/backend/package.json ./backend/
COPY --from=backend-builder /app/backend/dist ./backend/dist

# Copy built frontend into backend's public dir (backend will serve it)
COPY --from=frontend-builder /app/frontend/dist ./frontend/dist

# Install production deps only
RUN npm install --production --ignore-scripts

ENV NODE_ENV=production
ENV PORT=4188

# Expose the backend port (Railway auto-assigns PORT)
EXPOSE 4188

# Backend serves both API and static frontend
CMD ["node", "backend/dist/server.js"]
