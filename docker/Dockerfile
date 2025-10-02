# Cloud CV - SRE/DevOps Engineer Portfolio
# Multi-stage Docker build for production-ready deployment

# Stage 1: Build stage
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    python3 \
    make \
    g++

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Build the application (if using build tools)
# RUN npm run build

# Stage 2: Production stage
FROM nginx:alpine

# Install additional tools for debugging and monitoring
RUN apk add --no-cache \
    curl \
    jq \
    tzdata

# Set timezone
ENV TZ=UTC

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built application from builder stage
COPY --from=builder /app/frontend /usr/share/nginx/html

# Create nginx user and set permissions
RUN addgroup -g 1001 -S nginx && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d

# Create health check script
RUN echo '#!/bin/sh' > /usr/local/bin/healthcheck.sh && \
    echo 'curl -f http://localhost:80/ || exit 1' >> /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Switch to non-root user
USER nginx

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
