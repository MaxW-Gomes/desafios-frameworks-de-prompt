
---

# Relatório de Análise e Otimização de Custos de Cloud

### Estratégia FinOps para Redução de Gastos sem Impacto em SLA

* **Data do Relatório:** 2 de junho de 2026
* **Custo Mensal Atual:** USD 41.800,00
* **Meta de Redução (15%):** USD 6.270,00
* **Potencial de Economia Estimado:** ~22% (Até USD 9.200,00)

---

## 1. Resumo Executivo

Esta análise foi realizada a partir do inventário e das métricas de utilização de infraestrutura fornecidos. O gasto mensal totaliza **USD 41.800,00**. A meta de 15% estabelecida pela liderança exige um corte mínimo de **USD 6.270,00**.

Identificamos oportunidades reais que somam até **USD 9.200,00** em economia potencial (cerca de 22% do total). As ações propostas focam em direitos de reserva, modernização de arquitetura e automação de ciclo de vida de dados, **garantindo a estrita preservação dos SLAs de produção**.

---

## 2. Visão Geral dos Custos Atuais

Distribuição atual dos serviços analisados, ordenados por relevância financeira:

| Serviço | Categoria | Uso Médio | Custo Mensal (USD) | % do Total da Conta | Observação |
| --- | --- | --- | --- | --- | --- |
| **EC2 on-demand** | compute | 45% | 8.200,00 | 19,62% | Workloads variáveis |
| **RDS PostgreSQL** | databases | 62% | 8.200,00 | 19,62% | Multi-AZ |
| **EKS** | compute | 58% | 6.700,00 | 16,03% | 3 clusters |
| **EC2 reservada** | compute | 72% | 4.200,00 | 10,05% | Contrato de 1 ano |
| **S3 Standard** | storage | — | 3.100,00 | 7,42% | 5 buckets principais |
| **CloudWatch Logs** | observability | — | 2.800,00 | 6,70% | Retenção de 90 dias |
| **ElastiCache Redis** | databases | 40% | 2.100,00 | 5,02% | Cluster de produção |
| **Data Transfer Out** | network | — | 1.900,00 | 4,55% | Tráfego entre regiões |
| **EBS gp3** | storage | 68% | 1.600,00 | 3,83% | Volumes de produção |
| **NAT Gateway** | network | — | 1.200,00 | 2,87% | 3 gateways ativos |
| **CloudWatch Metrics** | observability | — | 900,00 | 2,15% | — |
| **Lambda** | compute | 30% | 900,00 | 2,15% | ~12M invocações/mês |
| **TOTAL** | — | — | **41.800,00** | **100,00%** | — |

---

## 3. Oportunidades de Ajuste Estruturadas (Ordenadas por Impacto)

### 🥇 Oportunidade 1: Otimização e Reserva de Instâncias EC2 On-Demand

* **Custo do Serviço:** USD 8.200,00 por mês
* **Percentual da Conta:** **19,62%**
* **Impacto Financeiro:** **Alto** (Economia estimada de USD 2.400,00 a USD 3.200,00)
* **Esforço de Implementação:** Médio
* **Riscos Envolvidos:** Baixo se aplicado via compromissos flexíveis (*Savings Plans*); Médio se houver redução de tamanho (*rightsizing*) agressiva sem monitoramento prévio de pico de carga.
* **Pré-requisitos:** Análise detalhada do histórico de uso com o *AWS Compute Optimizer*; identificação exata da linha de base estável da aplicação.
* **Ação Recomendada:** O uso médio de 45% indica severo superdimensionamento. Deve-se:
1. Aplicar *rightsizing* (reduzir família/tamanho) nas instâncias subutilizadas.
2. Adquirir um **Compute Savings Plan de 1 ano** (sem adiantamento) para cobrir a capacidade mínima constante (gerando até 30% de desconto imediato).
3. Configurar regras de Auto Scaling baseadas em CPU/Métricas de aplicação para absorver picos de tráfego, ou adotar instâncias Spot para workloads sem estado.



