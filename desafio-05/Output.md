Aqui está o arquivo YAML do Deployment atualizado, estruturado para seguir rigorosamente as melhores práticas de segurança, resiliência e boas práticas de Kubernetes.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chronos-api
  namespace: production
  labels:
    app.kubernetes.io/name: chronos-api
    app.kubernetes.io/part-of: chronos
    app.kubernetes.io/managed-by: helm # Exemplo de label padrão de mercado
spec:
  replicas: 3 # Alta Disponibilidade: Mínimo de 3 réplicas para tolerância a falhas
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%       # Garante que novas réplicas sobem antes de derrubar as antigas
      maxUnavailable: 0   # Garante que 100% da capacidade atual permaneça ativa durante o deploy
  selector:
    matchLabels:
      app: chronos-api
  template:
    metadata:
      labels:
        app: chronos-api
    spec:
      # Segurança: Define contexto a nível de Pod (Não roda como Root)
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      
      # Alta Disponibilidade Avançada: Evita que os Pods rodem no mesmo nó físico
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - chronos-api
              topologyKey: kubernetes.io/hostname

      containers:
      - name: api
        image: chronos-api:1.0.0 # Imagem versionada (evita surpresas com a 'latest')
        imagePullPolicy: IfNotPresent
        
        # Segurança: Restrições rígidas a nível de container
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true # Impede escrita no disco do container (boa prática clássica)
          capabilities:
            drop:
            - ALL

        ports:
        - containerPort: 8080
          name: http-port

        # Gerenciamento de Recursos (Ajuste os valores conforme a realidade do Chronos)
        resources:
          requests:
            cpu: "250m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"

        # Injeção de variáveis de ambiente via Secrets
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: chronos-secrets
              key: database-password # Altere para o nome exato da chave dentro da sua secret
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: chronos-secrets
              key: jwt-secret # Altere para o nome exato da chave dentro da sua secret

        # Probes de Saúde (Ajuste os paths conforme os endpoints reais da aplicação)
        livenessProbe:
          httpGet:
            path: /healthz # Endpoint para verificar se o container travou/morreu
            port: http-port
          initialDelaySeconds: 15
          periodSeconds: 20
        readinessProbe:
          httpGet:
            path: /ready # Endpoint para verificar se a app está pronta para receber tráfego
            port: http-port
          initialDelaySeconds: 5
          periodSeconds: 10

```

---

## 🛠️ Ajustes Adicionais Implementados (Além dos Solicitados)

Como você deu carta branca para adicionar o que faltava, inseri proteções fundamentais para um ambiente de produção:

* **`RollingUpdate` Estruturado (`maxUnavailable: 0`):** Garante que seu API Gateway nunca perca capacidade de atendimento durante uma atualização. O Kubernetes só mata um pod antigo quando o novo estiver 100% pronto (`readinessProbe` aprovado).
* **`podAntiAffinity` (Afinidade Negativa):** Configuração crucial para Alta Disponibilidade real. Ela "pede gentilmente" ao Kubernetes para espalhar os 3 pods em nós (nodes) diferentes. Se um nó da AWS/Cloud cair, os outros 2 pods continuam segurando o tráfego em outros nós.
* **`readOnlyRootFilesystem: true`:** Força o sistema de arquivos do container a ser estritamente de leitura. Se um atacante conseguir explorar uma vulnerabilidade no Chronos, ele não conseguirá baixar scripts maliciosos ou alterar arquivos binários internos.
* **`capabilities.drop: ["ALL"]`:** Remove todos os privilégios do kernel Linux do container que não são estritamente necessários para expor uma porta de rede.
* **Nomenclatura na Porta (`name: http-port`):** Vinculamos os Probes ao nome da porta em vez do número `8080` diretamente. Se no futuro você mudar a porta da aplicação, só precisará alterar na linha do `containerPort`.