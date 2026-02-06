# Guia de Configuração de Access Points

Este guia mostra como configurar diferentes marcas de Access Points para usar o servidor RADIUS.

## 📋 Informações Necessárias

Antes de começar, você precisará:
- **IP do Servidor RADIUS**: O IP do servidor onde o Docker está rodando
- **Porta de Autenticação**: 1812
- **Porta de Accounting**: 1813
- **Shared Secret**: Definido no arquivo `clients.conf` (ex: SecretSharedKey123!)

---

## 1. Ubiquiti UniFi

### Via UniFi Controller

1. **Acesse o UniFi Controller** (geralmente em https://IP:8443)

2. **Vá em Settings → Profiles → RADIUS**

3. **Clique em "Create New RADIUS Profile"**

4. **Configure o perfil**:
   ```
   Profile Name: Servidor RADIUS Empresa
   
   Auth Servers:
   - IP Address: [IP_DO_SEU_SERVIDOR]
   - Port: 1812
   - Password: SecretSharedKey123!
   
   Accounting Servers:
   - IP Address: [IP_DO_SEU_SERVIDOR]
   - Port: 1813
   - Password: SecretSharedKey123!
   ```

5. **Criar/Editar Rede Wi-Fi**:
   - Vá em **Settings → WiFi**
   - Crie uma nova rede ou edite uma existente
   - **Security**: WPA2 Enterprise ou WPA3 Enterprise
   - **RADIUS Profile**: Selecione o perfil criado acima
   - Salve as configurações

6. **Adicione o UniFi no clients.conf**:
   ```
   client unifi-controller {
       ipaddr = 192.168.1.20
       secret = SecretSharedKey123!
       require_message_authenticator = yes
       nas_type = other
       shortname = unifi
   }
   ```

---

## 2. TP-Link EAP (Omada)

### Via Controlador Omada ou Interface Standalone

1. **Acesse a interface web** do AP ou Controlador

2. **Vá em Wireless → Wireless Settings**

3. **Selecione a rede/SSID** que deseja configurar

4. **Configure a segurança**:
   ```
   Security Mode: WPA2-Enterprise ou WPA-Enterprise
   Encryption: AES
   
   RADIUS Server:
   - IP Address: [IP_DO_SEU_SERVIDOR]
   - Port: 1812
   - Shared Secret: SecretSharedKey123!
   
   RADIUS Accounting (opcional):
   - IP Address: [IP_DO_SEU_SERVIDOR]
   - Port: 1813
   - Shared Secret: SecretSharedKey123!
   ```

5. **Aplique e salve**

6. **Adicione o TP-Link no clients.conf**:
   ```
   client tplink-ap {
       ipaddr = 192.168.1.30
       secret = SecretSharedKey123!
       require_message_authenticator = no
       nas_type = other
       shortname = tplink-ap
   }
   ```

---

## 3. Cisco (WLC - Wireless LAN Controller)

### Via WLC Interface

1. **Acesse o WLC** (geralmente https://IP)

2. **Vá em Security → RADIUS → Authentication**

3. **Adicione um novo servidor**:
   ```
   Server Index: (próximo disponível)
   Server Address: [IP_DO_SEU_SERVIDOR]
   Shared Secret: SecretSharedKey123!
   Port: 1812
   Server Status: Enabled
   ```

4. **Configure o Accounting** (Security → RADIUS → Accounting):
   ```
   Server Address: [IP_DO_SEU_SERVIDOR]
   Shared Secret: SecretSharedKey123!
   Port: 1813
   Server Status: Enabled
   ```

5. **Configure o WLAN**:
   - Vá em **WLANs**
   - Selecione ou crie um WLAN
   - **Security → Layer 2**:
     - Security: WPA+WPA2
     - Authentication Key Management: 802.1X
   - **AAA Servers**:
     - Selecione o servidor RADIUS criado

6. **Adicione o Cisco no clients.conf**:
   ```
   client cisco-wlc {
       ipaddr = 192.168.1.40
       secret = SecretSharedKey123!
       require_message_authenticator = yes
       nas_type = cisco
       shortname = cisco-wlc
   }
   ```

---

## 4. MikroTik

### Via WebFig ou WinBox

1. **Acesse o MikroTik**

2. **Configure o RADIUS** (Radius):
   ```
   Add New:
   - Service: wireless
   - Address: [IP_DO_SEU_SERVIDOR]
   - Secret: SecretSharedKey123!
   - Authentication Port: 1812
   - Accounting Port: 1813
   ```

3. **Configure o Interface Wireless**:
   - Vá em **Wireless → Security Profiles**
   - Crie um novo perfil:
     ```
     Name: radius-profile
     Mode: dynamic keys
     Authentication Types: WPA2 EAP
     Unicast Ciphers: aes ccm
     Group Ciphers: aes ccm
     ```

4. **Aplique ao Interface**:
   - Vá em **Wireless → Interfaces**
   - Selecione o interface
   - Security Profile: radius-profile

5. **Adicione o MikroTik no clients.conf**:
   ```
   client mikrotik-ap {
       ipaddr = 192.168.1.50
       secret = SecretSharedKey123!
       require_message_authenticator = yes
       nas_type = other
       shortname = mikrotik
   }
   ```

---

## 5. D-Link

### Via Interface Web

1. **Acesse a interface web** do AP

2. **Vá em Wireless → Security**

3. **Configure**:
   ```
   Authentication: WPA2-Enterprise
   Cipher Type: AES
   
   RADIUS Server Settings:
   - Primary RADIUS Server: [IP_DO_SEU_SERVIDOR]
   - RADIUS Port: 1812
   - Shared Secret: SecretSharedKey123!
   
   RADIUS Accounting (se disponível):
   - Accounting Server: [IP_DO_SEU_SERVIDOR]
   - Accounting Port: 1813
   - Shared Secret: SecretSharedKey123!
   ```

4. **Adicione o D-Link no clients.conf**:
   ```
   client dlink-ap {
       ipaddr = 192.168.1.60
       secret = SecretSharedKey123!
       require_message_authenticator = no
       nas_type = other
       shortname = dlink-ap
   }
   ```

---

## 6. Aruba (Instant AP)

### Via Aruba Instant Interface

1. **Acesse o Aruba Instant** (geralmente https://IP)

2. **Vá em Configuration → Authentication**

3. **Adicione servidor RADIUS**:
   ```
   Server Name: RADIUS-Empresa
   IP Address: [IP_DO_SEU_SERVIDOR]
   Auth Port: 1812
   Accounting Port: 1813
   Shared Secret: SecretSharedKey123!
   ```

4. **Configure o SSID** (Configuration → WLAN):
   ```
   SSID: Empresa-WiFi
   Type: Employee
   Security Level: WPA2-Enterprise
   Authentication Servers: RADIUS-Empresa
   ```

5. **Adicione o Aruba no clients.conf**:
   ```
   client aruba-instant {
       ipaddr = 192.168.1.70
       secret = SecretSharedKey123!
       require_message_authenticator = yes
       nas_type = other
       shortname = aruba
   }
   ```

---

## 🔧 Configuração Genérica (Qualquer AP)

Para APs não listados acima, use esta configuração genérica:

### No Access Point:
1. Procure por **802.1X**, **WPA Enterprise** ou **RADIUS** nas configurações
2. Configure:
   - **Tipo de Segurança**: WPA2-Enterprise ou WPA3-Enterprise
   - **Servidor RADIUS**: IP do seu servidor
   - **Porta**: 1812
   - **Shared Secret**: A mesma senha do clients.conf
   - **Accounting** (opcional): Porta 1813

### No clients.conf:
```
client nome-do-seu-ap {
    ipaddr = [IP_DO_AP]
    secret = [SENHA_COMPARTILHADA]
    require_message_authenticator = no
    nas_type = other
    shortname = nome-curto
}
```

---

## ✅ Checklist de Configuração

- [ ] IP do servidor RADIUS está acessível do AP
- [ ] Portas 1812 e 1813 UDP estão abertas no firewall
- [ ] Shared Secret é o mesmo no AP e no clients.conf
- [ ] IP do AP está adicionado no clients.conf
- [ ] Containers Docker estão rodando
- [ ] Testou autenticação com radtest
- [ ] Reiniciou o container FreeRADIUS após alterar clients.conf

---

## 🧪 Teste de Conectividade

Antes de configurar os usuários, teste se o AP consegue alcançar o servidor:

```bash
# No servidor, teste se as portas estão abertas
sudo netstat -ulnp | grep -E "1812|1813"

# Teste com radtest (substitua valores)
radtest usuario senha IP_SERVIDOR 1812 shared_secret

# Ver logs em tempo real
docker-compose logs -f freeradius
```

---

## 🔍 Troubleshooting

### AP não conecta ao RADIUS:
1. Verifique se o IP está correto
2. Verifique se o shared secret é o mesmo
3. Verifique firewall do servidor
4. Veja os logs: `docker-compose logs freeradius`

### Autenticação falha:
1. Verifique se o usuário existe no banco
2. Verifique se a senha está correta
3. Veja os logs de autenticação no banco de dados
4. Execute o FreeRADIUS em modo debug

### Accounting não funciona:
1. Verifique se a porta 1813 está aberta
2. Confirme que o accounting está habilitado no AP
3. Verifique a tabela `radacct` no banco

---

## 📞 Suporte Adicional

Para marcas específicas não listadas, consulte:
- Documentação do fabricante
- Procure por "802.1X configuration" ou "WPA Enterprise"
- Entre em contato com o suporte técnico do fabricante

Após configurar, sempre teste com um usuário de teste antes de implantar em produção!
