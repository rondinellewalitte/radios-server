# 🚀 Deploy no EasyPanel - Guia Completo

Este guia mostra como fazer deploy do servidor RADIUS no EasyPanel.

## 📋 Pré-requisitos

- Conta no EasyPanel
- Servidor VPS com EasyPanel instalado
- Acesso SSH ao servidor (opcional, para testes)
- Git instalado localmente

---

## 🔧 Passo 1: Preparar o Repositório Git

### 1.1 Criar repositório no GitHub/GitLab

```bash
# No seu computador local
cd radius-server

# Inicializar repositório Git
git init
git add .
git commit -m "Initial commit - Servidor RADIUS com Docker"

# Conectar ao GitHub (substitua com seu repositório)
git remote add origin https://github.com/seu-usuario/radius-server.git
git branch -M main
git push -u origin main
```

### 1.2 Arquivos importantes para commit

Certifique-se de que estes arquivos estão no repositório:
- ✅ `docker-compose.yml`
- ✅ `init-db.sql`
- ✅ `freeradius/clients.conf`
- ✅ `freeradius/mods-available/sql`
- ✅ `freeradius/sites-available/default`
- ✅ `.env.example`
- ✅ `README.md`

**NÃO COMMITE** o arquivo `.env` com senhas reais!

---

## 🎯 Passo 2: Configurar no EasyPanel

### 2.1 Criar novo projeto

1. Acesse seu **EasyPanel**
2. Clique em **"Create Project"** ou **"New Project"**
3. Configure:
   - **Project Name**: `radius-server` ou outro nome
   - **Type**: Docker Compose

### 2.2 Conectar repositório Git

1. Em **Source**, selecione **Git**
2. Cole a URL do seu repositório:
   ```
   https://github.com/seu-usuario/radius-server.git
   ```
3. Se o repositório for privado, adicione as credenciais

### 2.3 Configurar Build

1. **Branch**: `main` (ou a branch que você usa)
2. **Docker Compose File**: `docker-compose.yml`
3. **Auto Deploy**: Ative se quiser deploy automático ao dar push

---

## 🔐 Passo 3: Configurar Variáveis de Ambiente

No EasyPanel, vá em **Environment Variables** e adicione:

```env
POSTGRES_DB=radius
POSTGRES_USER=radius
POSTGRES_PASSWORD=SuaSenhaSegura123!MudeIsso
RADIUS_AUTH_PORT=1812
RADIUS_ACCT_PORT=1813
ADMINER_PORT=8080
TZ=America/Sao_Paulo
```

**IMPORTANTE**: 
- ✅ Altere `POSTGRES_PASSWORD` para uma senha forte
- ✅ Esta senha será usada pelo PostgreSQL e pelo FreeRADIUS

---

## 🌐 Passo 4: Configurar Portas e Networking

### 4.1 Expor portas UDP (importante!)

O EasyPanel pode ter limitações com portas UDP. Você tem duas opções:

**Opção A: Via EasyPanel UI**
1. Vá em **Ports**
2. Adicione as portas:
   - `1812/udp` → RADIUS Authentication
   - `1813/udp` → RADIUS Accounting
   - `8080/tcp` → Adminer (interface web)

**Opção B: Via iptables no servidor (mais confiável)**

Conecte via SSH ao servidor do EasyPanel:

```bash
# Liberar portas UDP no firewall
sudo ufw allow 1812/udp
sudo ufw allow 1813/udp
sudo ufw allow 8080/tcp

# Verificar regras
sudo ufw status
```

### 4.2 Obter IP público do servidor

```bash
# No servidor EasyPanel, execute:
curl ifconfig.me
```

Anote este IP, você precisará dele para configurar os Access Points.

---

## 🚀 Passo 5: Deploy

1. No EasyPanel, clique em **Deploy** ou **Start**
2. Aguarde o build e inicialização dos containers
3. Acompanhe os logs para verificar se tudo iniciou corretamente

### Verificar status dos containers

