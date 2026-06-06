# Task
Rodar consulta sql nas tabelas do sistema Ledger.

# Action
Leia as tabelas abaixo e crie uma consulta sql que mostre o volume de transações considerando as seguintes informações:

- A consulta deve buscar os dados de '2026-04-24' até 6 meses atrás
- A consulta deve retornar os dados em três colunas: "mês", "categoria", "quantidade de transações" e "volume total em reais"
- A consulta deve ser agrupada por mês(formato YYYY-MM) e por categoria
- A consulta deve buscar somente as transações em que a coluna "status" = 'completed'
- O campo "amount_cents" está em centavos de real e precisa ser retornado na saída em reais com duas casas decimais
- As categorias existentes são: 'subscription','one_time','refund' e 'credit_adjustment'.
- A consulta precisa estar ordenada por mês(crescente) e depois categoria(crescente)

## Tabelas do sistema Ledger

```
CREATE TABLE transactions (
  id              BIGSERIAL PRIMARY KEY,
  customer_id     BIGINT NOT NULL REFERENCES customers(id),
  category        VARCHAR(32) NOT NULL,
  amount_cents    BIGINT NOT NULL,
  status          VARCHAR(16) NOT NULL,
  payment_method  VARCHAR(16),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at    TIMESTAMPTZ
);

CREATE INDEX idx_transactions_created_at ON transactions(created_at);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_category ON transactions(category);
```

```
CREATE TABLE customers (
  id          BIGSERIAL PRIMARY KEY,
  segment     VARCHAR(16) NOT NULL,
  country     CHAR(2) NOT NULL,
  signup_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```



# Goal
Gerar um relatório que mostre o crescimento no número de transações nos últimos 6 meses por categoria