#!/bin/bash

# Script de Backup do Servidor RADIUS
# Execute este script regularmente usando cron

BACKUP_DIR="/backup/radius"
DATA_ATUAL=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="radius_backup_${DATA_ATUAL}.sql"
DIAS_RETENCAO=30

# Criar diretório de backup se não existir
mkdir -p ${BACKUP_DIR}

echo "🔄 Iniciando backup do servidor RADIUS..."
echo "📅 Data: $(date)"

# Fazer backup do PostgreSQL
echo "📦 Fazendo backup do banco de dados..."
docker exec radius-postgres pg_dump -U radius radius > "${BACKUP_DIR}/${BACKUP_FILE}"

if [ $? -eq 0 ]; then
    echo "✓ Backup criado com sucesso: ${BACKUP_FILE}"
    
    # Comprimir o backup
    gzip "${BACKUP_DIR}/${BACKUP_FILE}"
    echo "✓ Backup comprimido: ${BACKUP_FILE}.gz"
    
    # Calcular tamanho
    TAMANHO=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}.gz" | cut -f1)
    echo "📊 Tamanho: ${TAMANHO}"
    
    # Remover backups antigos
    echo "🗑️  Removendo backups com mais de ${DIAS_RETENCAO} dias..."
    find ${BACKUP_DIR} -name "radius_backup_*.sql.gz" -mtime +${DIAS_RETENCAO} -delete
    
    # Listar backups existentes
    echo ""
    echo "📋 Backups disponíveis:"
    ls -lh ${BACKUP_DIR}/radius_backup_*.sql.gz | tail -5
    
    echo ""
    echo "✓ Backup concluído com sucesso!"
else
    echo "✗ Erro ao criar backup!"
    exit 1
fi

# Opcional: Enviar para storage externo (descomente e configure)
# echo "☁️  Enviando para cloud storage..."
# aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}.gz" s3://seu-bucket/radius-backups/
# rclone copy "${BACKUP_DIR}/${BACKUP_FILE}.gz" remote:radius-backups/

echo "✓ Processo de backup finalizado!"
echo "============================================"
