Aqui está a consulta SQL ajustada para o PostgreSQL para gerar o relatório com os requisitos solicitados.

```sql
SELECT 
    TO_CHAR(created_at, 'YYYY-MM') AS "mês",
    category AS "categoria",
    COUNT(id) AS "quantidade de transações",
    ROUND(SUM(amount_cents) / 100.0, 2) AS "volume total em reais"
FROM 
    transactions
WHERE 
    status = 'completed'
    AND created_at >= '2026-04-24'::TIMESTAMP - INTERVAL '6 months'
    AND created_at <= '2026-04-24 23:59:59'
GROUP BY 
    TO_CHAR(created_at, 'YYYY-MM'),
    category
ORDER BY 
    "mês" ASC,
    category ASC;

```

---

### 💡 Detalhes da Solução:

* **Filtro de Data:** A cláusula `WHERE` busca os dados retroativos a partir de `2026-04-24` utilizando `- INTERVAL '6 months'`. Também delimitamos o fim do dia `2026-04-24` para garantir que o intervalo fique exato.
* **Formatação do Mês:** Utilizamos `TO_CHAR(created_at, 'YYYY-MM')` para agrupar e exibir os meses exatamente no formato solicitado.
* **Conversão de Centavos:** Como a coluna `amount_cents` armazena os valores em centavos, dividimos por `100.0` (o `.0` força o banco a entender como um número flutuante/numeric) e aplicamos o `ROUND(..., 2)` para garantir as duas casas decimais.
* **Agrupamento e Ordenação:** A ordenação segue a regra de negócio (mês crescente, categoria crescente), permitindo que você veja a evolução mensal lado a lado de cada categoria ('subscription', 'one_time', etc).