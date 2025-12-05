defmodule HookhubWeb.Router do
  use HookhubWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {HookhubWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :api_rate_limited do
    plug(:accepts, ["json"])
    plug(HookhubWeb.Plugs.RateLimiter, type: :api)
  end

  pipeline :webhook_rate_limited do
    plug(:accepts, ["json"])
    plug(HookhubWeb.Plugs.RateLimiter, type: :webhook)
  end

  pipeline :admin_rate_limited do
    plug(:accepts, ["json"])
    plug(HookhubWeb.Plugs.RateLimiter, type: :admin)
  end

  scope "/", HookhubWeb do
    pipe_through(:browser)

    # Redirect root to dashboard
    get("/", PageController, :home)

    # Dashboard routes
    get("/dashboard", DashboardController, :index)
    get("/dashboard/api-keys", DashboardController, :api_keys)
    get("/dashboard/analytics", DashboardController, :analytics)
  end

  # Webhook ingestion endpoint (requires API key authentication + rate limiting)
  scope "/webhooks", HookhubWeb do
    pipe_through(:webhook_rate_limited)

    post("/ingest", WebhookController, :ingest)
  end

  # API endpoints for querying events (with rate limiting)
  scope "/api", HookhubWeb do
    pipe_through(:api_rate_limited)

    resources("/events", EventController, only: [:index, :show])
  end

  # API endpoints for managing API keys (with stricter rate limiting)
  scope "/api", HookhubWeb do
    pipe_through(:admin_rate_limited)

    resources("/keys", ApiKeyController, only: [:index, :create, :delete])
  end
end
