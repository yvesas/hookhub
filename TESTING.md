# Guia de Testes e Validação - HookHub

Este documento descreve como testar e validar todas as funcionalidades do HookHub.

## 🚀 Início Rápido

### 1. Iniciar a Aplicação

```bash
# Iniciar com Docker Compose
docker compose up

# Aguardar até ver a mensagem de que o servidor está rodando
# Você verá algo como: [info] Running HookhubWeb.Endpoint with Bandit...
```

### 2. Executar Seeds

Em outro terminal:

```bash
docker compose exec app mix run priv/repo/seeds.exs
```

**Importante:** Copie as API keys geradas! Exemplo de saída:

```
Creating providers...
✓ Created providers: MessageFlow, ChatRelay

Creating API keys...
✓ MessageFlow API Key: hh_live_abc123def456...
  (Save this key, it won't be shown again)
✓ ChatRelay API Key: hh_live_xyz789ghi012...
  (Save this key, it won't be shown again)

✅ Database seeded successfully!
```

### 3. Executar Testes Básicos

```bash
./test_api.sh
```

## ✅ Checklist de Validação

### Fase 1: Infraestrutura

- [ ] Docker Compose inicia sem erros
- [ ] PostgreSQL está rodando e acessível
- [ ] Aplicação Phoenix inicia corretamente
- [ ] Migrations executadas com sucesso
- [ ] Seeds executados com sucesso

### Fase 2: Interface Web

#### Dashboard de Eventos (`/dashboard`)

- [ ] Página carrega sem erros
- [ ] Filtro por provedor funciona
- [ ] Filtro por tipo de evento funciona
- [ ] Filtro por data funciona
- [ ] Botão "Clear" limpa os filtros
- [ ] Paginação funciona
- [ ] Botão "Details" expande/colapsa detalhes
- [ ] Raw payload JSON é exibido corretamente

#### Gerenciamento de API Keys (`/dashboard/api-keys`)

- [ ] Página carrega sem erros
- [ ] Botão "Create API Key" abre modal
- [ ] Formulário de criação funciona
- [ ] API key é gerada e exibida
- [ ] Botão "Copy to Clipboard" funciona
- [ ] Chaves são listadas (mascaradas)
- [ ] Botão "Revoke" funciona
- [ ] Chaves revogadas aparecem como "Revoked"

### Fase 3: API de Ingestão

#### Teste com MessageFlow

```bash
# Substitua YOUR_MESSAGEFLOW_API_KEY pela chave gerada
curl -X POST http://localhost:4000/webhooks/ingest \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_MESSAGEFLOW_API_KEY" \
  -d '{
    "event_id": "mf_evt_test_001",
    "event_type": "message.inbound",
    "timestamp": "2025-12-03T23:00:00Z",
    "data": {
      "message_id": "mf_msg_test_001",
      "sender": {
        "id": "usr_test_001",
        "name": "Test User"
      },
      "recipient": {
        "id": "acc_test_001"
      },
      "content": {
        "type": "text",
        "body": "Hello from MessageFlow test!"
      }
    }
  }'
```

**Resultado esperado:**
```json
{
  "status": "success",
  "message": "Event ingested successfully",
  "event_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

- [ ] Retorna status 200
- [ ] Retorna event_id
- [ ] Evento aparece no dashboard

#### Teste com ChatRelay

```bash
# Substitua YOUR_CHATRELAY_API_KEY pela chave gerada
curl -X POST http://localhost:4000/webhooks/ingest \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_CHATRELAY_API_KEY" \
  -d '{
    "id": "cr-test-001",
    "type": "INCOMING_MESSAGE",
    "created_at": 1733270400,
    "payload": {
      "msg_ref": "cr-msg-test-001",
      "platform": "WHATSAPP",
      "from": "+5511999999999",
      "from_name": "Test User",
      "to": "+5511888888888",
      "message": {
        "format": "TEXT",
        "text": "Hello from ChatRelay test!"
      }
    }
  }'
```

**Resultado esperado:**
```json
{
  "status": "success",
  "message": "Event ingested successfully",
  "event_id": "660e8400-e29b-41d4-a716-446655440001"
}
```

- [ ] Retorna status 200
- [ ] Retorna event_id
- [ ] Evento aparece no dashboard

#### Teste de Idempotência

Envie o mesmo evento duas vezes:

```bash
# Primeira vez - deve criar o evento
curl -X POST http://localhost:4000/webhooks/ingest \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{
    "event_id": "mf_evt_idempotency_test",
    "event_type": "message.inbound",
    "timestamp": "2025-12-03T23:00:00Z",
    "data": {
      "message_id": "mf_msg_idem",
      "sender": {"id": "usr_001", "name": "User"},
      "recipient": {"id": "acc_001"},
      "content": {"type": "text", "body": "Idempotency test"}
    }
  }'

# Segunda vez - deve retornar duplicate
curl -X POST http://localhost:4000/webhooks/ingest \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{
    "event_id": "mf_evt_idempotency_test",
    "event_type": "message.inbound",
    "timestamp": "2025-12-03T23:00:00Z",
    "data": {
      "message_id": "mf_msg_idem",
      "sender": {"id": "usr_001", "name": "User"},
      "recipient": {"id": "acc_001"},
      "content": {"type": "text", "body": "Idempotency test"}
    }
  }'
