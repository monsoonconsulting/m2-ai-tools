# m2-ai-tools

A collection of Magento 2 AI skills for Claude Code, Cursor, Copilot, and other AI coding assistants. Each skill teaches the AI assistant how to generate production-ready Magento 2 code following best practices.

## Quick Install

Run from your Magento 2 project root:

```sh
# Claude Code
curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s claude

# Cursor
curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s cursor

# GitHub Copilot
curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s copilot

# Codex
curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s codex

# Gemini
curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s gemini

# OpenCode
curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s opencode
```

The installer detects your Magento root (looks for `app/etc/env.php`) and deploys skill files into the platform-specific directory.

## Skills

### Module Structure

| Skill | Description |
|-------|-------------|
| `m2-module` | Scaffold a new Magento 2 module with all required files |
| `m2-di-config` | Configure dependency injection — preferences, virtual types, argument replacement |
| `m2-plugin` | Create before/after/around plugins (interceptors) |
| `m2-observer` | Create event observers with common event reference |

### Database & Data

| Skill | Description |
|-------|-------------|
| `m2-db-schema` | Declarative database schema (tables, columns, indexes, constraints) |
| `m2-eav-attributes` | EAV attribute creation with data patches |
| `m2-indexer` | Custom indexer with Mview materialization |
| `m2-cache-type` | Custom cache type with invalidation logic |

### API & Integration

| Skill | Description |
|-------|-------------|
| `m2-api-builder` | REST/SOAP Web API with service contracts |
| `m2-graphql-builder` | GraphQL schema, resolvers, and mutations |
| `m2-extension-attributes` | Extension attributes for extending core entities |
| `m2-message-queue` | Message queue publishers, consumers, and topology |
| `m2-import-export` | Import/export entity types and custom processors |

### Admin

| Skill | Description |
|-------|-------------|
| `m2-admin-ui` | Admin grids, forms, UI components, and ACL |
| `m2-system-config` | System configuration (system.xml) with field types and source models |
| `m2-cli-command` | Custom CLI commands (bin/magento) |

### Frontend

| Skill | Description |
|-------|-------------|
| `m2-controller` | Frontend and admin controllers with proper HTTP verb interfaces |
| `m2-frontend-layout` | Layout XML, blocks, containers, and templates |
| `m2-theme` | Custom theme scaffolding and inheritance |
| `m2-page-builder` | Page Builder content types and appearances |
| `m2-widget` | CMS widget types with configurable parameters |
| `m2-customer-sections` | Customer section (private content) data providers |
| `m2-customer-account` | Customer account pages and sections |

### Checkout & Sales

| Skill | Description |
|-------|-------------|
| `m2-checkout` | Checkout customizations — steps, totals, payment rendering |
| `m2-payment-method` | Payment method integration |
| `m2-shipping-carrier` | Shipping carrier with rate calculation |
| `m2-product-type` | Custom product types |

### Scheduling & Email

| Skill | Description |
|-------|-------------|
| `m2-cron-job` | Cron jobs with schedule expressions and custom groups |
| `m2-email-template` | Transactional email templates |

### Quality & Security

| Skill | Description |
|-------|-------------|
| `m2-testing` | PHPUnit tests — unit, integration, and API functional |
| `m2-security` | Security best practices — CSRF, ACL, input validation |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `M2_SKILLS_REPO_URL` | GitHub repo URL | Override the repository URL |
| `M2_SKILLS_BRANCH` | `main` | Branch to install from |

## License

Proprietary — All rights reserved. Copyright (c) Monsoon Consulting.
