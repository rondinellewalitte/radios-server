# 🔧 Troubleshooting - FreeRADIUS no EasyPanel

## ❌ Problema: FreeRADIUS exited with code 1

### Causas Comuns

1. **Módulo SQL não habilitado**
2. **Arquivo de configuração SQL com erro de sintaxe**
3. **Variáveis de ambiente não expandidas**
4. **Arquivo de queries não encontrado**

---

## ✅ Solução Aplicada

Criamos um **Dockerfile customizado** que:
- ✅ Habilita o módulo SQL automaticamente
- ✅ Copia todas as configurações necessárias
- ✅ Define permissões corretas
- ✅ Usa valores hardcoded (não variáveis de ambiente)

---

## 🔍 Como Verificar Logs no EasyPanel

### Ver logs do FreeRADIUS:
```bash
# Via docker-compose
docker-compose logs freeradius

# Ver últimas 50 linhas
docker-compose logs --tail=50 freeradius

# Seguir logs em tempo real
docker-compose logs -f freeradius
```

### Testar configuração do FreeRADIUS:
```bash
# Entrar no container
docker-compose exec freeradius sh

# Testar configuração (dentro do container)
radiusd -XC

# Se tudo estiver OK, você verá:
# Configuration appears to be OK
```

### Modo Debug (para diagnosticar problemas):
```bash
# Parar o container
docker-compose stop freeradius

# Rodar em modo debug
docker-compose run --rm freeradius radiusd -X

# Isso mostrará todos os detalhes do que está acontecendo
```

---

## 🐛 Erros Comuns e Soluções

### Erro: "Failed to link /etc/freeradius/mods-enabled/sql"
**Causa**: Módulo SQL não habilitado
**Solução**: O Dockerfile agora faz isso automaticamente

### Erro: "No such file or directory: queries.conf"
**Causa**: Tentativa de incluir arquivo que não existe
**Solução**: Removemos o `$INCLUDE` da configuração SQL

### Erro: "Failed to connect to database"
**Causa**: PostgreSQL não está pronto ou senha incorreta
**Solução**: 
- Verifique se postgres iniciou: `docker-compose ps postgres`
- Verifique senha no arquivo `freeradius/mods-available/sql`
- Certifique-se que a senha é a mesma do .env

### Erro: "Permission denied"
**Causa**: Permissões incorretas nos arquivos
**Solução**: O Dockerfile corrige isso com `chown`

---

## 🧪 Testar Autenticação

### Teste Básico (dentro do container):
```bash
docker-compose exec freeradius sh
radtest admin "Admin@123" localhost 1812 testing123
```

### Teste Externo (do seu PC):
```bash
# Instalar ferramenta
sudo apt install freeradius-utils

# Testar
radtest admin "Admin@123" SEU_IP_SERVIDOR 1812 testing123

# Resposta esperada:
# Sending Access-Request Id 123 to SEU_IP_SERVIDOR:1812
# ...
# Received Access-Accept Id 123 from SEU_IP_SERVIDOR:1812
```

---

## 📝 Alterar Senha do Banco de Dados

Se você mudar a senha do PostgreSQL nas variáveis de ambiente, você **TAMBÉM** precisa atualizar em:

**Arquivo**: `freeradius/mods-available/sql`

```
# Altere estas linhas:
login = "radius"
password = "SUA_NOVA_SENHA_AQUI"
radius_db = "radius"
```

Depois:
```bash
# Rebuild da imagem
docker-compose build freeradius

# Reiniciar
docker-compose restart freeradius
```

---

## 🔄 Rebuild Completo

Se nada funcionar, tente rebuild completo:

```bash
# Parar tudo
docker-compose down

# Limpar imagens antigas
docker-compose build --no-cache

# Reiniciar
docker-compose up -d

# Ver logs
docker-compose logs -f
```

---

## 📊 Verificar Status dos Serviços

```bash
# Ver todos os containers
docker-compose ps

# Deve mostrar algo como:
# NAME                  STATUS
# radios-server-postgres-1     running
# radios-server-freeradius-1   running
# radios-server-adminer-1      running

# Se freeradius mostrar "Exited", veja os logs:
docker-compose logs freeradius
```

---

## 🆘 Checklist de Diagnóstico

Quando o FreeRADIUS não iniciar:

- [ ] PostgreSQL está rodando? `docker-compose ps postgres`
- [ ] Senha do SQL está correta no arquivo `sql`?
- [ ] Arquivos de configuração estão no lugar certo?
- [ ] Permissões dos arquivos estão corretas?
- [ ] Módulo SQL foi habilitado?
- [ ] Logs mostram erro específico? `docker-compose logs freeradius`
- [ ] Teste de configuração passa? `radiusd -XC`

---

## 📞 Última Tentativa

Se ainda assim não funcionar, você pode usar a versão mais simples sem SQL temporariamente:

```bash
# Editar docker-compose.yml
# Comentar a build do freeradius e usar a imagem padrão:

freeradius:
  image: freeradius/freeradius-server:latest
  # build:
  #   context: .
  #   dockerfile: Dockerfile.freeradius
```

Isso iniciará o FreeRADIUS sem SQL (apenas com arquivos locais) para você testar se o resto está funcionando.

---

**Dica**: Sempre comece pelos logs! Eles mostram exatamente o que está errado.
