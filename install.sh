#!/bin/bash

# Script de Instalação Rápida do Servidor RADIUS
# Execute este script para configurar rapidamente o servidor

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║    INSTALAÇÃO DO SERVIDOR RADIUS COM DOCKER               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Este script precisa ser executado como root (use sudo)"
    exit 1
fi

# 1. Verificar e instalar Docker
echo "🔍 Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo "📦 Docker não encontrado. Instalando..."
    apt update
    apt install -y docker.io docker-compose
    systemctl enable docker
    systemctl start docker
    echo "✓ Docker instalado com sucesso"
else
    echo "✓ Docker já está instalado"
fi

# 2. Verificar Docker Compose
echo "🔍 Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Instalando Docker Compose..."
    apt install -y docker-compose
    echo "✓ Docker Compose instalado"
else
    echo "✓ Docker Compose já está instalado"
fi

# 3. Criar diretórios necessários
echo "📁 Criando estrutura de diretórios..."
mkdir -p /backup/radius
mkdir -p logs

# 4. Configurar permissões
echo "🔒 Configurando permissões..."
chmod 644 freeradius/clients.conf
chmod 644 freeradius/mods-available/sql
chmod 644 freeradius/sites-available/default
chmod 644 init-db.sql
chmod +x backup.sh
chmod +x gerenciar_usuarios.py

# 5. Perguntar configurações básicas
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "CONFIGURAÇÃO INICIAL"
echo "═══════════════════════════════════════════════════════════"
echo ""

read -p "Deseja alterar a senha padrão do PostgreSQL? (s/N): " ALTERAR_SENHA
if [[ $ALTERAR_SENHA =~ ^[Ss]$ ]]; then
    read -sp "Digite a nova senha: " NOVA_SENHA
    echo ""
    # Atualizar docker-compose.yml
    sed -i "s/POSTGRES_PASSWORD: RadiusSecurePass123!/POSTGRES_PASSWORD: $NOVA_SENHA/" docker-compose.yml
    # Atualizar configuração SQL
    sed -i "s/password = \"RadiusSecurePass123!\"/password = \"$NOVA_SENHA\"/" freeradius/mods-available/sql
    echo "✓ Senha alterada com sucesso"
fi

echo ""
read -p "Qual é o IP deste servidor? (deixe em branco para auto-detectar): " IP_SERVIDOR
if [ -z "$IP_SERVIDOR" ]; then
    IP_SERVIDOR=$(hostname -I | awk '{print $1}')
    echo "IP detectado: $IP_SERVIDOR"
fi

# 6. Iniciar containers
echo ""
echo "🚀 Iniciando containers Docker..."
docker-compose down 2>/dev/null || true
docker-compose up -d

# 7. Aguardar inicialização
echo "⏳ Aguardando containers inicializarem..."
sleep 10

# 8. Verificar status
echo ""
echo "📊 Status dos containers:"
docker-compose ps

# 9. Testar conexão com banco
echo ""
echo "🧪 Testando conexão com banco de dados..."
sleep 5
if docker exec radius-postgres psql -U radius -d radius -c "SELECT COUNT(*) FROM usuarios_empresa;" &>/dev/null; then
    echo "✓ Banco de dados funcionando corretamente"
else
    echo "⚠️  Possível problema com o banco de dados"
fi

# 10. Instalar dependências Python (opcional)
echo ""
read -p "Deseja instalar dependências Python para o script de gerenciamento? (s/N): " INSTALAR_PYTHON
if [[ $INSTALAR_PYTHON =~ ^[Ss]$ ]]; then
    echo "📦 Instalando psycopg2..."
    apt install -y python3-pip
    pip3 install psycopg2-binary
    echo "✓ Dependências Python instaladas"
fi

# 11. Configurar cron para backup (opcional)
echo ""
read -p "Deseja configurar backup automático diário às 02:00? (s/N): " CONFIGURAR_BACKUP
if [[ $CONFIGURAR_BACKUP =~ ^[Ss]$ ]]; then
    CRON_JOB="0 2 * * * $(pwd)/backup.sh >> /var/log/radius-backup.log 2>&1"
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✓ Backup automático configurado"
fi

# 12. Resumo final
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                INSTALAÇÃO CONCLUÍDA!                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 INFORMAÇÕES IMPORTANTES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Adminer (Interface Web):"
echo "   URL: http://$IP_SERVIDOR:8080"
echo "   Usuário: radius"
echo "   Senha: RadiusSecurePass123! (ou a que você configurou)"
echo "   Banco: radius"
echo ""
echo "🔐 Servidor RADIUS:"
echo "   IP: $IP_SERVIDOR"
echo "   Porta Autenticação: 1812"
echo "   Porta Accounting: 1813"
echo ""
echo "📝 PRÓXIMOS PASSOS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Configure seus Access Points:"
echo "   - Edite: freeradius/clients.conf"
echo "   - Adicione os IPs dos seus APs"
echo "   - Reinicie: docker-compose restart freeradius"
echo ""
echo "2. Teste a autenticação:"
echo "   apt install freeradius-utils"
echo "   radtest admin Admin@123 localhost 1812 testing123"
echo ""
echo "3. Gerencie usuários:"
echo "   - Interface Web: http://$IP_SERVIDOR:8080"
echo "   - Script Python: ./gerenciar_usuarios.py"
echo ""
echo "4. Configure seus Access Points:"
echo "   - Consulte: CONFIGURACAO_APS.md"
echo ""
echo "5. Monitore os logs:"
echo "   docker-compose logs -f freeradius"
echo ""
echo "📚 Documentação completa: README.md"
echo "🔧 Guia de APs: CONFIGURACAO_APS.md"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "✓ Servidor RADIUS pronto para uso!"
echo ""
