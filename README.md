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

### General Architecture
![General Architecture Diagram](GeneralArchLight.png)
Read Intent is technically a microservice architecture as a whole.
This diagram should cover the main flows and general layout of the services.
The main entry-point for the backend services infrastructure is a single server (**BFF**) acting as a gateway.
Everything else is closed to the internet as a part of the private network and only the BFF can initiate the flows and be requested to give information.
You can [read more about the BFF](./backend/README.md).
The Python services rely solely on Redis Streams events for I/O, which gets initiated by BFF.

### Ports
There are two main ways to access the backend services from the internet:
- ConnectRPC - Authentication and CRUD operations
- HTTP API - Restricted to only extension authentication and article submission

Every request from the internet must go to backend, using either of two ways, on a HTTP server initiated on a single port.

### Authentication
#### Kratos
The main way we authenticate is by using [Ory Kratos](https://www.ory.com/docs/kratos/configuring) self-hosted instance, behind then BFF (`backend/`). We are using Kratos to manage every aspect of authentication and user information, including sign up, sign in, verification, password reset, etc.
(WIP) Google Sign in will also be managed by Kratos
#### JWT for extension
Another authentication method is implemented for the browser extension, to make pairing it with the mobile app easier - "OAuth 2.0 Device Authorization Grant" ([RFC8628](https://datatracker.ietf.org/doc/html/rfc8628))
with slight modification of not supporting auth by URLs and only supports verification with user code.
We are using mobile app, which is authenticated by Kratos to pair the browser extension to the user, using a device code, displayed in the extension. Once the pairing is successful we are generating signed JWT token, **exclusively for the authentication of parse article** endpoint.

### Regular user flow - With manual article submission

#### 1. Article Submission
User can submit article for parsing in one of two ways:
- Browser Extension - a) Send any URL for parsing. b) Send the current page, URL and trimmed rendered HTML
- Mobile App - Sending URL

The browser submission of the current page is especially useful for getting around the issues with paywalls. If the user is already authorized to view the article, they can send the rendered HTML directly and we will be able to use it, without the paywall restriction.

#### 2. On Article Submission
1. The articles service on backend stores the delivered article URL and status as "processing" in articles table and links the article to the user who submitted it using *many-to-many* relationship. The articles table is used as a sort of caching feature, and other users wanting to submit the same article will simple reuse the already parsed article. *TODO - In case the article is parse from HTML we will need to mark it as special and not reuse it. This will avoid access to the articles they are unauthorize to see and also bad actor submitting malformed articles and other seeing them*
    - Meanwhile, UI will display the processing article in the list
2. The articles service submits an input event to the Redis Streams for scraper to take on.
3. Once the scraper parses the article, it emits output event, with "article_id" and either "result" or an "error" field in it.
    - The articles service gets the event and changes article status accordingly.
    - The phonemizer service also gets the same event and starts generating phonemes for the parsed article.
5. Results from the phonemizer will be consumed by the articles service and update the article accordingly.
6. The UI is checking with an lightweight endpoint if any articles have updated since the last check, pinging it with exponential backoff. If anything changed, the UI will query and get the complete set of updated articles, including the newest addition.
