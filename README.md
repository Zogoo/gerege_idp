# Gerege IdP

Gerege IdP is an open-source Identity Provider (IdP) project that supports modern Single Sign-On (SSO) protocols and various authentication methods, including fingerprint authentication and magic links.

## Features

- **SSO Protocols**: Supports popular SSO protocols such as OAuth2, OpenID Connect, and SAML.
- **Fingerprint Authentication**: Allows users to authenticate using fingerprint recognition.
- **Magic Links**: Provides a passwordless authentication method using magic links sent via email.
- **Scalable**: Designed to handle a large number of authentication requests efficiently.
- **Secure**: Implements best practices for security to protect user data and authentication processes.

## Getting Started

### Prerequisites

- **Ruby**: Install Ruby using a version manager like [rbenv](https://github.com/rbenv/rbenv).
- **PostgreSQL**: Install PostgreSQL using [postgresapp.com](https://postgresapp.com) or Homebrew.
- **Docker**: Ensure Docker is installed and running on your machine.

### Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/yourusername/gerege-idp.git
    cd gerege-idp
    ```

2. Install dependencies:
    ```sh
    bundle install
    ```

3. Set up the database:
    ```sh
    rails db:setup
    ```

4. Start the application:
    ```sh
    rails server
    ```

### Configuration

Configure the application by editing the files in the [config](http://_vscodecontentref_/0) directory, such as [database.yml](http://_vscodecontentref_/1) and [puma.rb](http://_vscodecontentref_/2). Ensure you set the necessary environment variables for database connections and other settings.

### Running Tests

Run the test suite using:
```sh
rails test
```

Contributing
We welcome contributions to Gerege IdP! Please fork the repository and submit pull requests for any enhancements or bug fixes.

License
This project is open for non-profitable usage. Any other usage requires a license. See the LICENSE file for details.

Contact
For any questions or support, please open an issue on the GitHub repository or contact the maintainers.

Feel free to customize this README file further to suit your project's specific needs.