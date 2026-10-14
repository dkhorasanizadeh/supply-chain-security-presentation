FROM golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY main.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /app .

FROM alpine:3.16.7
COPY --from=build /app /app
EXPOSE 8080
ENTRYPOINT ["/app"]
