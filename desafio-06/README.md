# Módulo Terraform S3 Corporativo (`hvt-s3-module`)

Módulo reutilizável e padronizado para provisionamento de buckets S3 na AWS. Este módulo foi desenhado para garantir conformidade automática com as diretrizes de segurança, auditoria e taggamento da empresa.

## ✨ Funcionalidades Integradas por Padrão

Para manter a conformidade, **todo** bucket criado através deste módulo possui:
* **Prefixo Compulsório:** O nome do bucket sempre começará com `hvt-<ambiente>-`.
* **Tags Obrigatórias:** `Owner`, `CostCenter` e `Environment` aplicadas automaticamente.
* **Segurança Avançada:** Criptografia Server-Side ativa por padrão (`SSE-S3`).
* **Governança:** Versionamento ativado para proteção contra deleções acidentais.
* **Privacidade:** Bloqueio total de acesso público (`Block Public Access`).
* **Auditoria:** Configuração de logs de acesso direcionados para um bucket centralizado.

---

## 📋 Variáveis de Entrada (Inputs)

| Nome | Descrição | Tipo | Obrigatório |
| :--- | :--- | :--- | :--- |
| `environment` | Nome do ambiente (`dev`, `staging`, `prod`) | `string` | **Sim** |
| `owner` | Time ou squad dona do recurso (ex: `data-engineering`) | `string` | **Sim** |
| `cost_center` | Centro de custo para faturamento (ex: `cc-10234`) | `string` | **Sim** |
| `logging_target_bucket` | ID do bucket centralizado que armazenará os logs | `string` | **Sim** |
| `buckets` | Mapa contendo os sufixos e configurações dos buckets | `map(object)`| **Sim** |

### Estrutura do objeto `buckets`
* `force_destroy` *(opcional/bool)*: Permite destruir o bucket mesmo que ele contenha arquivos. Padrão: `false`.

---

## 📤 Saídas (Outputs)

| Nome | Descrição | Tipo |
| :--- | :--- | :--- |
| `bucket_ids` | Mapa indexado contendo os IDs/Nomes reais dos buckets criados. | `map(string)` |
| `bucket_arns` | Mapa indexado contendo os ARNs dos buckets criados. | `map(string)` |

---

## 🛠️ Exemplos de Uso

### Exemplo 1: Criando múltiplos buckets para um time de dados
No exemplo abaixo, o time de engenharia de dados cria a estrutura de Data Lake de uma só vez no ambiente de desenvolvimento.

```hcl
module "data_lake_buckets" {
  source = "git::[https://github.com/sua-empresa/terraform-aws-s3.git?ref=v1.0.0](https://github.com/sua-empresa/terraform-aws-s3.git?ref=v1.0.0)" # Altere para o caminho real do seu módulo

  environment           = "dev"
  owner                 = "data-engineering"
  cost_center           = "cc-9942"
  logging_target_bucket = "hvt-audit-logs-central-bucket" # Bucket de logs já existente

  buckets = {
    "landing-zone" = {
      force_destroy = true # Útil em ambiente de desenvolvimento
    }
    "processed-data" = {}
    "analytics-ready" = {}
  }
}

# Output dos nomes gerados para usar em outras partes do código
output "meus_buckets" {
  value = module.data_lake_buckets.bucket_ids
}
/* O output acima retornará:
  {
    "landing-zone"    = "hvt-dev-landing-zone"
    "processed-data"  = "hvt-dev-processed-data"
    "analytics-ready" = "hvt-dev-analytics-ready"
  }
*/

```

### Exemplo 2: Criando apenas 1 bucket simples

Caso um time precise de apenas um bucket isolado para uploads temporários:

```hcl
module "frontend_assets" {
  source = "../modules/s3" # Caminho local caso esteja no mesmo repositório

  environment           = "prod"
  owner                 = "frontend-team"
  cost_center           = "cc-1105"
  logging_target_bucket = "hvt-audit-logs-central-bucket"

  buckets = {
    "static-cache" = {}
  }
}

```