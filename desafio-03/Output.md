Seu relatório em formato PDF com a análise detalhada e oportunidades de cortes de custo foi gerado com sucesso.

Abaixo está o resumo executivo e a estrutura detalhada do plano apresentado no relatório técnico para apoiar a tomada de decisões imediatas.

---

### 📊 Visão Geral da Conta e Impacto por Serviço

O custo mensal total mapeado na planilha é de **USD 41.800,00**.

* **Sua Meta (15%):** Redução mínima de **USD 6.270,00**.
* **Potencial Identificado:** Economia estimada de até **USD 9.200,00 (~22%)**, superando a meta sem comprometer a resiliência e o SLA de produção.

Abaixo estão as oportunidades de otimização priorizadas por **impacto financeiro**:

---

### 🚀 Plano de Ação e Ajustes Estruturados (Ordenados por Impacto)

#### 1. Otimização de Instâncias EC2 On-Demand

* **Custo Atual:** USD 8.200,00 (**19,62%** do total da conta)
* **Impacto Financeiro:** **Alto** (Economia de USD 2.400,00 a USD 3.200,00)
* **Esforço:** Médio
* **Riscos Envolvidos:** Baixo se aplicado via Savings Plans flexíveis; Médio se houver *rightsizing* agressivo sem testes de carga prévios.
* **Pré-requisitos:** Análise de histórico de uso com o *AWS Compute Optimizer*; separação clara de workloads previsíveis de workloads sazonais.
* **Ação Recomendada:** O uso médio de 45% indica superdimensionamento. Deve-se aplicar *rightsizing* nas instâncias ociosas e cobrir a base de computação estável por meio de um contrato de **Compute Savings Plan de 1 ano** (gerando ~30% de desconto imediato). Picos de carga variável devem ser gerenciados por regras de Auto Scaling mais agressivas ou instâncias Spot.

#### 2. Redimensionamento e Reserva do RDS PostgreSQL

* **Custo Atual:** USD 8.200,00 (**19,62%** do total da conta)
* **Impacto Financeiro:** **Alto** (Economia de USD 2.000,00 a USD 2.800,00)
* **Esforço:** Médio
* **Riscos Envolvidos:** Mínimo para a compra de reservas comerciais (sem alteração técnica); Médio se houver degradação de performance por downgrade de instância.
* **Pré-requisitos:** Avaliação da telemetria de CPU e IOPS no CloudWatch para validar o teto de utilização antes de qualquer alteração de tipo de hardware.
* **Ação Recomendada:** Sendo um banco crítico (Multi-AZ com 62% de uso médio), o SLA de produção está garantido. Contudo, o custo sob demanda é alto. A recomendação principal é a compra de **Instâncias Reservadas (RI) de RDS por 1 ano** (opção *No Upfront* / Sem adiantamento). Se houver instâncias de staging dentro desse montante operando em Multi-AZ, elas devem ser convertidas para Single-AZ.

#### 3. Consolidação de Recursos e Auto-scaling Inteligente no EKS

* **Custo Atual:** USD 6.700,00 (**16,03%** do total da conta)
* **Impacto Financeiro:** **Alto** (Economia de USD 1.300,00 a USD 2.000,00)
* **Esforço:** Alto
* **Riscos Envolvidos:** Médio. Alterações na camada de nós de clusters Kubernetes podem causar indisponibilidade se Pod Disruption Budgets (PDBs) e liveness/readiness probes não estiverem configurados corretamente.
* **Pré-requisitos:** Instalação e parametrização do **Karpenter** como scheduler de nós; auditoria das declarações de `requests` e `limits` das aplicações.
* **Ação Recomendada:** Com 3 clusters ativos e uso médio de apenas 58%, há uma fragmentação cara. Ações: substituir o Cluster Autoscaler legado pelo **Karpenter** para consolidar Pods em menos nós de forma dinâmica; adotar instâncias Spot para workloads sem estado (*stateless*) em ambientes não produtivos; unificar clusters de desenvolvimento/homologação em um único cluster físico isolado por Namespaces.

