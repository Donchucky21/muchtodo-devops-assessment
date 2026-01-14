# syntax=docker/dockerfile:1

########## Build stage ##########
FROM golang:1.22-alpine AS builder

WORKDIR /src

# Install build deps (git sometimes needed for go modules)
RUN apk add --no-cache git ca-certificates

# Copy go.mod/go.sum first for caching
COPY Server/MuchToDo/go.mod Server/MuchToDo/go.sum ./Server/MuchToDo/
WORKDIR /src/Server/MuchToDo
RUN go mod download

# Copy source
COPY Server/MuchToDo ./Server/MuchToDo

# Build a static binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/api ./cmd/api


########## Runtime stage ##########
FROM alpine:3.20

# Create non-root user
RUN addgroup -S app && adduser -S -G app app \
    && apk add --no-cache ca-certificates curl

WORKDIR /app

COPY --from=builder /out/api /app/api

# Run as non-root
USER app

EXPOSE 8080

# Healthcheck required by assessment
HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD curl -fsS http://localhost:8080/health || exit 1

CMD ["/app/api"]
