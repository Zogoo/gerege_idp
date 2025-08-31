<h1 align="left">
  <a href="#">
    <img src="https://github.com/yatish27/gerege-idp/assets/1014383/fbad8ed2-9510-4693-a342-4bafa515b164" width="128px"/>
  </a>

GeregeIdP

  <p align="left">
    <a href="https://github.com/yatish27/gerege-idp/actions">
      <img alt="Build Status" src="https://github.com/yatish27/gerege-idp/actions/workflows/ci.yml/badge.svg"/>
    </a>
    <a href="https://github.com/yatish27/gerege-idp/blob/master/LICENSE.txt">
      <img alt="License" src="https://img.shields.io/badge/license-MIT-428F7E.svg"/>
    </a>
    <a href="https://codeclimate.com/github/yatish27/gerege-idp/maintainability"><img src="https://api.codeclimate.com/v1/badges/1cd4e3f1c0a4c5af29b1/maintainability" /></a>
  </p>
</h1>

## Introduction

GeregeIdP is a Ruby on Rails template with modern stack to start your new project.

## Features

- **Ruby**: Ruby 3.4.2
- **Rails**: [Rails 8](https://rubyonrails.org)
- **PostgreSQL**: [PostgresSQL 17](https://www.postgresql.org)
- **Tailwind CSS**: Uses [Tailwind CSS v4](https://tailwindcss.com) for styling.
- **Vite Ruby**: Uses [Vite Ruby](https://vite-ruby.netlify.app) for asset management. It is based on [Vite.js](https://vitejs.dev). It replaces webpacker, jsbundling-rails, cssbundling-rails, importmaps and sprockets/propshaft.
- **Node/npm**: Uses Node and npm.
- **Solid Queue**: Uses [Solid Queue](https://github.com/rails/solid_queue) for background processing.
- **Minitest/FactoryBot**: Uses Rails' default testing library, minitest along with [Factorybot](https://github.com/thoughtbot/factory_bot).
- **Rubocop**: Auto-formats Ruby code with [rubocop](https://rubocop.org).
- **Prettier**: Auto-formats JavaScript and CSS code with [prettier](https://prettier.io).
- **Github Actions**: Uses Github Actions for continuous integration and deployment.
- **Deployment**: Supports deployment on [Heroku](https://www.heroku.com/platform) and [Render](https://render.com)

## WebAuthn/Passkey Authentication

This application includes full WebAuthn support for passwordless authentication using passkeys. Users can:

### For Users:
1. **Add Passkeys**: Go to Settings → Authentication → Manage passkeys
2. **Login with Passkeys**: Use fingerprint, face ID, or other biometric authentication
3. **Multiple Devices**: Register passkeys on multiple devices (iPhone, MacBook, Windows PC, etc.)

### Features:
- **Biometric Authentication**: Fingerprint, face ID, or PIN
- **Cross-platform**: Works on iOS, macOS, Windows, Android
- **Secure**: Uses public-key cryptography
- **User-friendly**: No passwords to remember or type

### Technical Implementation:
- **Backend**: Uses the `webauthn` gem for server-side verification
- **Frontend**: Stimulus controllers handle WebAuthn API calls
- **Database**: Stores encrypted public keys and metadata
- **Security**: Implements proper challenge-response verification

### Routes:
- `/users/passkey_login` - Passkey login page
- `/users/passkey_management` - Manage user's passkeys
- `/users/passkey_login/authenticate` - Authentication endpoint

## Getting Started

### System Requirements

You will need the following to run the application.

- [**Ruby 3.4.2**](./docs/installing_prerequisites.md#ruby)
- [**PostgreSQL 17**](./docs/installing_prerequisites.md#postgresql)

Refer [here](./docs/installing_prerequisites.md) to install these dependencies

### Initial setup

- GeregeIdP is a preconfigured base Ruby on Rails application. You can clone this repository and add it to your repo.

  ```bash
  git clone git@github.com:yatish27/gerege-idp.git your_new_project_name
  cd your_new_project_name
  ```

- The application's default name is GeregeIdP. You can rename it to your desired new name. The name should be in camelcase.

  ```bash
  ./bin/rename_project YourNewProjectName
  ```

- Copy the `env.sample` to `.env`

  - The default username and password for database is set to `postgres` and `postgres`. You can override them in `.env` file.

- Run `bin/setup` to set up the application. It prepares the database and installs the required ruby gems and javascript packages. The script is idempotent, so you can run it multiple times.

  ```bash
  ./bin/setup
  ```

### Running the application

#### Option 1: Local Development (Recommended)

Start your application

```bash
./bin/dev
```

This runs overmind or foreman using the Procfile.dev. It starts the rails server, solid queue background job process and vite server.

Visit [http://localhost:3000](http://localhost:3000) to see the home page 🚀.

#### Option 2: Docker Compose

For containerized development environment, you can use Docker Compose:

```bash
# Start all services (database, redis, and Rails app)
docker-compose up

# Or run in background
docker-compose up -d

# To run with background job processor
docker-compose --profile worker up

# To stop all services
docker-compose down

# To rebuild containers after dependency changes
docker-compose build

# To view logs
docker-compose logs -f web
```

The Docker Compose setup includes:
- **PostgreSQL**: Latest Alpine version for the database
- **Redis**: Latest Alpine version for caching and queues
- **Rails App**: Development-optimized container with hot reloading
- **Worker**: Background job processor (optional, use `--profile worker`)

Visit [http://localhost:3000](http://localhost:3000) to see the home page 🚀.

## Deployment

- Heroku
- Render

## Testing

Running all tests

```
./bin/rails test:all
```

Running a single test

```
./bin/rails test test/jobs/hello_world_job_test.rb
```

## License

GeregeIdP is released under the [MIT License](./LICENSE.txt).

## Contributing

PRs are welcome