No EasyPanel, vá em **Logs** ou **Console** e execute:

```bash
docker-compose ps
```

Você deve ver 3 containers rodando:
- ✅ `radius-postgres`
- ✅ `freeradius-server`
- ✅ `radius-adminer`

---

## 🧪 Passo 6: Testar a Instalação

### 6.1 Acessar o Adminer

1. Abra o navegador: `http://SEU_IP_PUBLICO:8080`
2. Faça login:
   - **Sistema**: PostgreSQL
   - **Servidor**: postgres
   - **Usuário**: radius
   - **Senha**: A senha que você configurou
   - **Base de dados**: radius

3. Verifique se as tabelas foram criadas:
   - `usuarios_empresa`
   - `radcheck`
   - `radreply`
   - `radacct`
   - etc.

### 6.2 Testar autenticação

**Via Console do EasyPanel:**

```bash
# Entrar no container do FreeRADIUS
docker exec -it freeradius-server bash

# Testar usuário de exemplo
radtest admin "Admin@123" localhost 1812 testing123

# Você deve ver:
# Received Access-Accept
```

**Via seu computador (se tiver freeradius-utils instalado):**

```bash
radtest admin "Admin@123" SEU_IP_PUBLICO 1812 testing123
```

---

## 📝 Passo 7: Configurar Access Points

### 7.1 Editar clients.conf

Você precisa adicionar os IPs dos seus Access Points. Duas formas de fazer isso:

**Opção A: Via Git (recomendado)**

```bash
# No seu computador local
cd radius-server
nano freeradius/clients.conf

# Adicione seus APs (exemplo):
client ap-escritorio-1 {
    ipaddr = 192.168.1.10
    secret = MeuSecretSeguro123!
    require_message_authenticator = yes
    nas_type = other
    shortname = ap-escritorio-1
}

# Commit e push
git add freeradius/clients.conf
git commit -m "Adicionar Access Points"
git push

# O EasyPanel fará redeploy automaticamente (se configurado)
```

**Opção B: Via Console do EasyPanel**

```bash
# Editar diretamente no container
docker exec -it freeradius-server vi /etc/freeradius/clients.conf

# Após editar, reiniciar FreeRADIUS
docker-compose restart freeradius
```

### 7.2 Configurar os APs

Siga o guia `CONFIGURACAO_APS.md` e configure cada AP com:
- **IP do RADIUS**: IP público do seu servidor EasyPanel
- **Porta**: 1812 (auth) e 1813 (accounting)
- **Shared Secret**: O mesmo configurado no `clients.conf`

---

## 📊 Passo 8: Gerenciar Usuários

### Via Adminer (Interface Web)

1. Acesse: `http://SEU_IP:8080`
2. Vá na tabela `radcheck`
3. Clique em **"Insert"** para adicionar novo usuário:
   ```
   username: joao.silva
   attribute: Cleartext-Password
   op: :=
   value: SenhaDoJoao123
   ```

### Via SQL direto

No Console do EasyPanel:

```bash
# Conectar ao PostgreSQL
docker exec -it radius-postgres psql -U radius -d radius

# Adicionar usuário
INSERT INTO usuarios_empresa (username, nome_completo, email, departamento) 
VALUES ('maria.souza', 'Maria Souza', 'maria@empresa.com', 'RH');

INSERT INTO radcheck (username, attribute, op, value) 
VALUES ('maria.souza', 'Cleartext-Password', ':=', 'SenhaMaria123');

INSERT INTO radusergroup (username, groupname, priority) 
VALUES ('maria.souza', 'usuarios_wifi', 1);

# Verificar
SELECT * FROM v_usuarios_ativos;
```

### Via Script Python (se instalado)

```bash
# Instalar dependências (se necessário)
docker exec -it freeradius-server apk add python3 py3-pip
docker exec -it freeradius-server pip3 install psycopg2-binary

# Executar script
docker exec -it freeradius-server python3 /app/gerenciar_usuarios.py
```

---

## 🔒 Segurança no EasyPanel