### 🥈 Oportunidade 2: Redimensionamento e Compra de Reservas para RDS PostgreSQL

* **Custo do Serviço:** USD 8.200,00 por mês
* **Percentual da Conta:** **19,62%**
* **Impacto Financeiro:** **Alto** (Economia estimada de USD 2.000,00 a USD 2.800,00)
* **Esforço de Implementação:** Médio
* **Riscos Envolvidos:** Mínimo/Nulo para a compra puramente comercial de reservas; Baixo para desligamento de Multi-AZ apenas em ambientes de homologação.
* **Pré-requisitos:** Avaliação da telemetria de CPU, Memória e IOPS dos últimos 30 dias.
* **Ação Recomendada:** Sendo uma topologia Multi-AZ com uso médio de 62%, o banco possui relevância e criticidade de SLA. Contudo, o custo sob demanda é expressivo. A recomendação principal é adquirir **Instâncias Reservadas (RI) de RDS para 1 ano**, garantindo o desconto sem nenhuma alteração técnica ou risco à resiliência. Adicionalmente, caso haja instâncias de testes inclusas nessa categoria, elas devem ser migradas para Single-AZ e desligadas fora do horário comercial.

### 🥉 Oportunidade 3: Consolidação e Auto-scaling Avançado no EKS

* **Custo do Serviço:** USD 6.700,00 por mês
* **Percentual da Conta:** **16,03%**
* **Impacto Financeiro:** **Alto** (Economia estimada de USD 1.300,00 a USD 2.000,00)
* **Esforço de Implementação:** Alto
* **Riscos Envolvidos:** Médio. Ajustes e migrações na camada de nós do Kubernetes podem causar pequenas instabilidades caso os Pods não possuam regras de tolerância a interrupções (*Pod Disruption Budgets*) ou sondas de prontidão bem ajustadas.
* **Pré-requisitos:** Instalação do scheduler **Karpenter**; revisão completa de `requests` e `limits` de CPU e memória declarados nos manifestos das aplicações.
* **Ação Recomendada:** Manter 3 clusters com média de utilização de 58% gera muita fragmentação de recursos de computação. Ações:
1. Adotar o **Karpenter** para provisionamento dinâmico e consolidação proativa de nós de tamanho ideal.
2. Utilizar uma mescla com instâncias Spot para microsserviços *stateless* (sem estado) em ambientes de não-produção.
3. Avaliar a unificação dos clusters de Desenvolvimento e Homologação em um único cluster físico, mantendo o isolamento lógico estrito via Namespaces e políticas de rede.



### 📈 Oportunidade 4: Gestão de Ciclo de Vida e Retenção no CloudWatch Logs

* **Custo do Serviço:** USD 2.800,00 por mês
* **Percentual da Conta:** **6,70%**
* **Impacto Financeiro:** **Médio** (Economia estimada de USD 1.000,00 a USD 1.400,00)
* **Esforço de Implementação:** Baixo
* **Riscos Envolvidos:** Baixo. Pode inviabilizar consultas imediatas de logs muito antigos diretamente pela console da AWS (porém as buscas continuam possíveis via consultas no S3).
* **Pré-requisitos:** Alinhamento com os times de Segurança e Compliance para validar as regras regulatórias de auditoria da empresa.
* **Ação Recomendada:** A retenção padrão de 90 dias em armazenamento ativo (Hot Storage do CloudWatch) é altamente onerosa. Deve-se:
1. Alterar a retenção nativa dos grupos de logs para **14 ou 30 dias**.
2. Implementar uma sub-rotina nativa para exportar automaticamente logs antigos para buckets do **S3 Glacier**, onde o custo por GB armazenado é drasticamente inferior.
3. Ajustar o nível de verbosidade das aplicações de `DEBUG/INFO` para `WARN/ERROR` em produção.



### 📈 Oportunidade 5: Políticas de Ciclo de Vida do S3 Standard

