# ReadIntent (Monorepo Readme)

A Read-it-later application for saving, reading, and listening to web content, primarily articles.

Users can save articles through a browser extension, a direct URL, or RSS feed (coming soon), and the app will clean up and sanitise the content, removing all Ads and unnecessary distractions. The cleaned-up content will be made available offline on your devices.
The app will run text-to-speech directly on-device and generate high-quality audio articles offline. Generating a podcast-like experience from the content YOU want to consume.
**The core idea is intentional reading**: choose where you want to focus your attention, rather than have it chosen for you by algorithms.

*Original proposal can be read at [./docs/Proposal.md](./docs/Proposal.md)*


## Project Layout

### Monorepo
I have decided to make this project a [**monorepo**](https://en.wikipedia.org/wiki/Monorepo). *Meaning all of the code for all of the services, application and infrastructure are located in this repository*.
Monorepos are a bit controversial, but in this case advantages it offers definitely outweights disadvantages.
- Fast iteration times, without cross-repo coordination overhead and faster code exploration across projects.
- Easier to make changes and distribute shared protobuf and ConnectRPC contracts.
- At the start of the project, most of the projecs require changes to be made to multiple layers at once either way.
- Building and running dev environments, and managing environment variables are easier under the same root.
- I am a single contributor for now and there are no conflicting changes across the projects.
Those are just some fo the upsides. Down the line if the shared version managements gets in the way and other contributors join, we can always split this repository into multirepo or employ more advanced monorepo tooling.

## Projects and layout
- `backend/` - A Go server acting as a primary gateway and the main API for the public net. Handles authentication and general CRUD. Recieves requests with HTTP, ConnectRPC and Redis Streams.
- `browser_extension/` - JS extension for Chromium and Firefox based browsers, built with service workers. Manages article submission through browser extension.
- `docs/` - contains general and shared documentation for this project.
- `infra/` - Configuration and orchestration management for different environments. Currently handles
  - **postgres** setup, initialization and permission/access rules.
  - **[Kratos]**(https://www.ory.com/docs/kratos/configuring) configuration.
  - **Docker Compose** setup for dev and production (WIP).
- `phonemizer/` - A Python service running audio inference pipeline with [**Kokoro**](https://github.com/hexgrad/kokoro), currently used to generate [phonemes](https://en.wikipedia.org/wiki/Phoneme) for pre-transform purified article text. I/O is done through Redis Streams events.
- `scraper/` - A Python service running [Trafilatura](https://trafilatura.readthedocs.io/en/latest/index.html) for article gathering with custom transformations for cleaning up the article. I/O is done through Redis Streams events.
- `shared/` - A shared components between other services are located here.
  - `shared/connectrpc` - [ConnectRPC](https://connectrpc.com/) shared contracts for generating typesafe code with protobuf protocol. Uses [**Make**](https://www.gnu.org/software/make/) config for distributing the generated files between `ui/` and `backend/` projects.
- `ui/` - [Flutter](https://flutter.dev/) project for Android/IOS/Desktop platforms. This is the main UI for the project. This can also be made to work with web, but would require major modifications.

*More details about each of the components are in Readme.md of each*

## Running project
- Running the backend services of the project only required Docker and Docker compose setup. For details check the [`infra/`](./infra) directory. To run dev, create `.env.dev` from `.env.example` and run `sh start_dev.sh`.
- The browser extension can be loaded in each browser separately.
- Flutter UI requires flutter to be installed on the device. `flutter run -d <platform>`

## Architecture and event flow

### Ports
There are two main ways to access the backend services from the internet:
- ConnectRPC - Authentication and CRUD operations
- HTTP API - Restricted to only extension authentication and article submission

### Authentication
//TODO
