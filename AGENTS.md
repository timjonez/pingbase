# Pingbase — Project Agent Guide

## Overview

Open-source Slack alternative built with Elixir/Phoenix + LiveView.
Self-hosted = all features free. SaaS = per-seat freemium (10 free users).

## Tech Stack

- **Backend**: Elixir / Phoenix / LiveView
- **Frontend**: Tailwind CSS + DaisyUI
- **Database**: PostgreSQL
- **Jobs**: Oban
- **Auth**: Magic links + API tokens
- **Billing**: Stripe (SaaS only)
- **Files**: S3-compatible

## Commands

```bash
# Setup
mix setup

# Run dev server
mix phx.server

# Run tests
mix test

# Database
mix ecto.create
mix ecto.migrate
mix ecto.reset

# Assets
mix assets.build
mix assets.deploy
```

## Architecture

- **Contexts** (lib/pingbase/*): All business logic
- **Web** (lib/pingbase_web/*): Thin controllers and LiveViews
- **Service-layer first**: Contexts are pure functions, reusable by API/MCP/CLI

## Database Rules

- Table names: singular (e.g., `user`, `workspace`)
- Every table: `created_at` and `updated_at`

## Auth

- Web: Magic link → session cookie
- API/MCP/CLI: Bearer token (`Authorization: Token <token>`)

## License

O'Saasy License — open source, SaaS rights reserved.

## Project Structure

```
docs/        — Documentation
specs/       — Feature specs
plans/       — Implementation plans
lib/pingbase/accounts/     — Users, auth, tokens
lib/pingbase/billing/      — Stripe, plans, subscriptions
lib/pingbase/workspaces/   — Workspaces, memberships, invites
lib/pingbase/chat/         — Rooms, messages, reactions
lib/pingbase/notifications/ — Notifications
lib/pingbase/integrations/ — Webhooks, slash commands
lib/pingbase/uploads/      — File uploads
```