#### 4. Gestão de Retenção e Filtros no CloudWatch Logs

* **Custo Atual:** USD 2.800,00 (**6,70%** do total da conta)
* **Impacto Financeiro:** **Médio** (Economia de USD 1.000,00 a USD 1.400,00)
* **Esforço:** Baixo
* **Riscos Envolvidos:** Baixo. Eventual perda de logs operacionais antigos para consulta imediata via console (mitigado pelo arquivamento no S3).
* **Pré-requisitos:** Alinhamento com o time de Segurança/Compliance sobre as regras de auditoria e tempos mínimos exigidos por regulamentos da empresa.
* **Ação Recomendada:** Manter 90 dias de retenção nativa no CloudWatch (Hot Storage) é ineficiente. Reduza a retenção nativa para **14 ou 30 dias** e configure uma tarefa automatizada para exportar logs antigos para o **S3 Glacier** (onde o custo por GB é até 90% menor). Ajuste o nível de verbosidade (*Log Level*) de aplicações ruidosas em produção.

#### 5. Ciclo de Vida do S3 Standard

* **Custo Atual:** USD 3.100,00 (**7,42%** do total da conta)
* **Impacto Financeiro:** **Médio** (Economia de USD 600,00 a USD 1.200,00)
* **Esforço:** Baixo
* **Riscos Envolvidos:** Mínimo. Ligeiro aumento no tempo de recuperação de arquivos de uso esporádico.
* **Pré-requisitos:** Ativação do *S3 Storage Lens* para identificar a idade média dos objetos e detectar uploads multipartes inacabados.
* **Ação Recomendada:** Aplicar **Políticas de Ciclo de Vida (Lifecycle Policies)** nos 5 buckets principais. Objetos que não são acessados há mais de 30 dias devem transicionar automaticamente para *S3 Standard-IA (Infrequent Access)* ou habilitar o *S3 Intelligent-Tiering*. Adicionar regras para deletar versões antigas de objetos e limpar uploads que falharam.

#### 6. Otimização de Arquitetura de Rede (NAT Gateways)

* **Custo Atual:** USD 1.200,00 (**2,87%** do total da conta)
* **Impacto Financeiro:** **Baixo-Médio** (Economia de USD 400,00 a USD 800,00)
* **Esforço:** Médio
* **Riscos Envolvidos:** Redução marginal de resiliência caso uma Zona de Disponibilidade inteira sofra uma queda rara (se consolidado de 3 para 1 gateway). Risco mitigado se mantidos 2 gateways para 3 AZs.
* **Pré-requisitos:** Mapeamento e alteração das tabelas de roteamento da VPC (*Route Tables*).
* **Ação Recomendada:** Reduzir os 3 gateways ativos para 1 ou 2, compartilhando o tráfego de saída das sub-redes privadas. Paralelamente, implementar **VPC Endpoints** (Gateway tipo S3 e DynamoDB) para que o tráfego interno não passe pelo NAT Gateway, eliminando custos de processamento de dados por giga.

---

### ⏱️ Cronograma Sugerido de Implementação (Estratégia FinOps)

1. **Fase 1 (Semana 1 - Ganho Rápido):** Aplicar políticas de ciclo de vida no S3 e reduzir retenção do CloudWatch Logs. *(Esforço Baixo / Impacto Imediato)*
2. **Fase 2 (Semana 2 e 3 - Comercial):** Adquirir os planos de Instâncias Reservadas para RDS e Savings Plans para EC2 base estável. *(Garante os descontos contratuais sem alterar código)*
3. **Fase 3 (Semana 4+ - Engenharia):** Configurar o Karpenter no EKS, consolidar os clusters e os NAT Gateways. *(Esforço maior, mas consolida a cultura de eficiência de nuvem)*