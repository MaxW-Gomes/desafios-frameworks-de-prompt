Aqui está o Dockerfile. As principais decisões tomadas foram:

**Multi-stage build** — o stage `builder` instala as dependências com pip e o stage `runtime` copia apenas os artefatos prontos, resultando em uma imagem final sem `pip`, `setuptools` ou qualquer lixo de compilação.

**Dependência de sistema** — o `psycopg2-binary` precisa de `libpq5` em runtime. Ela é instalada com `--no-install-recommends` e o cache do apt é limpo logo em seguida para não inflar a camada.

**Usuário não-root** — UID/GID `1001` dedicados são criados para rodar a aplicação. É uma exigência em praticamente todo scanner de vulnerabilidades (Trivy, Snyk, etc.) e uma boa prática de segurança padrão.

**`tests/` excluído** — apenas `app.py` e `lib/` são copiados. Para reforçar isso no build context, vale criar um `.dockerignore` com:
```
tests/
__pycache__/
*.pyc
.env
```

**Variáveis de ambiente** — `DATABASE_URL` e `API_KEY` são declaradas vazias no `ENV`. Os valores reais devem ser injetados em runtime via `--env-file`, Kubernetes Secrets ou equivalente — nunca hardcoded na imagem.