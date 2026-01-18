# -------- Build stage --------
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Install git (needed for go modules sometimes)
RUN apk add --no-cache ca-certificates git openssh-client && update-ca-certificates

# Copy go mod files first (for layer caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o muchtodo ./cmd/api

# -------- Runtime stage --------
FROM gcr.io/distroless/base-debian12

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/muchtodo /app/muchtodo

# Use non-root user (distroless already runs as non-root)
EXPOSE 8080

# Run the app
ENTRYPOINT ["/app/muchtodo"]
