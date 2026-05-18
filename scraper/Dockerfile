FROM python:3.13-trixie
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
    libxml2 libxslt1.1 python3-lxml \
    && rm -rf /var/lib/apt/lists/*

ENV UV_NO_DEV=1

WORKDIR /app
# Copy the requrements files first to leverage Docker cache
COPY pyproject.toml uv.lock ./

# Install the dependencies
RUN uv sync --locked --no-dev

# Copy the project into the image
COPY . .

CMD ["uv", "run", "main.py"]
