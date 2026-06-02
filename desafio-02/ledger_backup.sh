#!/usr/bin/env bash
# =============================================================================
# ledger_backup.sh
# Backup automatizado do banco PostgreSQL "ledger_prod" para o S3.
#
# Fluxo:
#   1. Obtém a senha via AWS Secrets Manager
#   2. Conecta ao PostgreSQL e valida acesso
#   3. Gera dump com pg_dump e compacta em gzip (streaming)
#   4. Faz upload para o S3
#   5. Registra tudo em /var/log/ledger-backup.log
#
# Dependências: awscli v2, postgresql-client, jq
# Compatível com: Ubuntu 22.04 LTS
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configurações gerais
# ---------------------------------------------------------------------------
DB_HOST="ledger-db.internal.hvt.io"
DB_PORT="5432"
DB_NAME="ledger_prod"
DB_USER="backup_user"

SECRET_NAME="rds-ledger-admin-user"
AWS_REGION="us-east-1"
S3_BUCKET="s3://hvt-ledger-backups/ledger-backups"

WORK_DIR="/var/backups/ledger"
LOG_FILE="/var/log/ledger-backup.log"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DUMP_FILE="${WORK_DIR}/ledger_prod_${TIMESTAMP}.dump"
GZ_FILE="${DUMP_FILE}.gz"
S3_KEY="ledger_prod_${TIMESTAMP}.dump.gz"

# ---------------------------------------------------------------------------
# Funções auxiliares
# ---------------------------------------------------------------------------

# Grava uma linha no log com timestamp ISO-8601
log() {
    local level="$1"
    local message="$2"
    echo "[$(date --iso-8601=seconds)] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info()  { log "INFO " "$1"; }
log_warn()  { log "WARN " "$1"; }
log_error() { log "ERROR" "$1"; }

# Chamado automaticamente pelo "trap" em caso de erro
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "Falha inesperada na linha ${line_number} (exit code: ${exit_code})."
    log_error "Backup ABORTADO em $(date --iso-8601=seconds)."

    # Remove arquivos parciais para liberar espaço
    [[ -f "${DUMP_FILE}" ]] && rm -f "${DUMP_FILE}" && log_warn "Arquivo de dump parcial removido: ${DUMP_FILE}"
    [[ -f "${GZ_FILE}"   ]] && rm -f "${GZ_FILE}"   && log_warn "Arquivo gz parcial removido: ${GZ_FILE}"

    exit "${exit_code}"
}

trap 'handle_error ${LINENO}' ERR

# ---------------------------------------------------------------------------
# 0. Pré-verificações
# ---------------------------------------------------------------------------

log_info "========================================================"
log_info "Início do backup — ledger_prod @ ${TIMESTAMP}"
log_info "========================================================"

# Cria diretório de trabalho se não existir
mkdir -p "${WORK_DIR}"

# Verifica espaço livre (mínimo 20 GB como margem de segurança)
FREE_KB=$(df --output=avail -k "${WORK_DIR}" | tail -1)
FREE_GB=$(( FREE_KB / 1024 / 1024 ))
log_info "Espaço livre em ${WORK_DIR}: ${FREE_GB} GB"
if (( FREE_GB < 20 )); then
    log_error "Espaço insuficiente em ${WORK_DIR}: ${FREE_GB} GB disponíveis (mínimo: 20 GB)."
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. Obtém a senha via AWS Secrets Manager
# ---------------------------------------------------------------------------
log_info "Recuperando credenciais do Secrets Manager (secret: ${SECRET_NAME})..."

SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "${SECRET_NAME}" \
    --region "${AWS_REGION}" \
    --query 'SecretString' \
    --output text)

# A secret pode estar no formato JSON {"password":"..."} ou como string direta
if echo "${SECRET_JSON}" | jq -e . >/dev/null 2>&1; then
    # Tenta os campos mais comuns usados pelo RDS Secrets Manager
    export PGPASSWORD
    PGPASSWORD=$(echo "${SECRET_JSON}" | jq -r '.password // .PGPASSWORD // .db_password // empty')
    if [[ -z "${PGPASSWORD}" ]]; then
        log_error "Campo de senha não encontrado no JSON da secret. Campos disponíveis: $(echo "${SECRET_JSON}" | jq -r 'keys[]')"
        exit 1
    fi
else
    # Secret é uma string simples (senha pura)
    export PGPASSWORD="${SECRET_JSON}"
fi

log_info "Credenciais obtidas com sucesso."

# ---------------------------------------------------------------------------
# 2. Valida acesso ao banco
# ---------------------------------------------------------------------------
log_info "Testando conectividade com o banco de dados..."

psql \
    --host="${DB_HOST}" \
    --port="${DB_PORT}" \
    --username="${DB_USER}" \
    --dbname="${DB_NAME}" \
    --no-password \
    --command="SELECT 1;" \
    --quiet \
    --tuples-only > /dev/null

log_info "Conectividade OK."

# ---------------------------------------------------------------------------
# 3. Gera o dump e compacta em streaming (sem armazenar o dump puro em disco)
# ---------------------------------------------------------------------------
log_info "Iniciando pg_dump | gzip => ${GZ_FILE}"
log_info "Formato: custom (-Fc) para restauração eficiente via pg_restore."

pg_dump \
    --host="${DB_HOST}" \
    --port="${DB_PORT}" \
    --username="${DB_USER}" \
    --dbname="${DB_NAME}" \
    --no-password \
    --format=custom \
    --blobs \
    --verbose \
    --lock-wait-timeout=30s \
    2>>"${LOG_FILE}" \
| gzip -9 > "${GZ_FILE}"

GZ_SIZE_HUMAN=$(du -sh "${GZ_FILE}" | cut -f1)
log_info "Dump compactado gerado: ${GZ_FILE} (${GZ_SIZE_HUMAN})"

# Limpa a senha da memória após o uso
unset PGPASSWORD

# ---------------------------------------------------------------------------
# 4. Upload para o S3
# ---------------------------------------------------------------------------
S3_URI="${S3_BUCKET}/${S3_KEY}"
log_info "Iniciando upload para ${S3_URI}..."

aws s3 cp "${GZ_FILE}" "${S3_URI}" \
    --region "${AWS_REGION}" \
    --storage-class STANDARD_IA \
    --no-progress

log_info "Upload concluído: ${S3_URI}"

# Valida que o objeto chegou ao S3
S3_SIZE=$(aws s3api head-object \
    --bucket "hvt-ledger-backups" \
    --key "ledger-backups/${S3_KEY}" \
    --region "${AWS_REGION}" \
    --query 'ContentLength' \
    --output text 2>/dev/null || echo "0")

if [[ "${S3_SIZE}" == "0" ]]; then
    log_warn "Não foi possível confirmar o tamanho do objeto no S3. Verifique manualmente."
else
    log_info "Tamanho confirmado no S3: ${S3_SIZE} bytes."
fi

# ---------------------------------------------------------------------------
# 5. Limpeza local
# ---------------------------------------------------------------------------
log_info "Removendo arquivo local: ${GZ_FILE}"
rm -f "${GZ_FILE}"

# ---------------------------------------------------------------------------
# 6. Finalização
# ---------------------------------------------------------------------------
log_info "Backup concluído com sucesso em $(date --iso-8601=seconds)."
log_info "========================================================"
exit 0