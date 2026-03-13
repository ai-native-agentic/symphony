# SYMPHONY — KNOWLEDGE BASE

**Generated:** 2026-03-10

## OVERVIEW

Symphony turns project work into isolated, autonomous implementation runs — AI agents manage coding tasks autonomously while engineers manage work at a higher level. Monitors Linear for candidate issues, spawns isolated Codex agents per issue, provides proof-of-work (CI status, PR review, complexity analysis, walkthrough videos), and safely lands approved PRs.

Stack: Elixir 1.19, OTP 28, Phoenix LiveView 1.1, Bandit HTTP, Req HTTP client, SQLite-backed state

## STRUCTURE

symphony/
├── elixir/
│   ├── _build/
│   ├── bin/
│   ├── config/
│   ├── cover/
│   ├── deps/
│   ├── docs/
│   ├── lib/
│   ├── log/
│   ├── priv/
│   ├── test/
│   ├── AGENTS.md
│   ├── Makefile
│   └── README.md
├── AGENTS.md
├── README.md

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Linear polling loop | `lib/symphony_elixir/orchestrator.ex` | Polls Linear, claims issues, spawns agents |
| Agent spawning | `lib/symphony_elixir/agent_runner.ex` | Creates workspace, launches Codex |
| Workspace isolation | `lib/symphony_elixir/workspace.ex` | Per-issue isolated dirs |
| Linear GraphQL | `lib/symphony_elixir/linear/client.ex` | API client with Req |
| Codex App Server | `lib/symphony_elixir/codex/app_server.ex` | App Server mode integration |
| Config setup | `lib/symphony_elixir/config.ex` | Env vars + YAML config |
| Web dashboard | `lib/symphony_elixir_web/dashboard_live.ex` | Phoenix LiveView UI |
| OTP supervision | `lib/symphony_elixir/application.ex` | Supervisor tree |

## COMMANDS

```bash
# Setup (requires mise for Elixir 1.19)
cd elixir/
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"
mise install     # installs Elixir 1.19.5 + OTP 28
make setup       # mix deps.get

# Build escript binary
make build       # produces bin/symphony

# Run Symphony
./elixir/bin/symphony --config config.yaml

# Development
make fmt         # mix format
make fmt-check   # check formatting
make lint        # mix specs.check + credo --strict
make test        # mix test
make coverage    # mix test --cover
make dialyzer    # type checking
make all         # full CI: setup + build + fmt-check + lint + coverage + dialyzer
```

## KEY MODULES

| Module | Role |
|--------|------|
| `SymphonyElixir.Orchestrator` | GenServer: Linear polling, issue claiming, agent lifecycle |
| `SymphonyElixir.AgentRunner` | Launches Codex in App Server mode per issue |
| `SymphonyElixir.Workspace` | Creates/destroys isolated working directories |
| `SymphonyElixir.Linear.Client` | GraphQL queries/mutations against Linear API |
| `SymphonyElixir.Codex.AppServer` | Codex App Server protocol (stdio JSON-RPC) |
| `SymphonyElixir.Codex.DynamicTool` | Injects `linear_graphql` tool into Codex sessions |
| `SymphonyElixir.Config` | Parses YAML config + env vars via NimbleOptions |
| `SymphonyElixir.CLI` | Escript entry point (main/1) |
| `SymphonyElixirWeb.DashboardLive` | Phoenix LiveView real-time status dashboard |

## DEPENDENCIES

| Package | Version | Purpose |
|---------|---------|---------|
| `phoenix` | ~1.8.0 | Web framework |
| `phoenix_live_view` | ~1.1.0 | Real-time dashboard |
| `bandit` | ~1.8 | HTTP server |
| `req` | ~0.5 | HTTP client (Linear API) |
| `jason` | ~1.4 | JSON encode/decode |
| `yaml_elixir` | ~2.12 | YAML config parsing |
| `solid` | ~1.2 | Liquid template engine |
| `nimble_options` | ~1.1 | Config schema + validation |
| `credo` | ~1.7 | Static analysis |
| `dialyxir` | ~1.4 | Type checking |

## CONVENTIONS

- **OTP patterns**: GenServer for stateful processes, Supervisor trees for fault tolerance
- **Config via env**: All secrets via env vars (LINEAR_API_KEY, OPENAI_API_KEY, etc.)
- **Isolated workspaces**: Each Linear issue gets its own directory; cleanup on terminal state
- **Test coverage threshold**: 100% (mix.exs enforces this — many modules are excluded)
- **Credo strict**: `credo --strict` on all non-excluded modules
- **Dialyzer**: Full type checking in CI
- **Escript binary**: `bin/symphony` for single-binary distribution
- **App Server mode**: Codex runs as a persistent App Server, not one-shot subprocess

## ANTI-PATTERNS

| Forbidden | Why |
|-----------|-----|
| Blocking calls in GenServer handle_call | Breaks OTP supervision model |
| Hardcoded API keys | Use env vars via Config |
| Shared mutable state across agents | Each agent has isolated workspace |
| Modifying SPEC.md without updating impl | Spec is source of truth |
| `IO.inspect` in production code | Use Logger |
| Skipping dialyzer | Type safety is enforced in CI |

## NOTES

- **Production warning**: Prototype software for evaluation only — not hardened for production
- **Alternative implementations**: SPEC.md is language-agnostic; implement in any language
- **Linear integration**: Polls for `In Progress` issues, claims them, monitors for state changes
- **Terminal states**: Done, Closed, Cancelled, Duplicate → agent stopped + workspace cleaned
- **Proof of work**: CI status, PR review feedback, complexity analysis, walkthrough videos
- **mise required**: Elixir 1.19.5 + OTP 28 managed via mise (see elixir/mise.toml)
- **Test coverage**: 100% threshold enforced; many I/O modules excluded from coverage
