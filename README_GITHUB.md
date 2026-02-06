# 🔐 Servidor RADIUS com Docker e PostgreSQL

Sistema completo de autenticação RADIUS para controlar acessos Wi-Fi corporativos através de Access Points.

![Docker](https://img.shields.io/badge/Docker-Ready-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue)
![FreeRADIUS](https://img.shields.io/badge/FreeRADIUS-Latest-green)

## 📋 Características

- ✅ **FreeRADIUS** - Servidor de autenticação robusto
- ✅ **PostgreSQL** - Banco de dados relacional para gerenciar usuários
- ✅ **Adminer** - Interface web para administração do banco
- ✅ **Docker Compose** - Deploy simplificado
- ✅ **Suporte 50-200 usuários** - Ideal para pequenas e médias empresas
- ✅ **Grupos de usuários** - Administradores, usuários comuns, etc.
- ✅ **Logs completos** - Accounting e autenticação
- ✅ **Backup automatizado** - Scripts incluídos

## 🚀 Quick Start

### Método 1: Docker Compose Local

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/radius-server.git
cd radius-server

# Configure as variáveis de ambiente
cp .env.example .env
nano .env  # Edite as senhas

# Inicie os containers
docker-compose up -d

# Verifique o status
docker-compose ps
```

### Método 2: Deploy no EasyPanel

Siga o guia completo em [DEPLOY_EASYPANEL.md](DEPLOY_EASYPANEL.md)

## 📚 Documentação

- 📘 [README.md](README.md) - Documentação completa
- 🔧 [CONFIGURACAO_APS.md](CONFIGURACAO_APS.md) - Como configurar Access Points
- 🚀 [DEPLOY_EASYPANEL.md](DEPLOY_EASYPANEL.md) - Deploy no EasyPanel

## 🌐 Portas Utilizadas

| Serviço | Porta | Protocolo | Descrição |
|---------|-------|-----------|-----------|
| FreeRADIUS Auth | 1812 | UDP | Autenticação |
| FreeRADIUS Acct | 1813 | UDP | Accounting |
| Adminer | 8080 | TCP | Interface Web |
| PostgreSQL | 5432 | TCP | Banco (interno) |

## 🔐 Configuração Inicial

### 1. Editar variáveis de ambiente

```bash
cp .env.example .env
nano .env
```

**IMPORTANTE**: Altere a senha do PostgreSQL!

### 2. Configurar Access Points

Edite `freeradius/clients.conf` e adicione seus APs:

```
client meu-ap {
    ipaddr = 192.168.1.10
    secret = SenhaSecreta123!
    require_message_authenticator = yes
    nas_type = other
    shortname = meu-ap
}
```

### 3. Iniciar serviços

```bash
docker-compose up -d
```

## 👥 Gerenciar Usuários

### Via Adminer (Web Interface)

1. Acesse: `http://seu-ip:8080`
2. Login com credenciais do PostgreSQL
3. Gerencie usuários nas tabelas

### Via SQL

```bash
# Conectar ao banco
docker exec -it radius-postgres psql -U radius -d radius

# Adicionar usuário
INSERT INTO usuarios_empresa (username, nome_completo, email, departamento) 
VALUES ('joao', 'João Silva', 'joao@empresa.com', 'TI');

INSERT INTO radcheck (username, attribute, op, value) 
VALUES ('joao', 'Cleartext-Password', ':=', 'senha123');

INSERT INTO radusergroup (username, groupname, priority) 
VALUES ('joao', 'usuarios_wifi', 1);
```

### Via Script Python

```bash
python3 gerenciar_usuarios.py
```

## 🧪 Testar Autenticação

```bash
# Instalar ferramenta de teste
sudo apt install freeradius-utils

# Testar usuário
radtest admin "Admin@123" localhost 1812 testing123

# Resposta esperada:
# Received Access-Accept
```

## 📊 Monitoramento

### Ver logs

```bash
# Logs do FreeRADIUS
docker-compose logs -f freeradius

# Logs de autenticação (últimas 20)
docker exec -it radius-postgres psql -U radius -d radius -c "
SELECT username, reply, authdate 
FROM radpostauth 
ORDER BY authdate DESC 
LIMIT 20;
"
```

### Sessões ativas

```bash
docker exec -it radius-postgres psql -U radius -d radius -c "
SELECT username, nasipaddress, acctstarttime 
FROM radacct 
WHERE acctstoptime IS NULL;
"
```

## 💾 Backup

### Manual

```bash
# Executar script de backup
./backup.sh
```

### Automático (Cron)

```bash
# Adicionar ao crontab
crontab -e

# Backup diário às 2h da manhã
0 2 * * * /caminho/para/radius-server/backup.sh
```

## 🔧 Marcas de Access Points Suportadas

- ✅ Ubiquiti UniFi
- ✅ TP-Link EAP/Omada
- ✅ Cisco (WLC)
- ✅ MikroTik
- ✅ D-Link
- ✅ Aruba Instant
- ✅ Qualquer AP com suporte 802.1X

Consulte [CONFIGURACAO_APS.md](CONFIGURACAO_APS.md) para instruções específicas.

## 📁 Estrutura do Projeto

```
radius-server/
├── docker-compose.yml           # Orquestração dos containers
├── init-db.sql                  # Schema inicial do banco
├── .env.example                 # Exemplo de variáveis de ambiente
├── backup.sh                    # Script de backup
├── gerenciar_usuarios.py        # Gerenciador de usuários CLI
├── install.sh                   # Instalação automatizada
├── README.md                    # Este arquivo
├── CONFIGURACAO_APS.md          # Guia de configuração de APs
├── DEPLOY_EASYPANEL.md          # Deploy no EasyPanel
└── freeradius/
    ├── clients.conf             # Configuração dos APs
    ├── mods-available/
    │   └── sql                  # Configuração do módulo SQL
    └── sites-available/
        └── default              # Configuração do site default
```

## 🛡️ Segurança

- ✅ Senhas nunca em texto plano no código
- ✅ Variáveis de ambiente para configurações sensíveis
- ✅ `.gitignore` configurado para não commitar senhas
- ✅ Recomendação de firewall para portas específicas
- ⚠️ **IMPORTANTE**: Nunca exponha o Adminer publicamente sem autenticação

## 🐛 Troubleshooting

### FreeRADIUS não inicia

```bash
# Ver logs
docker-compose logs freeradius

# Testar configuração
docker exec freeradius-server radiusd -XC
```

### Porta UDP não funciona

```bash
# Verificar se a porta está aberta
sudo netstat -ulnp | grep 1812

# Liberar no firewall
sudo ufw allow 1812/udp
sudo ufw allow 1813/udp
```

### Autenticação falha

```bash
# Verificar se usuário existe
docker exec -it radius-postgres psql -U radius -d radius -c "
SELECT * FROM radcheck WHERE username = 'nome_usuario';
"

# Ver logs de autenticação
docker exec -it radius-postgres psql -U radius -d radius -c "
SELECT * FROM radpostauth ORDER BY authdate DESC LIMIT 10;
"
```

## 📝 To-Do / Roadmap

- [ ] Interface web completa para gerenciamento
- [ ] Suporte a 2FA/MFA
- [ ] Integração com LDAP/Active Directory
- [ ] Dashboard de estatísticas
- [ ] API REST para gerenciamento
- [ ] Suporte a certificados SSL/TLS

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para:

1. Fork o projeto
2. Criar uma branch (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abrir um Pull Request

## 📄 Licença

Este projeto é livre para uso comercial e pessoal.

## 📞 Suporte

- 📖 [Documentação Completa](README.md)
- 🔧 [Configuração de APs](CONFIGURACAO_APS.md)
- 🚀 [Deploy EasyPanel](DEPLOY_EASYPANEL.md)

## ⭐ Se este projeto foi útil, deixe uma estrela!

---

Desenvolvido com ❤️ para facilitar a autenticação Wi-Fi corporativa
