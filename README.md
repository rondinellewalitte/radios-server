# Servidor RADIUS com Docker e PostgreSQL

Sistema completo de autenticação RADIUS para controlar acessos Wi-Fi através dos Access Points da empresa.

## 📋 Componentes

- **FreeRADIUS**: Servidor RADIUS para autenticação
- **PostgreSQL**: Banco de dados para gerenciar usuários
- **Adminer**: Interface web para gerenciar o banco de dados

## 🚀 Instalação

### 1. Pré-requisitos

```bash
# Instalar Docker e Docker Compose
sudo apt update
sudo apt install docker.io docker-compose -y

# Adicionar seu usuário ao grupo docker (opcional)
sudo usermod -aG docker $USER
```

### 2. Configurar o projeto

```bash
# Clone ou copie os arquivos para um diretório
cd radius-server

# Ajuste as permissões
chmod 644 freeradius/clients.conf
chmod 644 freeradius/mods-available/sql
chmod 644 freeradius/sites-available/default
chmod 644 init-db.sql
```

### 3. Configurar seus Access Points

Edite o arquivo `freeradius/clients.conf` e adicione os IPs dos seus APs:

```bash
nano freeradius/clients.conf
```

Exemplo de configuração:
```
client ap-escritorio-1 {
    ipaddr = 192.168.1.10
    secret = MinhaSenhaSecreta123!
    require_message_authenticator = yes
    nas_type = other
    shortname = ap-escritorio-1
}
```

**IMPORTANTE**: Anote o "secret" pois você precisará configurá-lo no Access Point!

### 4. Iniciar os serviços

```bash
# Iniciar todos os containers
docker-compose up -d

# Verificar se está rodando
docker-compose ps

# Ver logs em tempo real
docker-compose logs -f freeradius
```

## 📊 Acessar o Adminer (Interface Web)

1. Abra o navegador: `http://SEU_IP:8080`
2. Faça login:
   - **Sistema**: PostgreSQL
   - **Servidor**: postgres
   - **Usuário**: radius
   - **Senha**: RadiusSecurePass123!
   - **Base de dados**: radius

## 👥 Gerenciar Usuários

### Via Adminer (Interface Web)

1. Acesse o Adminer
2. Vá em "SQL command" ou nas tabelas diretamente

### Via SQL (comandos diretos)

```bash
# Conectar ao PostgreSQL
docker exec -it radius-postgres psql -U radius -d radius

# Adicionar novo usuário
INSERT INTO usuarios_empresa (username, nome_completo, email, departamento) 
VALUES ('joao.silva', 'João Silva', 'joao@empresa.com', 'TI');

INSERT INTO radcheck (username, attribute, op, value) 
VALUES ('joao.silva', 'Cleartext-Password', ':=', 'SenhaSegura123!');

INSERT INTO radusergroup (username, groupname, priority) 
VALUES ('joao.silva', 'usuarios_wifi', 1);

# Listar todos os usuários ativos
SELECT * FROM v_usuarios_ativos;

# Desativar um usuário
UPDATE usuarios_empresa SET ativo = FALSE WHERE username = 'joao.silva';

# Alterar senha
UPDATE radcheck SET value = 'NovaSenha123!' 
WHERE username = 'joao.silva' AND attribute = 'Cleartext-Password';

# Sair do PostgreSQL
\q
```

## 🔧 Configurar Access Points

### Exemplo: UniFi Controller

1. Acesse o Controller UniFi
2. Vá em **Settings** → **Profiles** → **RADIUS**
3. Clique em **Create New RADIUS Profile**
4. Configure:
   - **Profile Name**: Servidor RADIUS Empresa
   - **Auth Servers**:
     - IP: `IP_DO_SERVIDOR_RADIUS`
     - Port: `1812`
     - Password: `SecretSharedKey123!` (o mesmo do clients.conf)
   - **Accounting Servers**:
     - IP: `IP_DO_SERVIDOR_RADIUS`
     - Port: `1813`
     - Password: `SecretSharedKey123!`

5. Aplique este perfil RADIUS à sua rede Wi-Fi

### Exemplo: TP-Link

1. Acesse a interface do AP
2. Vá em **Wireless** → **Wireless Security**
3. Configure:
   - **Security Mode**: WPA2-Enterprise
   - **RADIUS Server IP**: `IP_DO_SERVIDOR_RADIUS`
   - **RADIUS Port**: `1812`
   - **RADIUS Password**: `SecretSharedKey123!`

## 📈 Monitoramento

### Ver logs de autenticação

```bash
# Logs do FreeRADIUS
docker-compose logs -f freeradius

# Ver tentativas de autenticação recentes (via SQL)
docker exec -it radius-postgres psql -U radius -d radius -c "SELECT username, reply, authdate, nasipaddress FROM radpostauth ORDER BY authdate DESC LIMIT 20;"

# Ver sessões ativas
docker exec -it radius-postgres psql -U radius -d radius -c "SELECT username, nasipaddress, acctstarttime, acctsessiontime FROM radacct WHERE acctstoptime IS NULL;"
```

