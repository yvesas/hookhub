# API Examples

Este arquivo contém exemplos de como usar a API do HookHub.

## Autenticação

Todas as requisições para `/webhooks/ingest` requerem uma API key no header:

```
X-API-Key: hh_live_XXXXXXXXXX
```

## 1. Ingestão de Webhooks

### MessageFlow Provider

```bash
curl -X POST http://localhost:4000/webhooks/ingest \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_MESSAGEFLOW_API_KEY" \
  -d '{
    "event_id": "mf_evt_8a7b6c5d4e3f2a1b",
    "event_type": "message.inbound",
    "timestamp": "2025-01-15T14:32:07Z",
    "data": {
      "message_id": "mf_msg_1a2b3c4d5e6f",
      "sender": {
        "id": "usr_mf_7k9m2p4q8r1t",
        "name": "João Silva"
      },
      "recipient": {
        "id": "acc_mf_3x5z7w9y1v0u"
      },
      "content": {
        "type": "text",
        "body": "Olá, gostaria de agendar uma consulta."
      }
    }
  }'
```

**Resposta de Sucesso:**
```json
{
  "status": "success",
  "message": "Event ingested successfully",
  "event_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Resposta de Idempotência (evento duplicado):**
```json
{
  "status": "success",
  "message": "Event already exists (idempotent)",
  "duplicate": true
}
```

### ChatRelay Provider

```bash
curl -X POST http://localhost:4000/webhooks/ingest \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_CHATRELAY_API_KEY" \
  -d '{
    "id": "cr-20250115-143207-abc123",
    "type": "INCOMING_MESSAGE",
    "created_at": 1736951527,
    "payload": {
      "msg_ref": "cr-msg-xyz789",
      "platform": "WHATSAPP",
      "from": "+5511999887766",
      "from_name": "João Silva",
      "to": "+5511888776655",
      "message": {
        "format": "TEXT",
        "text": "Olá, gostaria de agendar uma consulta."
      }
    }
  }'
```

### Erros de Autenticação

**API Key ausente:**
```json
{
  "message": "Missing API key"
}
```
Status: 401 Unauthorized

**API Key inválida:**
```json
{
  "message": "Invalid API key"
}
```
Status: 401 Unauthorized

**API Key revogada ou expirada:**
```json
{
  "message": "API key is inactive or revoked"
}
```
Status: 403 Forbidden

## 2. Consulta de Eventos

### Listar Todos os Eventos

```bash
curl http://localhost:4000/api/events
```

**Resposta:**
```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "provider": {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "name": "MessageFlow"
      },
      "external_event_id": "mf_evt_8a7b6c5d4e3f2a1b",
      "event_type": "message.inbound",
      "timestamp": "2025-01-15T14:32:07Z",
      "sender": {
        "id": "usr_mf_7k9m2p4q8r1t",
        "name": "João Silva"
      },
      "recipient": {
        "id": "acc_mf_3x5z7w9y1v0u",
        "name": null
      },
      "message": {
        "type": "text",
        "body": "Olá, gostaria de agendar uma consulta."
      },
      "platform": "MessageFlow",
      "raw_payload": { ... },
      "inserted_at": "2025-01-15T14:32:08Z"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 42,
    "total_pages": 3
  }
}
```

### Filtrar por Provedor

```bash
curl "http://localhost:4000/api/events?provider_id=660e8400-e29b-41d4-a716-446655440001"
```

### Filtrar por Tipo de Evento

```bash
curl "http://localhost:4000/api/events?event_type=message.inbound"
```

### Filtrar por Intervalo de Tempo

```bash
curl "http://localhost:4000/api/events?start_date=2025-01-01T00:00:00Z&end_date=2025-01-31T23:59:59Z"
```

### Paginação

```bash
curl "http://localhost:4000/api/events?page=2&page_size=10"
```

### Filtros Combinados

```bash
curl "http://localhost:4000/api/events?provider_id=660e8400-e29b-41d4-a716-446655440001&event_type=message.inbound&page=1&page_size=20"
```

### Buscar Evento Específico

```bash
curl http://localhost:4000/api/events/550e8400-e29b-41d4-a716-446655440000
```

**Resposta:**
```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "provider": {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "name": "MessageFlow"
    },
    "external_event_id": "mf_evt_8a7b6c5d4e3f2a1b",
    "event_type": "message.inbound",
    "timestamp": "2025-01-15T14:32:07Z",
    "sender": {
      "id": "usr_mf_7k9m2p4q8r1t",
      "name": "João Silva"
    },
    "recipient": {
      "id": "acc_mf_3x5z7w9y1v0u",
      "name": null
    },
    "message": {
      "type": "text",
      "body": "Olá, gostaria de agendar uma consulta."
    },
    "platform": "MessageFlow",
    "raw_payload": { ... },
    "inserted_at": "2025-01-15T14:32:08Z"
  }
}
```

## 3. Testando com Docker

Primeiro, inicie os serviços:

```bash
docker compose up
```

Aguarde até ver a mensagem que o banco foi criado e as migrations executadas.

Depois, execute os seeds para criar os provedores e API keys:

```bash
docker compose exec app mix run priv/repo/seeds.exs
```

Copie as API keys geradas e use nos exemplos acima.

## 4. Performance

A API foi projetada para responder em menos de 200ms:

```bash
time curl -X POST http://localhost:4000/webhooks/ingest \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{ ... }'
```

## 5. Idempotência

Enviar o mesmo evento duas vezes não cria registros duplicados:

```bash
# Primeira requisição - cria o evento
curl -X POST http://localhost:4000/webhooks/ingest \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{"event_id": "test_123", ...}'

# Segunda requisição - retorna sucesso mas não cria duplicata
curl -X POST http://localhost:4000/webhooks/ingest \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{"event_id": "test_123", ...}'
```

A segunda requisição retornará:
```json
{
  "status": "success",
  "message": "Event already exists (idempotent)",
  "duplicate": true
}
```
