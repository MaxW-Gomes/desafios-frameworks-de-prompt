Com certeza! Vamos estruturar esse módulo de forma que ele seja extremamente simples de usar pelos outros times, mas rígido o suficiente para garantir que ninguém crie um bucket fora dos padrões de segurança e governança da empresa.

Para permitir a criação de **1 ou mais buckets** em uma única chamada, utilizaremos o recurso de `for_each` do Terraform mapeando as configurações necessárias.

Abaixo está a estrutura completa dos arquivos do módulo (`variables.tf`, `main.tf`, `outputs.tf`) e o arquivo `README.md` explicativo.

---

## 1. `variables.tf`

Aqui definimos as variáveis com tipos explícitos e descrições detalhadas, conforme o padrão exigido.

```hcl
variable "environment" {
  description = "Ambiente de implantação dos recursos (ex: dev, staging, prod)"
  type        = string
}

variable "owner" {
  description = "Time ou pessoa responsável pela criação e manutenção dos buckets"
  type        = string
}

variable "cost_center" {
  description = "Centro de custo associado a estes recursos para fins de faturamento"
  type        = string
}

variable "logging_target_bucket" {
  description = "ID do bucket S3 centralizado onde os logs de acesso de todos os buckets criados serão armazenados"
  type        = string
}

variable "buckets" {
  description = "Mapa contendo as configurações de cada bucket a ser criado. A chave do mapa será usada como sufixo do nome do bucket."
  type = map(object({
    # Você pode adicionar propriedades customizadas por bucket aqui se necessário no futuro
    force_destroy = optional(bool, false)
  }))
  default = {}
}

```

---

## 2. `main.tf`

Aqui aplicamos a lógica do prefixo `hvt-`, a injeção das tags obrigatórias em todos os sub-recursos e as quatro camadas de segurança solicitadas (Criptografia, Versionamento, Bloqueio Público e Logs de Acesso).

```hcl
locals {
  common_tags = {
    Owner       = var.owner
    CostCenter  = var.cost_center
    Environment = var.environment
  }
}

# 1. Criação dos Buckets S3
resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  # Garante o prefixo hvt-, o ambiente e o identificador único fornecido pelo usuário
  bucket        = "hvt-${var.environment}-${each.key}"
  force_destroy = each.value.force_destroy

  tags = merge(local.common_tags, {
    Name = "hvt-${var.environment}-${each.key}"
  })
}

# 2. Habilitação de Versionamento Ativo
resource "aws_s3_bucket_versioning" "this" {
  for_each = var.buckets

  bucket = aws_s3_bucket.this[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Configuração de Criptografia SSE-S3 (Padrão Mínimo AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = var.buckets

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Bloqueio Total de Acesso Público
resource "aws_s3_bucket_public_access_block" "this" {
  for_each = var.buckets

  bucket = aws_s3_bucket.this[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5. Configuração de Logging de Acesso
resource "aws_s3_bucket_logging" "this" {
  for_each = var.buckets

  bucket        = aws_s3_bucket.this[each.key].id
  target_bucket = var.logging_target_bucket
  target_prefix = "s3-access-logs/hvt-${var.environment}-${each.key}/"
}

```

---

## 3. `outputs.tf`

Para facilitar a vida dos times que vão consumir esse módulo, vamos expor os ARNs e IDs dos buckets criados.

```hcl
output "bucket_ids" {
  description = "Mapa com os IDs (nomes) de todos os buckets criados"
  value       = { for k, v in aws_s3_bucket.this : k => v.id }
}

output "bucket_arns" {
  description = "Mapa com os ARNs de todos os buckets criados"
  value       = { for k, v in aws_s3_bucket.this : k => v.arn }
}

```