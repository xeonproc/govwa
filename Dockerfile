FROM golang:alpine AS builder

# Set necessary environment variables needed for our image
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# Move to working directory /app
WORKDIR /app

# Copy and download dependency using go mod
COPY go.mod .
COPY go.sum .
RUN go mod download

# Copy the code into the container
COPY . .

# Download eicar.com file if it does not exist
RUN if [ ! -f /app/eicar.com ]; then \
      wget -q https://secure.eicar.org/eicar.com -O /app/eicar.com; \
    fi

# Build the application
RUN go version
RUN go build -o main .

# Move to /dist directory as the place for resulting binary folder
WORKDIR /dist

# Copy binary and eicar.com from build to main folder
RUN cp /app/main .
RUN cp /app/eicar.com .

# Build a small image
FROM scratch

COPY --from=builder /dist/main /
COPY --from=builder /dist/eicar.com /
COPY ./config/config.json /config/config.json
COPY ./templates/* /templates/
COPY ./public/. /public/
EXPOSE 8888

# Command to run
CMD ["./main"]
