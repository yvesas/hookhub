# 🚀 HookHub - Webhook Gateway Service

[![Elixir](https://img.shields.io/badge/Elixir-1.19.4-purple.svg)](https://elixir-lang.org/)
[![Phoenix](https://img.shields.io/badge/Phoenix-1.8.2-orange.svg)](https://www.phoenixframework.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://docs.docker.com/compose/)

HookHub é um serviço gateway de webhooks que recebe eventos de múltiplos provedores externos, normaliza os dados em um schema unificado, persiste no PostgreSQL e fornece APIs REST + interface web para gerenciamento completo.

## 📋 Índice

- [Características](#-características)
- [Início Rápido](#-início-rápido)
- [Desenvolvimento](#-desenvolvimento)
- [Arquitetura](#-arquitetura)
- [API Reference](#-api-reference)
- [Interface Web](#-interface-web)
- [Testes](#-testes)
- [Documentação](#-documentação)

## ✨ Características

### Core Features

- ⚡ **Ingestão de Webhooks** - Endpoint otimizado com resposta < 200ms
- 🔄 **Normalização Automática** - Suporte a múltiplos provedores (MessageFlow, ChatRelay)
- 🔒 **Autenticação Segura** - API keys com hash SHA256
- 🎯 **Idempotência Garantida** - Eventos duplicados não criam registros
- 📊 **APIs REST Completas** - Consulta, filtros e paginação
- 🎨 **Interface Web Moderna** - Dashboard com dark mode
- 📈 **Analytics Dashboard** - Estatísticas e métricas em tempo real
- 🛡️ **Rate Limiting** - Proteção contra abuso
- 📝 **Logs Estruturados** - JSON logging para observabilidade
- 📊 **Telemetria** - Métricas customizadas com Telemetry

### Diferenciais

- 🌙 **Dark Mode** - Toggle de tema com persistência
- ⚡ **Hot Reload** - Desenvolvimento com mudanças instantâneas
- 🐳 **Docker Ready** - Setup completo com um comando
- 📝 **Documentação Extensiva** - Guias e exemplos completos
- 🔧 **Scripts Auxiliares** - Workflow otimizado
- 📊 **Observabilidade Completa** - Logs, métricas e analytics integrados

## 🚀 Início Rápido

### Pré-requisitos

- Docker & Docker Compose
- (Opcional) Elixir 1.19+ e Erlang/OTP 28 para desenvolvimento local

### Instalação e Execução

```bash
# 1. Clone o repositório
git clone <repository-url>
cd HookHub

# 2. Inicie a aplicação com Docker
docker compose up -d

# 3. Execute as seeds (dados iniciais)
docker compose exec app mix run priv/repo/seeds.exs

# 4. Acesse a aplicação
open http://localhost:4000
```

**Pronto!** A aplicação estará rodando em http://localhost:4000

### API Keys Geradas

Após executar as seeds, você receberá 2 API keys:

```
✓ MessageFlow API Key: hh_live_XXXXX...
✓ ChatRelay API Key:   hh_live_XXXXX...
```

**⚠️ Importante:** Salve essas chaves! Elas são necessárias para testar a ingestão de webhooks.

## 💻 Desenvolvimento

### Opção 1: Desenvolvimento Local (Recomendado) ⚡

**Vantagens:** Hot reload, mudanças instantâneas, logs claros

```bash
# Setup inicial (primeira vez)
./setup_local.sh

# Iniciar servidor de desenvolvimento
./dev.sh
```

Acesse: http://localhost:4000

**Features do modo desenvolvimento:**
- ✅ Hot reload automático em templates (.heex)
- ✅ Recompilação automática de código Elixir
- ✅ Live reload no browser
- ✅ Logs detalhados no terminal

### Opção 2: Desenvolvimento com Docker 🐳

**Vantagens:** Ambiente idêntico à produção, isolamento completo

```bash
# Rebuild completo (sem cache)
./rebuild.sh
```

### Scripts Auxiliares

| Script | Descrição | Quando usar |
|--------|-----------|-------------|
| `./setup_local.sh` | Setup inicial para dev local | Primeira vez ou após clean |
| `./dev.sh` | Servidor com hot reload | Desenvolvimento diário |
| `./rebuild.sh` | Rebuild Docker completo | Mudanças em templates |
| `./clean.sh` | Limpar ambiente | Reset completo |

### Workflow Recomendado

```bash
# Desenvolvimento diário (mais rápido)
./dev.sh

# Quando mudar templates ou precisar rebuild
./rebuild.sh

# Para limpar tudo e começar do zero
./clean.sh
./setup_local.sh
```

## 🏗️ Arquitetura

### Stack Tecnológico

- **Backend:** Elixir 1.19.4 + Phoenix 1.8.2
- **Database:** PostgreSQL 15
- **Frontend:** HTML + Tailwind CSS + JavaScript
- **Container:** Docker + Docker Compose
- **ORM:** Ecto 3.13

### Estrutura do Projeto

```
HookHub/
├── lib/
│   ├── hookhub/                      # Business logic
│   │   ├── events.ex                 # Events context
│   │   ├── providers.ex              # Providers context
│   │   ├── events/
│   │   │   ├── event.ex              # Event schema
│   │   │   └── normalizer.ex         # Payload normalization
│   │   └── providers/
│   │       ├── provider.ex           # Provider schema
│   │       └── api_key.ex            # API key management
│   └── hookhub_web/                  # Web layer
│       ├── controllers/
│       │   ├── webhook_controller.ex # Webhook ingestion
│       │   ├── event_controller.ex   # Events API
│       │   ├── api_key_controller.ex # API keys API
│       │   └── dashboard_controller.ex # Web interface
│       ├── plugs/
│       │   └── api_key_auth.ex       # Authentication middleware
│       └── router.ex                 # Routes
├── priv/repo/
│   ├── migrations/                   # Database migrations
│   └── seeds.exs                     # Initial data
├── docker-compose.yml                # Docker orchestration
├── Dockerfile                        # Application image
└── README.md                         # This file
```

### Database Schema

```sql
-- Providers (MessageFlow, ChatRelay)
providers (id, name, description, inserted_at, updated_at)

-- API Keys (authentication)
api_keys (
  id, provider_id, name, key_hash, key_prefix,
  is_active, expires_at, revoked_at,
  inserted_at, updated_at
)

-- Events (normalized schema)
events (
  id, provider_id, external_event_id, event_type,
  sender_id, sender_name, recipient_id, recipient_name,
  message_type, message_body, platform, timestamp,
  raw_payload, inserted_at, updated_at
)
```

**Constraints:**
- `UNIQUE(provider_id, external_event_id)` - Idempotência

**Indexes:**
- `provider_id, timestamp` - Performance em queries
- `event_type` - Filtros rápidos

## 📡 API Reference

### Webhook Ingestion

```bash
POST /webhooks/ingest
Headers:
  Content-Type: application/json
  X-API-Key: hh_live_XXXXX...

# MessageFlow payload
{
  "event_id": "msg_001",
  "event_type": "message.inbound",
  "timestamp": "2025-12-04T00:00:00Z",
  "data": {
    "sender": {"id": "usr_001", "name": "Alice"},
    "recipient": {"id": "acc_001"},
    "content": {"type": "text", "body": "Hello!"}
  }
}

# ChatRelay payload
{
  "id": "cr_001",
  "type": "INCOMING_MESSAGE",
  "created_at": 1733280000,
  "payload": {
    "platform": "WHATSAPP",
    "from": "+5511999999999",
    "from_name": "Bob",
    "to": "+5511888888888",
    "message": {"format": "TEXT", "text": "Hello!"}
  }
}
```

### Events API

```bash
# List events with filters
GET /api/events?provider_id=UUID&event_type=message.inbound&page=1

# Get specific event
GET /api/events/:id
```

### API Keys Management

```bash
# Create new API key
POST /api/keys
{
  "provider_id": "UUID",
  "name": "Production Key"
}

# List API keys
GET /api/keys

# Revoke API key
DELETE /api/keys/:id
```

**Veja exemplos completos em:** [API_EXAMPLES.md](API_EXAMPLES.md)

## 🎨 Interface Web

### Dashboard de Eventos

**URL:** http://localhost:4000/dashboard

**Features:**
- 📊 Lista de eventos com paginação
- 🔍 Filtros por provedor, tipo e data
- 📝 Detalhes expansíveis com payload completo
- 🌙 Dark mode com toggle

### Gerenciamento de API Keys

**URL:** http://localhost:4000/dashboard/api-keys

**Features:**
- ➕ Criar novas API keys
- 📋 Listar chaves (mascaradas)
- 🗑️ Revogar chaves
- 📋 Copiar para clipboard
- 🌙 Dark mode com toggle

### Analytics Dashboard

**URL:** http://localhost:4000/dashboard/analytics

**Features:**
- 📊 **Métricas Principais:**
  - Total de webhooks recebidos
  - Atividade das últimas 24 horas
  - Taxa de sucesso
  - Tempo médio de resposta

- 📈 **Gráficos e Visualizações:**
  - Webhooks por provider (com percentuais)
  - Top 10 tipos de eventos
  - Estatísticas por provider

- 🔍 **Filtros:**
  - Últimas 24 horas
  - Últimos 7 dias
  - Últimos 30 dias
  - Últimos 90 dias

- 📋 **Tabela de Providers:**
  - Total de eventos por provider
  - Data do último evento
  - Status de atividade

### Dark Mode

Clique no ícone de sol/lua no header para alternar entre temas:
- 🌞 **Light Mode** - Tema claro padrão
- 🌙 **Dark Mode** - Tema escuro com alto contraste

O tema é salvo automaticamente e sincronizado entre páginas.

## 🧪 Testes

### Teste Rápido

```bash
# Testar ingestão de webhook
curl -X POST http://localhost:4000/webhooks/ingest \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{
    "event_id": "test_001",
    "event_type": "message.inbound",
    "timestamp": "2025-12-04T00:00:00Z",
    "data": {
      "sender": {"id": "usr_001", "name": "Test"},
      "recipient": {"id": "acc_001"},
      "content": {"type": "text", "body": "Hello!"}
    }
  }'

# Verificar eventos
curl http://localhost:4000/api/events | jq
```

### Suite de Testes

```bash
# Executar todos os testes
./test_api.sh
```

**Veja guia completo em:** [TESTING.md](TESTING.md)

## � Simulação de Tráfego

Para validar o funcionamento do sistema com tráfego realista, incluímos um script de simulação que:
1. Gera chaves de API temporárias ("Simulation Key") para cada provedor.
2. Envia webhooks contínuos (MessageFlow e ChatRelay) para `http://localhost:4000`.
3. Exibe o status de cada requisição em tempo real.

### Executando a Simulação

Certifique-se de que a aplicação está rodando (via Docker ou `./dev.sh`) e execute:

```bash
# Opção 1: Via mix alias (recomendado)
mix simulate

# Opção 2: Executar o script diretamente
mix run scripts/simulate_traffic.exs
```

**Exemplo de saída:**
```
🚀 Starting Traffic Simulation (Elixir)...
🔑 Creating Helper Simulation Keys...
   👉 Created key for MessageFlow: sk_sim_a1b2c3d4
   👉 Created key for ChatRelay: sk_sim_e5f6g7h8

📡 Sending webhooks... (Press Ctrl+C to stop)

✅ [14:35:22] MessageFlow -> 201
✅ [14:35:23] ChatRelay -> 201
✅ [14:35:24] MessageFlow -> 201
```

*Para parar a simulação, pressione `Ctrl+C`.*

## �📚 Documentação

- **[API_EXAMPLES.md](API_EXAMPLES.md)** - Exemplos completos de uso da API
- **[TESTING.md](TESTING.md)** - Guia de testes e validação
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Workflow de desenvolvimento

## 🔧 Configuração

### Variáveis de Ambiente

```bash
# Database
DB_HOST=localhost          # Database host
DB_USER=hookhub           # Database user
DB_PASSWORD=hookhub       # Database password
DB_NAME=hookhub_dev       # Database name

# Application
PORT=4000                 # Server port
SECRET_KEY_BASE=...       # Phoenix secret (auto-generated)
```

### Docker Compose

```yaml
services:
  db:
    image: postgres:15-alpine
    ports: ["5432:5432"]
    
  app:
    build: .
    ports: ["4000:4000"]
    depends_on:
      db:
        condition: service_healthy
```

## 🚨 Troubleshooting

### Porta 4000 em uso

```bash
# Encontrar processo
lsof -i :4000

# Matar processo
kill -9 <PID>
```

### Erro de conexão com banco

```bash
# Verificar se PostgreSQL está rodando
docker compose ps

# Reiniciar banco
docker compose restart db
```

### Hot reload não funciona

```bash
# Limpar e reconfigurar
./clean.sh
./setup_local.sh
./dev.sh
```

### Rebuild completo

```bash
# Limpar tudo
./clean.sh

# Rebuild Docker
./rebuild.sh
```

## 📊 Performance & Observabilidade

### Performance
- ⚡ **Ingestão:** < 200ms por webhook
- 🔄 **Idempotência:** Constraint no banco
- 📈 **Escalabilidade:** Connection pooling + índices otimizados
- 🎯 **Concorrência:** Erlang VM (milhares de conexões simultâneas)

### Logs Estruturados
- 📝 **Formato:** JSON com metadata contextual
- 🔍 **Campos:** timestamp, level, message, request_id, provider, event_type
- 📊 **Integração:** Pronto para ELK, Splunk, CloudWatch

### Métricas (Telemetry)
- **Webhooks:** count, duration, errors, duplicates
- **Database:** query time, pool size, connection stats
- **HTTP:** requests, response time, routing
- **VM:** memory, queue lengths, process count

### Rate Limiting
- 🛡️ **Webhook Ingestion:** 1000 requests/minuto por API key
- 🔒 **API Queries:** 100 requests/minuto por IP
- 🚫 **Admin Operations:** 10 requests/minuto por IP
- 📋 **Headers:** X-RateLimit-Limit, X-RateLimit-Remaining, Retry-After
- ⚠️ **Response:** HTTP 429 quando limite excedido

## 🔒 Segurança

- 🔐 **API Keys:** Hash SHA256
- 🛡️ **Validação:** Middleware de autenticação
- ⏰ **Expiração:** Suporte a chaves temporárias
- 🚫 **Revogação:** Desativação instantânea

## 🎯 Próximos Passos (Quem sabe...)

Melhorias futuras planejadas:

- [ ] Testes automatizados (ExUnit)
- [ ] Webhooks de saída (notificações)
- [ ] Export de dados (CSV/JSON)
- [ ] CI/CD pipeline
- [ ] Autenticação web (login para interface)
- [ ] Busca full-text (Elasticsearch)

**Já implementado:**
- ✅ Logs estruturados (JSON)
- ✅ Métricas (Telemetry)
- ✅ Rate limiting (Hammer)
- ✅ Dashboard de estatísticas


---

