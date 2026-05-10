# Start from the latest golang base image
FROM golang:1.26.1 AS builder

# Set necessary environmet variables needed for our image
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux
# Move to working directory /app
WORKDIR /app

# Copy and download dependency using go mod
COPY go.mod go.sum ./
RUN go mod download

# Copy the code into the container
COPY . .
# Remove all non go files, clean up config files
#RUN cd config/ && ls | grep -v .go$ | xargs rm -rf && cd ..

# Build the application
RUN go build -o main .

###### Scratch optimization case ######
FROM alpine:latest

RUN apk --no-cache add ca-certificates curl

WORKDIR /root/

# Copy the Pre-built binary file from the previous stage
COPY --from=builder /app/main .

# Export necessary port
EXPOSE 5050

# Command to run when starting the container
CMD ["./main"]
