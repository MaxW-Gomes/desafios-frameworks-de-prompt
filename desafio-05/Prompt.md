# Before
Nós temos uma aplicação chamada Chronos, que funciona como api gateway. Ele roda em um cluster kubernetes como um deployment. Por ser antigo, O arquivo yaml desse deployment não está seguindo as melhores práticas.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chronos-api
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: chronos-api
  template:
    metadata:
      labels:
        app: chronos-api
    spec:
      containers:
      - name: api
        image: chronos-api:latest
        ports:
        - containerPort: 8080
        env:
        - name: DB_PASSWORD
          value: "P@ssw0rd2023!"
        - name: JWT_SECRET
          value: "hvt-jwt-prod-secret"
```


# After
Precisamos que o arquivo yaml seja atualizado seguindo as melhores práticas de segurança e confiabilidade.

# Bridge
Rescreva o arquivo, fazendo com que os seguintes sejam respeitados:

- A aplicação deve possuir alta disponibilidade
- Adicione resource requests e limits
- A imagem deve ser versionado em vez de sempre pegar a latest. A imagem inicial pode ser a 1.0.0
- As variáveis de ambientes devem ser recuperadas através da secrets "chronos-secrets"
- Adicione liveness e readiness probes
- O securityContext não pode ser root

Caso tenha faltado alguma outra boa prática, fique à vontade para adicionar. Ajustes adicionais precisam ser informados.