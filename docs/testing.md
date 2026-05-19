# Testing

### TestContainers
[TestContainers](https://golang.testcontainers.org/) is an awesome package, allowing us to run Docker containers and Docker Compose orchestration inside individual tests.
This in turn allow us to use real dependencies in tests with minimal overhead, instead of introducing mocks that often lose important implementation details, that could cause failures down the line.
*TestContainers* allow us to write integration tests for every service components, since the package is available in Go and Python.

### Integration Testing
Integration tests should try to minimize mocked code and instead test against the real services and implementations.

### E2E Testing
E2E tests are mainly located in the `backend/tests/e2e` directory, which actually builds images for supporting services, connects actual ConnectRPC client and tests the flow End-to-End.
