# -------- Build stage --------
FROM golang:1.25-alpine AS builder

WORKDIR /src

# Install git (needed for go modules sometimes)
RUN apk add --no-cache ca-certificates git openssh-client && update-ca-certificates

# Copy go mod files first (for layer caching)
COPY app/go.mod app/go.sum ./
RUN go mod download

# Copy the rest of the source
COPY app/ ./

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o /out/muchtodo ./cmd/api

# -------- Runtime stage --------
FROM gcr.io/distroless/base-debian12

WORKDIR /app

# Copy binary from builder
COPY --from=builder /out/muchtodo /app/muchtodo

# Distroless runs as non-root by default
EXPOSE 8080

ENTRYPOINT ["/app/muchtodo"]
