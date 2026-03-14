# --- Стадия сборки ---
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Копируем зависимости
COPY go.mod go.sum ./
RUN go mod download

# Копируем исходники и собираем бинарник
COPY . .
RUN CGO_ENABLED=0 go build -o recipe-api ./cmd/api

# --- Финальный образ ---
FROM alpine:3.19
WORKDIR /app
COPY --from=builder /app/recipe-api .
EXPOSE 8080

CMD ["./recipe-api"]