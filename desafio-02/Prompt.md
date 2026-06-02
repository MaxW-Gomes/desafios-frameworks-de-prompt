# Role 
Assuma a função de um DBA com experiência em AWS e PostgreSQL.

# Task 
Crie um script ssh que realize as seguintes tarefas:

1. Obtenha a senha da base de dados através do serviço "Secrets Manager";
2. Acesse a base de dados PostgreSQL;
3. Gere um dump da base via "pg_dump". Depois de gerado, compacte o arquivo formato gzip;
4. Suba o arquivo compactado no bucket S3 através do comando "aws s3 cp";
5. Registre a execução no arquivo "/var/log/ledger-backup.log" com o uso de timestamp sem apagar os registros anteriores.

> OBS: Em caso de falha, o erro também deverá ser registrado em "/var/log/ledger-backup.log" e sair com o exit code apropriado.

**Dados necessários:**

```
Host: ledger-db.internal.hvt.io
Porta: 5432
Banco: ledger_prod
Usuário de backup: backup_user
Senha: variável de ambiente PGPASSWORD, populada pelo AWS Secrets Manager. Nome da secret: rds-ledger-admin-user
SO da instância: Ubuntu 22.04 LTS
Diretório de trabalho com 80 GB livres: /var/backups/ledger
Tamanho médio atual do dump compactado: ~12 GB
```