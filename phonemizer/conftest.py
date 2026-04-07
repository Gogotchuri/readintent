from typing import Any, Generator

import pytest
import redis
from redis import Redis
from testcontainers.redis import RedisContainer

@pytest.fixture(scope="session")
def redis_container():
    with RedisContainer() as container:
        yield container


@pytest.fixture(scope="session")
def redis_client(redis_container: RedisContainer) -> Generator[Redis, Any, None]:
    client = redis.Redis(
        host=redis_container.get_container_host_ip(),
        port=redis_container.get_exposed_port(redis_container.port),
        password=redis_container.password,
        decode_responses=True,
        protocol=3
    )
    yield client
    client.close()


@pytest.fixture()
def redis_db(redis_client):
    redis_client.flushdb()
    yield redis_client

