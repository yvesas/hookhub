# HookHub Development Scripts

Este diretório contém scripts úteis para desenvolvimento.

## 🚀 Desenvolvimento Local (com Hot Reload)

### Primeira vez - Setup inicial:
```bash
./setup_local.sh
```

Isso vai:
- ✅ Verificar se Elixir está instalado
- 📦 Iniciar PostgreSQL no Docker
- 📚 Instalar dependências
- 🗄️ Criar e migrar banco de dados
- 🌱 Popular dados iniciais

### Iniciar servidor de desenvolvimento:
```bash
./dev.sh
```

**Vantagens:**
- ⚡ Hot reload automático em templates (.heex)
- 🔄 Recompilação automática de código Elixir
- 🌐 Live reload no browser
- 📝 Logs claros no terminal

Acesse: http://localhost:4000

## 🐳 Desenvolvimento com Docker

### Rebuild completo (sem cache):
```bash
./rebuild.sh
```

Use quando:
- Mudou templates e precisa reconstruir
- Quer garantir build limpo
- Teve problemas com cache

## 🧹 Limpeza

### Limpar ambiente de desenvolvimento:
```bash
./clean.sh
```

Remove:
- Build artifacts (_build, deps)
- Para servidores rodando
- Para containers Docker

## 📋 Resumo dos Scripts

| Script | Uso | Quando usar |
|--------|-----|-------------|
| `setup_local.sh` | Setup inicial local | Primeira vez ou após clean |
| `dev.sh` | Servidor com hot reload | Desenvolvimento diário |
| `rebuild.sh` | Rebuild Docker completo | Mudanças em templates |
| `clean.sh` | Limpar tudo | Reset completo |

## 💡 Dicas

**Para desenvolvimento rápido (recomendado):**
1. Use `./dev.sh` - hot reload é muito mais rápido!
2. Mantenha PostgreSQL no Docker
3. Phoenix roda localmente

**Para ambiente idêntico à produção:**
1. Use `./rebuild.sh`
2. Tudo roda no Docker
3. Mais lento mas mais seguro

## 🔧 Troubleshooting

**Erro de conexão com banco:**
```bash
# Verifique se PostgreSQL está rodando
docker compose ps

# Reinicie apenas o banco
docker compose restart db
```

**Hot reload não funciona:**
```bash
# Limpe e reconfigure
./clean.sh
./setup_local.sh
./dev.sh
```

**Porta 4000 em uso:**
```bash
# Encontre o processo
lsof -i :4000

# Mate o processo
kill -9 <PID>
```
