# Tech Stack

## Languages

- **Dart** — linguagem principal (Flutter SDK ^3.6.1)
- **Kotlin** — camada nativa Android (plugins, integrações de sistema)

## Framework

- **Flutter** (estável mais recente, ^3.6.1)
  - Plataformas suportadas: Android, iOS, Web, Linux, macOS, Windows

## State Management

- **Provider** (`provider: ^6.1.0`)

## Backend & APIs

- **REST API** — backend principal (projeto separado); consumida via `http: ^1.6.0`
- **GraphQL API** — analytics (projeto separado); consumida via `graphql_flutter: ^5.1.2`

## Authentication

- **Firebase Auth** (`firebase_auth: ^5.4.2`)
- **Google Sign-In** (`google_sign_in: ^6.2.2`)

## Push Notifications

- **Firebase Messaging** (`firebase_messaging: ^15.2.10`)

## Data Visualization

- **fl_chart** (`fl_chart: ^1.2.0`)
- **Syncfusion Flutter Charts** (`syncfusion_flutter_charts: ^33.1.44`)

## Local Storage

- **SQLite** — persistência local de dados
- **shared_preferences** (`shared_preferences: ^2.2.3`) — preferências e configurações do usuário

## Serialization

- **json_annotation** + **json_serializable** + **build_runner** — geração de código para serialização JSON

## Internationalization

- **flutter_localizations** + **intl** (`intl: ^0.20.2`)

## Infrastructure & Deployment

- **Docker** — containerização
- **Kubernetes (k8s)** — orquestração de containers
- **Nginx** — servidor web/proxy reverso
- **Firebase Hosting** — hospedagem web

## CI/CD

- **semantic-release** — versionamento semântico automático baseado em Conventional Commits
- **GitLab CI/CD** — pipeline de integração e entrega contínua
