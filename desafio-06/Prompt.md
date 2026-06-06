# Context
Eu preciso criar um módulo terraform que seja utilizado para criar buckets s3 de forma reutilizável que será utilizado por todos os times na empresa.

# Action
Crie um módulo terraform com todos os recursos necessários a criação de buckets s3. Ou seja, o módulo deve permitir que sejam criados 1 ou mais buckets s3 em cada execução.
Também é necessário que seja criado um arquivo "README.md" ensinando como usar o módulo, mostrando exemplos no final.

# Result
O módulo deve seguir alguns padrões de criação, tais como:

- Tags obrigatórias em todo recurso: Owner, CostCenter, Environment.
- Prefixo hvt- nos nomes de recursos.
- Todo bucket S3 com: encryption habilitada (SSE-S3 mínimo), versioning ativo, block public access total, logging configurado.
- Variáveis de entrada em variables.tf com description e type obrigatórios.

# Example
Como referência, temos esse modulo de vpc que foi criado seguindo os padrões da empresa:

```
variable "environment" {
  description = "Nome do ambiente (dev, staging, production)"
  type        = string
}

locals {
  common_tags = {
    Owner       = var.owner
    CostCenter  = var.cost_center
    Environment = var.environment
  }
}

resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags = merge(local.common_tags, {
    Name = "hvt-vpc-${var.environment}"
  })
}
```
