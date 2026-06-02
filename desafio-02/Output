Segue o script com tudo que foi pedido. Abaixo estão os pontos de atenção antes de colocar em produção.

---

## O que o script faz, passo a passo

| Etapa | Detalhe |
|---|---|
| **0 – Pré-checks** | Garante que o diretório de trabalho existe e que há pelo menos 20 GB livres antes de começar |
| **1 – Secrets Manager** | Chama `aws secretsmanager get-secret-value` e extrai a senha via `jq`, suportando tanto JSON `{"password":"..."}` quanto string pura |
| **2 – Valida conexão** | Executa um `SELECT 1` antes do dump para falhar cedo se o banco estiver inacessível |
| **3 – Dump + gzip** | `pg_dump` em formato *custom* (`-Fc`) **em pipe direto** para `gzip -9` — o dump não é escrito em disco sem compressão, economizando ~3× espaço |
| **4 – Upload S3** | `aws s3 cp` com `--storage-class STANDARD_IA` (adequado para backups); valida o tamanho do objeto após o upload |
| **5 – Limpeza** | Remove o `.gz` local após upload confirmado |
| **Log** | Toda linha usa `tee -a` — nunca sobrescreve o arquivo de log |

---


## Permissões IAM necessárias para a role da instância EC2

```json
{
  "Effect": "Allow",
  "Action": [
    "secretsmanager:GetSecretValue"
  ],
  "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:rds-ledger-admin-user*"
},
{
  "Effect": "Allow",
  "Action": [
    "s3:PutObject",
    "s3:HeadObject"
  ],
  "Resource": "arn:aws:s3:::hvt-ledger-backups/ledger-backups/*"
}
```

---

## Deploy

```bash
# Instalar dependências
sudo apt-get install -y awscli jq postgresql-client

# Colocar o script em produção
sudo cp ledger_backup.sh /usr/local/sbin/
sudo chmod 700 /usr/local/sbin/ledger_backup.sh
sudo chown root:root /usr/local/sbin/ledger_backup.sh

# Criar arquivo de log com permissão adequada
sudo touch /var/log/ledger-backup.log
sudo chmod 640 /var/log/ledger-backup.log

# Agendar via cron (ex.: todo dia às 02:00)
echo "0 2 * * * root /usr/local/sbin/ledger_backup.sh" \
  | sudo tee /etc/cron.d/ledger-backup
```

---

## Comportamento em caso de falha

O `trap 'handle_error ${LINENO}' ERR` intercepta qualquer erro não tratado, loga a linha exata onde ocorreu junto com o exit code original, remove arquivos parciais do disco e sai com o código de erro correto — compatível com alertas do CloudWatch ou sistemas de monitoramento de cron.