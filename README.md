# Bilanc Self-Hosted

This repository contains the configuration for running a self-hosted instance of Bilanc. Follow these instructions to set up and run your Bilanc environment.

## Prerequisites

- Docker and Docker Compose installed on your system
- Access to required API keys and credentials
- Make sure your user has read access to the Bilanc self-hosted image (contact a Bilanc team member for assistance)
- Authenticate into [gcloud CLI](https://cloud.google.com/docs/authentication/gcloud)
- Run `gcloud auth configure-docker europe-west2-docker.pkg.dev`

## Setup Instructions

### 1. Environment Variables

1. Create a `.env` file in the root directory by copying the provided example:

```bash
cp .env.example .env
```

2. Configure the required environment variables in the `.env` file:

#### Database Configuration
```
POSTGRES_USERNAME=your_postgres_username
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DATABASE=bilanc_db
POSTGRES_HOST=your_postgres_host
POSTGRES_PORT=5432
RAW_DATA_SCHEMA=bilanc
```

#### API Keys
```
AI_PROVIDER=your_ai_provider (google-ai/anthropic/openai)
AI_MODEL=your_ai_model

Only define one of the following based on AI_PROVIDER choice:
GOOGLE_API_KEY=your_google_ai_api_key
OPENAI_API_KEY=your_openai_api_key
ANTHROPIC_API_KEY=your_anthropic_api_key


```

#### Integration Tokens
```
GITHUB_ACCESS_TOKEN=your_github_token
GITHUB_REPOSITORY=owner/repository-1 owner/repository-2
LINEAR_ACCESS_TOKEN=your_linear_token
```

#### Application Settings
```
NEXT_PUBLIC_API_URL=http://host.docker.internal:8000
NEXT_PUBLIC_AUTH_URL=your_auth_url
NEXT_PUBLIC_AUTH_API_KEY=your_auth_api_key
ENVIRONMENT=dev
FRONTEND_URL=http://localhost:3000
```

#### Email Configuration
```
RESEND_API_KEY=your_resend_api_key
DEFAULT_SENDER_EMAIL=notifications@yourdomain.com
```

#### Other Settings
```
DBT_PREFIX=marts
CELERY_BROKER_URL=redis://broker:6379/0
```

For detailed information about these environment variables, refer to the [Bilanc infrastructure documentation](https://bilanc.mintlify.app/self-hosting/infrastructure).

### 2. Configure Tenant and Target Settings

#### Target Configuration

Review and update the `target_config.yaml` file with your database configuration:

```yaml
postgres:
  postgres_db:
    username: !ENV ${POSTGRES_USERNAME}
    password: !ENV ${POSTGRES_PASSWORD}
    hostname: !ENV ${POSTGRES_HOST}
    db_name:  !ENV ${POSTGRES_DATABASE}
    schema:   !ENV ${RAW_DATA_SCHEMA}
    port:     !ENV ${POSTGRES_PORT} 
```

The configuration uses environment variables defined in your `.env` file.

#### Tenant Configuration

Update the `tenant_config.yaml` file with your organization settings:

```yaml
tenants:
  - name: Your Organization Name
    domain: yourdomain.com
    is_auto_onboarding_enabled: true
    taps:
      - name: github
        type: tap-github
        config:
          start_date: 2025-01-01
          repositories: !ENV ${GITHUB_REPOSITORY}
      - name: linear
        type: tap-linear
        config:
          start_date: 2025-01-01
```

Make sure to:
- Replace "Your Organization Name" with your actual organization name
- Update the domain to your organization's domain
- Adjust the number of seats based on your requirements
- Configure the start date for data collection
- Add or remove integration taps as needed

### 3. Starting the Application

Once you've configured your environment variables and configuration files, start the application by running:

```bash
make r
```

This command will build and start all the Docker containers in detached mode.

### 4. Accessing the Application

After the containers are up and running, you can access:

- Web UI: http://localhost:3000
- API: http://localhost:8000
- Dagster Dashboard: http://localhost:4000

## Additional Commands

The Makefile provides several useful commands:

- `make up`: Start all containers in the foreground
- `make down` or `make d`: Stop and remove all containers
- `make recompose`: Rebuild and restart all containers
- `make run` or `make r`: Build and start all containers in detached mode

## Architecture Overview

This self-hosted setup consists of several services:

- **dagster_daemon**: Manages and orchestrates workflows
- **dagster_webserver**: Provides a web interface for monitoring workflows
- **api**: FastAPI backend service
- **broker**: Redis instance for message brokering
- **worker**: Celery worker for background processing
- **frontend**: Next.js frontend application

## Troubleshooting

- If containers fail to start, check the logs with `docker-compose logs [service_name]`
- Ensure all required environment variables are properly set
- Verify the database connection details
- Check that the API keys and integration tokens are valid

For more detailed information, please refer to the [Bilanc documentation](https://bilanc.mintlify.app/self-hosting).