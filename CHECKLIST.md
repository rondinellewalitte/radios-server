# ✅ Checklist de Deploy - Servidor RADIUS

Use este checklist para garantir que nada foi esquecido no deploy.

## 📦 Antes de Subir para o Git

- [ ] Revisei todos os arquivos de configuração
- [ ] `.env` está no `.gitignore` (senhas não vão para o Git)
- [ ] `.env.example` está preenchido com valores de exemplo
- [ ] Arquivos de configuração sensíveis estão protegidos
- [ ] README atualizado com instruções claras
- [ ] Testei localmente com `docker-compose up`

## 🚀 Deploy no EasyPanel

### Preparação
- [ ] Repositório Git criado (GitHub/GitLab)
- [ ] Código commitado e pushado para o Git
- [ ] EasyPanel instalado e funcionando no VPS
- [ ] Acesso SSH ao servidor (para troubleshooting)

### Configuração no EasyPanel
- [ ] Projeto criado no EasyPanel
- [ ] Repositório Git conectado
- [ ] Branch correta selecionada (main/master)
- [ ] Variáveis de ambiente configuradas:
  - [ ] `POSTGRES_DB`
  - [ ] `POSTGRES_USER`
  - [ ] `POSTGRES_PASSWORD` (ALTERADA da padrão!)
  - [ ] `RADIUS_AUTH_PORT`
  - [ ] `RADIUS_ACCT_PORT`
  - [ ] `ADMINER_PORT`
  - [ ] `TZ`

### Portas e Networking
- [ ] Porta 1812/UDP liberada no firewall do servidor
- [ ] Porta 1813/UDP liberada no firewall do servidor
- [ ] Porta 8080/TCP liberada (Adminer) ou restrita a IPs específicos
- [ ] IP público do servidor anotado

### Deploy
- [ ] Deploy realizado com sucesso
- [ ] Containers iniciaram (postgres, freeradius, adminer)
- [ ] Logs verificados sem erros críticos
- [ ] PostgreSQL aceitando conexões
- [ ] FreeRADIUS iniciado sem erros

## 🧪 Testes Pós-Deploy

### Teste 1: Adminer
- [ ] Adminer acessível em `http://IP:8080`
- [ ] Login no Adminer funcionando
- [ ] Tabelas criadas no banco de dados:
  - [ ] `usuarios_empresa`
  - [ ] `radcheck`
  - [ ] `radreply`
  - [ ] `radacct`
  - [ ] `radpostauth`
  - [ ] `radusergroup`
- [ ] Usuários de exemplo existem no banco

### Teste 2: Autenticação RADIUS
- [ ] Teste com radtest funcionou:
  ```bash
  radtest admin "Admin@123" IP_SERVIDOR 1812 testing123
  ```
- [ ] Resposta: `Access-Accept` recebida
- [ ] Log de autenticação registrado na tabela `radpostauth`

### Teste 3: Portas UDP
- [ ] Porta 1812/UDP respondendo:
  ```bash
  nmap -sU -p 1812 IP_SERVIDOR
  ```
- [ ] Porta 1813/UDP respondendo

## 🔧 Configuração dos Access Points

### Preparação
- [ ] Lista de Access Points com IPs anotada
- [ ] Shared secrets definidos (senhas fortes)
- [ ] Arquivo `freeradius/clients.conf` editado localmente
- [ ] Mudanças commitadas e pushadas para o Git
- [ ] Redeploy feito no EasyPanel (ou container reiniciado)

### Por Access Point
Para cada AP, marque quando completar:

**AP #1: __________________**
- [ ] IP adicionado no `clients.conf`
- [ ] AP configurado com IP do servidor RADIUS
- [ ] Porta 1812 configurada
- [ ] Shared secret configurado (igual ao clients.conf)
- [ ] Tipo de segurança: WPA2-Enterprise
- [ ] Teste de conexão realizado
- [ ] Usuário teste conseguiu conectar

**AP #2: __________________**
- [ ] IP adicionado no `clients.conf`
- [ ] AP configurado com IP do servidor RADIUS
- [ ] Porta 1812 configurada
- [ ] Shared secret configurado
- [ ] Tipo de segurança: WPA2-Enterprise
- [ ] Teste de conexão realizado
- [ ] Usuário teste conseguiu conectar

**AP #3: __________________**
- [ ] IP adicionado no `clients.conf`
- [ ] AP configurado
- [ ] Teste realizado

*(Adicione mais conforme necessário)*

## 👥 Usuários

### Usuários de Teste
- [ ] Usuário teste criado
- [ ] Teste de autenticação via Wi-Fi funcionou
- [ ] Logs de acesso registrados

### Usuários Reais
- [ ] Planilha de usuários preparada
- [ ] Usuários criados no sistema:
  - [ ] Usuários criados em `usuarios_empresa`
  - [ ] Senhas criadas em `radcheck`
  - [ ] Usuários associados a grupos em `radusergroup`
- [ ] Senhas enviadas aos usuários de forma segura
- [ ] Instruções de conexão enviadas aos usuários

## 🔒 Segurança

- [ ] Senha padrão do PostgreSQL alterada
- [ ] Adminer protegido (firewall, auth, ou túnel SSH)
- [ ] Portas UDP expostas apenas para rede necessária
- [ ] Shared secrets dos APs são senhas fortes
- [ ] `.env` nunca foi commitado para o Git
- [ ] Backup configurado e testado
- [ ] Logs sendo monitorados

## 💾 Backup e Recuperação

- [ ] Script de backup testado:
  ```bash
  ./backup.sh
  ```
- [ ] Backup automático configurado (cron ou similar)
- [ ] Teste de restauração realizado
- [ ] Backups sendo armazenados em local seguro
- [ ] Política de retenção definida (ex: 30 dias)

## 📊 Monitoramento

- [ ] Acesso aos logs configurado
- [ ] Comando para ver logs salvo:
  ```bash
  docker-compose logs -f freeradius
  ```
- [ ] Query para ver autenticações recentes salva
- [ ] Query para ver sessões ativas salva
- [ ] Alertas configurados (opcional)

## 📝 Documentação

- [ ] README atualizado com informações do deploy
- [ ] IPs e credenciais documentados em local seguro
- [ ] Instruções para usuários finais criadas
- [ ] Contato de suporte definido
- [ ] Procedimentos de emergência documentados

## 🎓 Treinamento

- [ ] Equipe de TI treinada para:
  - [ ] Adicionar usuários
  - [ ] Resetar senhas
  - [ ] Ver logs
  - [ ] Troubleshooting básico
- [ ] Usuários finais instruídos sobre:
  - [ ] Como conectar ao Wi-Fi
  - [ ] Configurações necessárias
  - [ ] Quem contatar em caso de problemas

## 📞 Pós-Deploy

- [ ] Monitoramento ativo nos primeiros dias
- [ ] Feedback dos usuários coletado
- [ ] Problemas identificados e resolvidos
- [ ] Performance avaliada
- [ ] Documentação atualizada com aprendizados

## 🎉 Conclusão

- [ ] Sistema em produção e estável
- [ ] Todos os usuários conectando com sucesso
- [ ] Logs sendo gerados corretamente
- [ ] Backup funcionando
- [ ] Equipe capacitada
- [ ] Documentação completa

---

**Data de Deploy:** __________________

**Responsável:** __________________

**Versão:** __________________

---

## 📝 Notas Adicionais

Use este espaço para anotar observações específicas do seu deploy:

```
[Suas notas aqui]
```