* **Custo do Serviço:** USD 3.100,00 por mês
* **Percentual da Conta:** **7,42%**
* **Impacto Financeiro:** **Médio** (Economia estimada de USD 600,00 a USD 1.200,00)
* **Esforço de Implementação:** Baixo
* **Riscos Envolvidos:** Mínimo. Leve acréscimo no tempo de recuperação e custo de requisição apenas para arquivos muito antigos acessados de forma esporádica.
* **Pré-requisitos:** Ativação do ferramenta *S3 Storage Lens* para mapear padrões de acesso e identificar objetos órfãos.
* **Ação Recomendada:** Configurar **Políticas de Ciclo de Vida (Lifecycle Policies)** nos 5 buckets principais. Objetos sem modificação ou acesso há mais de 30 dias devem transicionar automaticamente para classes econômicas como *S3 Standard-IA (Infrequent Access)* ou *S3 Intelligent-Tiering*. Incluir rotinas para expirar versões antigas e limpar uploads multipartes inacabados.

### 📉 Oportunidade 6: Otimização do ElastiCache Redis

* **Custo do Serviço:** USD 2.100,00 por mês
* **Percentual da Conta:** **5,02%**
* **Impacto Financeiro:** **Médio-Baixo** (Economia estimada de USD 400,00 a USD 600,00)
* **Esforço de Implementação:** Médio
* **Riscos Envolvidos:** Baixo. Risco residual de estouro de memória (mitigado se validado com métricas prévias).
* **Pré-requisitos:** Verificação rigorosa do parâmetro `BytesUsedForCache` no CloudWatch.
* **Ação Recomendada:** O cluster opera com apenas 40% de utilização média. Recomenda-se realizar o *downsizing* (redução do tamanho da instância) dos nós atuais do cluster ou avaliar a redução da quantidade de réplicas de leitura se a resiliência atual estiver sobredimensionada para as demandas da aplicação.

### 📉 Oportunidade 7: Consolidação de Redundância de NAT Gateways

* **Custo do Serviço:** USD 1.200,00 por mês
* **Percentual da Conta:** **2,87%**
* **Impacto Financeiro:** **Baixo-Médio** (Economia estimada de USD 400,00 a USD 800,00)
* **Esforço de Implementação:** Médio
* **Riscos Envolvidos:** Redução de alta disponibilidade na saída de internet privada caso uma Zona de Disponibilidade inteira (AZ) sofra uma pane completa (risco mitigado mantendo 2 gateways em vez de apenas 1).
* **Pré-requisitos:** Alteração e mapeamento de tabelas de roteamento da VPC (*Route Tables*).
* **Ação Recomendada:** Atualmente existem 3 NAT Gateways ativos (um por AZ), gerando um custo fixo por hora muito elevado. Recomenda-se reduzir para 2 NAT Gateways compartilhados entre as sub-redes. Paralelamente, implementar **VPC Endpoints** (para serviços internos como S3 e DynamoDB), permitindo que o tráfego interno não passe pelo NAT Gateway, eliminando tarifas abusivas de processamento de dados.

---

## 4. Conclusão e Plano de Execução Sugerido

Para alcançar com total segurança a meta de **15% de redução** sem afetar negativamente os SLAs, o plano de ação deve seguir o cronograma baseado em complexidade técnica e impacto:

* **Fase 1 (Quick Wins - Semana 1):** Alteração da retenção do CloudWatch Logs e aplicação imediata de políticas de ciclo de vida no S3 Standard.
* *Economia estimada: ~5% do total da conta.*


* **Fase 2 (Otimização Comercial - Semanas 2 e 3):** Aquisição de RDS Reserved Instances e contratação do Compute Savings Plan para o EC2 estável.
* *Economia estimada: ~10% do total da conta (Batendo a Meta).*


* **Fase 3 (Modernização de Engenharia - Semana 4+):** Implantação do Karpenter no EKS, consolidação de clusters não produtivos e redução de NAT Gateways.
* *Economia estimada adicional: ~7% extra para margem de segurança.*



---

*Relatório estruturado sob princípios FinOps. Confidencial.*