### 1. Proteger o Adminer

O Adminer **NÃO DEVE** ficar exposto publicamente!

**Opção A: Usar proxy reverso com autenticação**

No EasyPanel, configure um proxy reverso com Basic Auth para o Adminer.

**Opção B: Bloquear acesso externo**

```bash
# Via firewall, permitir apenas IPs específicos
sudo ufw delete allow 8080/tcp
sudo ufw allow from SEU_IP_ESCRITORIO to any port 8080
```

**Opção C: Usar túnel SSH**

```bash
# Do seu computador
ssh -L 8080:localhost:8080 usuario@servidor-easypanel

# Depois acesse: http://localhost:8080
```

### 2. Backup Automático

Configure backup no EasyPanel ou via cron:

```bash
# Editar crontab no servidor
crontab -e

# Adicionar (backup diário às 2h)
0 2 * * * docker exec radius-postgres pg_dump -U radius radius | gzip > /backup/radius_$(date +\%Y\%m\%d).sql.gz
```

---

## 📈 Monitoramento

### Ver logs do FreeRADIUS

No EasyPanel Console:

```bash
# Logs em tempo real
docker-compose logs -f freeradius

# Últimas 100 linhas
docker-compose logs --tail=100 freeradius
```

### Verificar autenticações

```bash
docker exec -it radius-postgres psql -U radius -d radius -c "
SELECT username, reply, authdate, nasipaddress 
FROM radpostauth 
ORDER BY authdate DESC 
LIMIT 20;
"
```

### Sessões ativas

```bash
docker exec -it radius-postgres psql -U radius -d radius -c "
SELECT username, nasipaddress, acctstarttime, acctsessiontime 
FROM radacct 
WHERE acctstoptime IS NULL;
"
```

---

## 🔄 Atualizações e Manutenção

### Atualizar configurações

```bash
# No seu computador
git pull
# Fazer alterações
git add .
git commit -m "Atualização de configuração"
git push

# EasyPanel fará redeploy automaticamente (se configurado)
```

### Reiniciar serviços

```bash
# Reiniciar tudo
docker-compose restart

# Reiniciar apenas FreeRADIUS
docker-compose restart freeradius

# Reiniciar apenas PostgreSQL
docker-compose restart postgres
```

### Limpar e recriar (CUIDADO: apaga dados!)

```bash
docker-compose down -v
docker-compose up -d
```

---

## ⚠️ Troubleshooting

### FreeRADIUS não inicia

```bash
# Ver logs detalhados
docker-compose logs freeradius

# Testar configuração
docker exec freeradius-server radiusd -XC
```

### Portas UDP não funcionam

1. Verifique firewall do servidor
2. Verifique configuração de rede do EasyPanel
3. Teste com `nc` ou `nmap`:
   ```bash
   nmap -sU -p 1812 SEU_IP
   ```

### Banco não conecta

```bash
# Verificar se PostgreSQL está rodando
docker-compose ps postgres

# Testar conexão
docker exec -it radius-postgres psql -U radius -d radius -c "SELECT 1;"
```

---

## 📞 Checklist de Deploy

- [ ] Repositório Git criado e configurado
- [ ] Variáveis de ambiente configuradas no EasyPanel
- [ ] Senhas padrão alteradas
- [ ] Portas UDP 1812/1813 liberadas no firewall
- [ ] Containers iniciaram com sucesso
- [ ] Adminer acessível e funcionando
- [ ] Teste de autenticação com `radtest` passou
- [ ] Access Points adicionados no `clients.conf`
- [ ] APs configurados com IP e secret corretos
- [ ] Teste de autenticação real via Wi-Fi funcionou
- [ ] Backup configurado
- [ ] Adminer protegido/restrito

---

## 🎯 Próximos Passos

1. Configure seus Access Points reais
2. Adicione usuários da empresa
3. Configure backup automático
4. Monitore logs regularmente
5. Configure alertas (opcional)

Seu servidor RADIUS está pronto para produção no EasyPanel! 🚀
