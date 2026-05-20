# Go Back-End for Frontend (BFF)

Main gateway service for Read Intent. Handles user authentication (via Ory Kratos), articles CRUD, and browser extension pairing. This service is also responsible for starting the event pipeline in RedisStreams.
*Technically this monolith is constructed of few well decoupled smaller services, constructing a "Modular Monolith" with independent slices*

## Configuration

Configuration is read and built in [`config/config.go`](./config/config.go) from ENV variables and defaults. A `.env` file can be placed at `config/.env` (see [`config/.env.example`](./config/.env.example)).

Here are all of the ENV variables that can be set for this project:

**Server**
- `ENVIRONMENT` - Runtime environment (`dev` / `prod`), default: `dev`
- `PORT` - HTTP and ConnectRPC server port, default: `5050`

**Auth / Kratos**
- `KRATOS_PUBLIC_URL` - Ory Kratos public API URL, default: `http://localhost:4433`

**PostgreSQL** (prefix `DATABASE_CONFIG_`)
- `DATABASE_CONFIG_HOSTNAME` - Database host, default: `localhost`
- `DATABASE_CONFIG_PORT` - Database port, default: `5432`
- `DATABASE_CONFIG_USERNAME` - Database user, default: `postgres`
- `DATABASE_CONFIG_PASSWORD` - Database password, default: `postgres`
- `DATABASE_CONFIG_DATABASE` - Database name, default: `postgres`
- `DATABASE_CONFIG_SSLMODE` - SSL mode, default: `disable`

**Redis Streams** (prefix `REDIS_`)
- `REDIS_HOSTNAME` - Redis host, default: `localhost`
- `REDIS_PORT` - Redis port, default: `6379`
- `REDIS_PASSWORD` - Redis password, default: (empty)
- `REDIS_DB` - Redis database number, default: `0`
- `REDIS_GROUP_NAME` - Redis Streams consumer group name for BFF
- `REDIS_CONSUMER_NAME` - Redis Streams consumer name for BFF instance

## Running

*Requires PostgreSQL, Redis, and Ory Kratos to be running. See `infra/` for full docker-compose setup.*

### With Docker
From this directory build and run the Docker image:
```sh
docker build -t readintent_backend . && docker run -p 5050:5050 readintent_backend
```

### Without Docker
```sh
go build -o main . && ./main
```
or directly:
```sh
go run .
```

## API

The backend exposes two protocols on a single HTTP server:
- **ConnectRPC** - Auth and Articles services, defined in `proto/` (protobuf definitions)
- **HTTP REST** - Browser extension endpoints (pairing, token exchange)

## Project Structure
- `main.go` - Entry point. Initializes config, database, Redis, services, and starts the HTTP server with graceful shutdown.
- `config/` - Configuration loading from ENV variables with defaults. Uses `caarlos0/env` and `godotenv`.
- `database/` - PostgreSQL connection, Redis client setup, and SQL migrations (`database/migrations/`).
- `services/auth/` - Authentication service. Integrates with Ory Kratos for session validation.  Exposed via ConnectRPC.
- `services/articles/` - Article CRUD service. Orchestrates the scraping and phonemizing pipeline through Redis Streams. Exposed via ConnectRPC.
- `services/extension/` - Browser extension pairing service. Grant code and JWT token generation. Exposed via HTTP REST.
- `middlewares/` - HTTP middlewares (session validation).
- `proto/` - Generated protobuf and ConnectRPC code for auth and articles services.
- `tests/` - End-to-end tests simulating the full pipeline.

## Testing

Run all tests:
```sh
go test ./...
```

Tests use [testcontainers-go](https://golang.testcontainers.org/) to spin up PostgreSQL (and other dependencies) in Docker, so Docker must be running.

## Architecture

A few different architectural concepts are used in this directory. I'll try to cover and underline some of those here.

### Modular Monolith
This directory technically contains 3 different isolated services or modules:
- Authentication service
- Articles service
- Extension service
The services are decoupled from each other and injected at the runtime using manual DI.
The idea is to keep things simple and flexible at the start of the development, and be able to extract the parts of the system as separate services with minimal pain down the line (in case the computational or responsibility decoupling of the services becomes required).
Each service module in `backend/services` can easily be made runnable as a separate process by moving into it's own CMD package and attaching protocol of choice in between it and it's dependants.
We are currently calling functions instead of a network or fs calls, which in principle can easily be swapped.

### Clean Architecture
Each service is using concepts from the clean architecture:
- Repository patterns - abstracting away the storage layer to focus on bussiness logic
- Ports - The input layers to the application, in our case - HTTP, ConnectRPC and Redis Streams
- Adapters - Adapters are ways our app talks to the outside world, we have adapters for Kratos and Redis

### Vertical Slices
The whole thing together is also known as the **Vertical Slices Architecture**, we split boundries based on the actors and domain, instead of technical units (which would be horizontal slices / onion)
