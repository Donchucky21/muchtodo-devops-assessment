# ---- Build stage ----
FROM golang:1.25-alpine AS builder

WORKDIR /src

RUN apk add --no-cache ca-certificates git

# Copy go mod files first for better caching
COPY Server/MuchToDo/go.mod Server/MuchToDo/go.sum ./
RUN go mod download

# Copy the rest of the backend source
COPY Server/MuchToDo/ ./

# Build (adjust ./ if your main package is in a subfolder like ./cmd/api)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/muchtodo ./cmd/api

# ---- Runtime stage ----
FROM alpine:3.20

RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

RUN apk add --no-cache ca-certificates curl

COPY --from=builder /out/muchtodo /app/muchtodo

USER app

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=5 \
  CMD curl -fsS http://127.0.0.1:3000/health || exit 1

ENTRYPOINT ["/app/muchtodo"]
