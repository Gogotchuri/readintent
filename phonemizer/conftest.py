from typing import Any, Generator, cast
from unittest.mock import Mock

import pytest
import redis
from redis import Redis
from testcontainers.redis import RedisContainer

from config import Config
from event_consumer import EventHub


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


class PhonemizerHubFixture:
    def __init__(self, redis_client: Redis):
        self.mock = Mock()
        self.conf = Config(
            stream_input_event="test:input",
            stream_output_event="test:output",
            consumer_group="test-group",
            consumer_name="test-consumer",
            min_idle_time=0,
        )
        self.hub = EventHub(self.conf, redis_client, self.mock)
        self.hub.ensure_group()

    def send(self, **fields):
        self.hub.redis_client.xadd(self.conf.stream_input_event, fields)

    def consume(self):
        self.hub._consume_single_event_batch()

    @property
    def pending(self) -> int:
        info = self.hub.redis_client.xpending(self.conf.stream_input_event, self.conf.consumer_group)
        return info["pending"]

    @property
    def output(self) -> list[dict]:
        results = cast(
            dict,
            self.hub.redis_client.xread({self.conf.stream_output_event: "0-0"}, count=100, block=1000),
        )
        if not results:
            return []
        batch = results.get(self.conf.stream_output_event, [])
        if not batch:
            return []
        return [entry[1] for entry in batch[0]]

    def run_retry_sweep(self):
        self.hub._retry_pending_events()

    def bump_delivery_count(self, n: int):
        for _ in range(n):
            self.hub.redis_client.xautoclaim(
                name=self.conf.stream_input_event,
                groupname=self.conf.consumer_group,
                consumername=self.conf.consumer_name,
                min_idle_time=0,
                start_id="0-0",
            )


@pytest.fixture()
def hub(redis_db) -> Generator[PhonemizerHubFixture, Any, None]:
    f = PhonemizerHubFixture(redis_db)
    yield f
