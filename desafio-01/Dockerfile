# =============================================================================
# Stage 1 — Builder
# Instala as dependências em um ambiente isolado para manter a imagem final limpa
# =============================================================================
FROM python:3.12-slim AS builder

WORKDIR /install

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir --prefix=/install/deps -r requirements.txt


# =============================================================================
# Stage 2 — Runtime
# Imagem final enxuta, sem ferramentas de build desnecessárias
# =============================================================================
FROM python:3.12-slim

# =============================================================================
# Dependências de sistema
# Instala libpq necessária para psycopg2 funcionar em runtime
# =============================================================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq5 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Usuário não-root
# Cria um usuário dedicado para rodar a aplicação com privilégios mínimos
# =============================================================================
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --no-create-home appuser

# =============================================================================
# Dependências Python
# Copia os pacotes instalados no stage builder para a imagem final
# =============================================================================
COPY --from=builder /install/deps /usr/local

# =============================================================================
# Código da aplicação
# Copia apenas os arquivos necessários para produção, excluindo testes
# =============================================================================
WORKDIR /app

COPY app.py .
COPY lib/ ./lib/

RUN chown -R appuser:appgroup /app

# =============================================================================
# Variáveis de ambiente
# Declara as variáveis exigidas em runtime (valores injetados via deploy)
# =============================================================================
ENV DATABASE_URL="" \
    API_KEY=""

# =============================================================================
# Porta exposta
# Informa ao runtime que a aplicação escuta na porta 8080
# =============================================================================
EXPOSE 8080

# =============================================================================
# Usuário de execução
# Garante que o processo roda sem privilégios de root
# =============================================================================
USER appuser

# =============================================================================
# Ponto de entrada
# Inicia a aplicação com Gunicorn em modo produção
# =============================================================================
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "4", "app:app"]