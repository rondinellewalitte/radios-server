# 🚀 Guia Rápido - Subir para o Git e Deploy no EasyPanel

## 📦 Passo 1: Preparar o Repositório Git

```bash
# 1. Extrair o ZIP
unzip radius-server-easypanel.zip
cd radius-server

# 2. Inicializar Git
git init

# 3. Adicionar arquivos
git add .

# 4. Primeiro commit
git commit -m "Initial commit - Servidor RADIUS com Docker e PostgreSQL"

# 5. Criar repositório no GitHub/GitLab
# Vá em github.com ou gitlab.com e crie um repositório novo
# Exemplo: radius-server

# 6. Conectar ao repositório remoto (substitua com sua URL)
git remote add origin https://github.com/SEU_USUARIO/radius-server.git

# 7. Criar branch main e fazer push
git branch -M main
git push -u origin main
```

## 🎯 Passo 2: Deploy no EasyPanel

### 2.1 No EasyPanel

1. **Login** no seu EasyPanel
2. Clique em **"New Project"** ou **"Create Project"**
3. Configure:
   - **Name**: `radius-server`
   - **Type**: `Docker Compose` ou `Git`

### 2.2 Conectar Git

1. Em **Source**, selecione **Git**
2. Cole a URL do repositório:
   ```
   https://github.com/SEU_USUARIO/radius-server.git
   ```
3. Se privado, adicione credenciais

### 2.3 Configurar

1. **Branch**: `main`
2. **Docker Compose File**: `docker-compose.yml`

### 2.4 Variáveis de Ambiente

Adicione em **Environment Variables**:

```env
POSTGRES_DB=radius
POSTGRES_USER=radius
POSTGRES_PASSWORD=ALTERE_ESTA_SENHA_AQUI_123!
RADIUS_AUTH_PORT=1812
RADIUS_ACCT_PORT=1813
ADMINER_PORT=8080
TZ=America/Sao_Paulo
```

**⚠️ IMPORTANTE**: Altere a senha do PostgreSQL!

### 2.5 Deploy

1. Clique em **Deploy** ou **Start**
2. Aguarde a build
3. Verifique os logs

## ✅ Passo 3: Verificar

```bash
# Via SSH no servidor EasyPanel
docker ps

# Você deve ver 3 containers:
# - radius-postgres
# - freeradius-server
# - radius-adminer
```

## 🌐 Passo 4: Acessar

- **Adminer**: `http://SEU_IP:8080`
- **Servidor RADIUS**: `SEU_IP:1812` (UDP)

## 🔧 Passo 5: Configurar APs

1. Edite localmente: `freeradius/clients.conf`
2. Adicione seus Access Points
3. Commit e push:
   ```bash
   git add freeradius/clients.conf
   git commit -m "Adicionar Access Points"
   git push
   ```
4. EasyPanel fará redeploy automaticamente

## 🧪 Passo 6: Testar

```bash
# Instalar no seu PC
sudo apt install freeradius-utils

# Testar
radtest admin "Admin@123" SEU_IP 1812 testing123

# Esperado: Access-Accept
```

## 📋 Próximos Passos

1. ✅ Configurar seus APs reais
2. ✅ Adicionar usuários no Adminer
3. ✅ Testar conexão Wi-Fi
4. ✅ Configurar backup

---

## 🆘 Precisa de Ajuda?

Consulte a documentação completa:
- [DEPLOY_EASYPANEL.md](DEPLOY_EASYPANEL.md) - Guia completo
- [CONFIGURACAO_APS.md](CONFIGURACAO_APS.md) - Configurar Access Points
- [CHECKLIST.md](CHECKLIST.md) - Checklist de deploy
- [README.md](README.md) - Documentação geral

---

**Pronto!** Seu servidor RADIUS está rodando no EasyPanel! 🎉