### Verificar conexões ativas

```bash
# Acessar banco de dados
docker exec -it radius-postgres psql -U radius -d radius

# Consultar sessões ativas
SELECT username, nasipaddress, acctstarttime, 
       EXTRACT(EPOCH FROM (NOW() - acctstarttime))::int as tempo_conectado
FROM radacct 
WHERE acctstoptime IS NULL 
ORDER BY acctstarttime DESC;
```

## 🧪 Testar Autenticação

```bash
# Instalar radtest (se necessário)
sudo apt install freeradius-utils -y

# Testar autenticação de um usuário
radtest admin "Admin@123" localhost 1812 testing123

# Resposta de sucesso:
# Received Access-Accept
```

## 🔐 Segurança

### Alterar senhas padrão

```bash
# Edite o docker-compose.yml e altere:
# - POSTGRES_PASSWORD
# - A senha no arquivo freeradius/mods-available/sql

# Depois recrie os containers
docker-compose down
docker-compose up -d
```

### Backup do banco de dados

```bash
# Fazer backup
docker exec radius-postgres pg_dump -U radius radius > backup_radius_$(date +%Y%m%d).sql

# Restaurar backup
docker exec -i radius-postgres psql -U radius -d radius < backup_radius_20250206.sql
```

## 📊 Queries Úteis

```sql
-- Total de usuários cadastrados
SELECT COUNT(*) FROM usuarios_empresa WHERE ativo = TRUE;

-- Usuários por departamento
SELECT departamento, COUNT(*) as total 
FROM usuarios_empresa 
WHERE ativo = TRUE 
GROUP BY departamento;

-- Últimas 50 tentativas de autenticação
SELECT username, reply, authdate, nasipaddress 
FROM radpostauth 
ORDER BY authdate DESC 
LIMIT 50;

-- Usuários que nunca fizeram login
SELECT u.username, u.nome_completo 
FROM usuarios_empresa u
LEFT JOIN radpostauth p ON u.username = p.username
WHERE p.username IS NULL AND u.ativo = TRUE;

-- Tempo total de conexão por usuário (últimos 30 dias)
SELECT username, 
       COUNT(*) as total_sessoes,
       SUM(acctsessiontime) / 3600 as horas_totais
FROM radacct 
WHERE acctstarttime > NOW() - INTERVAL '30 days'
GROUP BY username 
ORDER BY horas_totais DESC;
```

## 🛠️ Comandos Úteis

```bash
# Parar todos os serviços
docker-compose down

# Reiniciar apenas o FreeRADIUS
docker-compose restart freeradius

# Ver uso de recursos
docker stats

# Limpar logs antigos
docker-compose logs --tail=100 > /dev/null

# Recriar tudo do zero (APAGA DADOS!)
docker-compose down -v
docker-compose up -d
```

## 📞 Suporte

### Problemas Comuns

**Erro de conexão ao banco**
```bash
# Verifique se o PostgreSQL está rodando
docker-compose ps postgres

# Veja os logs
docker-compose logs postgres
```

**FreeRADIUS não inicia**
```bash
# Veja os logs de erro
docker-compose logs freeradius

# Verifique sintaxe dos arquivos de configuração
docker exec freeradius-server radiusd -XC
```

**Autenticação falha**
```bash
# Modo debug do FreeRADIUS
docker-compose stop freeradius
docker-compose run --rm freeradius radiusd -X

# Verificar se o usuário existe no banco
docker exec -it radius-postgres psql -U radius -d radius -c "SELECT * FROM radcheck WHERE username = 'nome_usuario';"
```

## 📝 Estrutura de Arquivos

```
radius-server/
├── docker-compose.yml           # Orquestração dos containers
├── init-db.sql                  # Schema e dados iniciais do PostgreSQL
├── README.md                    # Este arquivo
└── freeradius/
    ├── clients.conf             # Configuração dos Access Points
    ├── mods-available/
    │   └── sql                  # Configuração do módulo SQL
    └── sites-available/
        └── default              # Configuração do site default
```

## 🎯 Próximos Passos

1. ✅ Configure os IPs reais dos seus Access Points no `clients.conf`
2. ✅ Teste a autenticação com `radtest`
3. ✅ Configure seus APs para usar o servidor RADIUS
4. ✅ Adicione usuários reais no banco de dados
5. ✅ Configure backup automático
6. ✅ Monitore os logs regularmente

## 🔒 Observações de Segurança

- **NUNCA** exponha a porta 8080 (Adminer) para a internet
- Use senhas fortes para todos os usuários
- Considere usar certificados SSL/TLS
- Mantenha backups regulares
- Em produção, considere usar senhas com hash (MD5, SHA1) ao invés de Cleartext-Password
- Limite o acesso ao servidor apenas à rede interna
