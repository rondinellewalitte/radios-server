# ⚙️ Configuração Específica do EasyPanel

## 📝 Mudanças para Compatibilidade

Este `docker-compose.yml` foi otimizado para o EasyPanel:

✅ **Removido `version`** - Obsoleto no Docker Compose moderno
✅ **Removido `container_name`** - EasyPanel gerencia nomes automaticamente
✅ **Mudado `ports` para `expose`** - Evita conflitos de portas

## 🌐 Como Expor as Portas no EasyPanel

Como usamos `expose` ao invés de `ports`, você precisa configurar as portas no painel do EasyPanel:

### Opção 1: Via Interface do EasyPanel

1. Vá no seu projeto no EasyPanel
2. Acesse a seção **"Domains & Ports"** ou **"Networking"**
3. Adicione as seguintes portas:

**Para o FreeRADIUS:**
- Porta: `1812` | Protocolo: `UDP` | Container Port: `1812`
- Porta: `1813` | Protocolo: `UDP` | Container Port: `1813`

**Para o Adminer:**
- Porta: `8080` | Protocolo: `TCP` | Container Port: `8080`

### Opção 2: Via SSH no Servidor

Se o EasyPanel não permitir configurar portas UDP pela interface:

```bash
# Conectar via SSH ao servidor
ssh usuario@seu-servidor

# Liberar portas no firewall
sudo ufw allow 1812/udp comment "RADIUS Authentication"
sudo ufw allow 1813/udp comment "RADIUS Accounting"
sudo ufw allow 8080/tcp comment "Adminer Web UI"

# Verificar regras
sudo ufw status numbered
```

### Opção 3: Configuração Manual de Port Mapping

Se precisar forçar o mapeamento de portas, edite temporariamente o docker-compose.yml no servidor:

```bash
# No servidor EasyPanel
cd /etc/easypanel/projects/seu-projeto/code

# Editar docker-compose.yml e adicionar ports:
nano docker-compose.yml
```

Adicione em cada serviço:

```yaml
freeradius:
  # ... outras configurações
  ports:
    - "1812:1812/udp"
    - "1813:1813/udp"

adminer:
  # ... outras configurações
  ports:
    - "8080:8080"
```

Depois reinicie:
```bash
docker-compose restart
```

## 🔍 Verificar se as Portas Estão Abertas

```bash
# Verificar portas TCP
sudo netstat -tlnp | grep -E "8080"

# Verificar portas UDP
sudo netstat -ulnp | grep -E "1812|1813"

# Testar do seu computador
nmap -sU -p 1812,1813 SEU_IP_SERVIDOR
```

## 📊 Encontrar Nome dos Containers

Como removemos `container_name`, o EasyPanel cria nomes automáticos. Para encontrá-los:

```bash
# Listar todos os containers
docker ps

# Filtrar por projeto
docker ps | grep radius

# Os nomes serão algo como:
# radios-server-postgres-1
# radios-server-freeradius-1
# radios-server-adminer-1
```

## 🛠️ Comandos Úteis com Novos Nomes

```bash
# Substituir nos comandos do README:
# Ao invés de: docker exec -it radius-postgres psql ...
# Use: docker exec -it radios-server-postgres-1 psql ...

# Ou use o docker-compose que identifica automaticamente:
docker-compose exec postgres psql -U radius -d radius

# Logs
docker-compose logs -f freeradius

# Restart
docker-compose restart freeradius
```

## 🎯 Resumo

1. ✅ Use `docker-compose` ao invés de `docker` sempre que possível
2. ✅ Configure as portas no EasyPanel ou via firewall
3. ✅ Os nomes dos containers serão gerados pelo EasyPanel
4. ✅ Tudo funciona normalmente, apenas os nomes mudaram

---

**Pronto!** O docker-compose.yml agora está 100% compatível com o EasyPanel sem conflitos! 🚀