```

**Segunda requisição deve retornar:**
```json
{
  "status": "success",
  "message": "Event already exists (idempotent)",
  "duplicate": true
}
```

- [ ] Primeira requisição cria evento
- [ ] Segunda requisição retorna duplicate: true
- [ ] Apenas um evento existe no banco

#### Teste de Autenticação

```bash
# Sem API key - deve retornar 401
curl -X POST http://localhost:4000/webhooks/ingest \
  -H "Content-Type: application/json" \
  -d '{"event_id": "test"}'

# API key inválida - deve retornar 401
curl -X POST http://localhost:4000/webhooks/ingest \
  -H "Content-Type: application/json" \
  -H "X-API-Key: invalid_key_123" \
  -d '{"event_id": "test"}'
```

- [ ] Sem API key retorna 401
- [ ] API key inválida retorna 401
- [ ] Mensagem de erro apropriada

### Fase 4: API de Consulta

#### Listar Eventos

```bash
# Listar todos os eventos
curl http://localhost:4000/api/events

# Com paginação
curl "http://localhost:4000/api/events?page=1&page_size=10"

# Filtrar por provedor (use o ID do provider)
curl "http://localhost:4000/api/events?provider_id=PROVIDER_UUID"

# Filtrar por tipo
curl "http://localhost:4000/api/events?event_type=message.inbound"

# Filtrar por data
curl "http://localhost:4000/api/events?start_date=2025-12-01T00:00:00Z&end_date=2025-12-31T23:59:59Z"
```

- [ ] Lista eventos corretamente
- [ ] Paginação funciona
- [ ] Filtros funcionam
- [ ] Retorna estrutura JSON correta

#### Buscar Evento Específico

```bash
# Substitua EVENT_ID pelo ID de um evento
curl http://localhost:4000/api/events/EVENT_ID
```

- [ ] Retorna evento específico
- [ ] Retorna 404 para ID inexistente

### Fase 5: API de Gerenciamento de Keys

#### Criar API Key

```bash
# Substitua PROVIDER_ID pelo ID do provider
curl -X POST http://localhost:4000/api/keys \
  -H "Content-Type: application/json" \
  -d '{
    "provider_id": "PROVIDER_ID",
    "name": "Test Key"
  }'
```

- [ ] Cria API key com sucesso
- [ ] Retorna chave completa (apenas uma vez)
- [ ] Chave funciona para autenticação

#### Listar API Keys

```bash
curl http://localhost:4000/api/keys
```

- [ ] Lista todas as chaves
- [ ] Chaves estão mascaradas
- [ ] Mostra status (ativa/revogada)

#### Revogar API Key

```bash
# Substitua KEY_ID pelo ID da chave
curl -X DELETE http://localhost:4000/api/keys/KEY_ID
```

- [ ] Revoga chave com sucesso
- [ ] Chave revogada não funciona mais
- [ ] Status muda para "Revoked"

### Fase 6: Performance

#### Teste de Tempo de Resposta

```bash
# Medir tempo de resposta da ingestão
time curl -X POST http://localhost:4000/webhooks/ingest \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{
    "event_id": "perf_test_001",
    "event_type": "message.inbound",
    "timestamp": "2025-12-03T23:00:00Z",
    "data": {
      "message_id": "msg_001",
      "sender": {"id": "usr_001", "name": "User"},
      "recipient": {"id": "acc_001"},
      "content": {"type": "text", "body": "Performance test"}
    }
  }'
```

- [ ] Resposta em menos de 200ms
- [ ] Resposta consistente em múltiplas requisições

## 🐛 Troubleshooting

### Problema: Docker não inicia

```bash
# Verificar logs
docker compose logs

# Reconstruir imagens
docker compose build --no-cache
docker compose up
```

### Problema: Banco de dados não conecta

```bash
# Verificar se PostgreSQL está rodando
docker compose ps

# Recriar banco
docker compose down -v
docker compose up
```

### Problema: Migrations não executam

```bash
# Executar manualmente
docker compose exec app mix ecto.create
docker compose exec app mix ecto.migrate
```

### Problema: Seeds não executam

```bash
# Verificar se migrations foram executadas
docker compose exec app mix ecto.migrate

# Executar seeds novamente
docker compose exec app mix run priv/repo/seeds.exs
```

## ✅ Critérios de Sucesso

O projeto está completo e funcional quando:

1. ✅ Todos os serviços Docker iniciam sem erros
2. ✅ Migrations e seeds executam com sucesso
3. ✅ Interface web carrega e é navegável
4. ✅ Webhooks são ingeridos com sucesso
5. ✅ Normalização funciona para ambos os provedores
6. ✅ Idempotência previne duplicatas
7. ✅ Autenticação bloqueia requisições inválidas
8. ✅ APIs de consulta retornam dados corretos
9. ✅ Filtros e paginação funcionam
10. ✅ API keys podem ser criadas e revogadas
11. ✅ Performance está dentro do esperado (< 200ms)

## 📝 Relatório de Testes

Após executar todos os testes, preencha:

- Data dos testes: _______________
- Versão testada: _______________
- Ambiente: Docker / Local
- Testes passados: _____ / _____
- Problemas encontrados: _______________
- Observações: _______________
