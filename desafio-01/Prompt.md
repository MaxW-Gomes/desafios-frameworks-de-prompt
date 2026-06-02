# Role 
Assuma a função de um Devops com experiência em processos de build de imagem.

# Task
Crie um arquivo "Dockerfile" para uma aplicação python cuja estrutura se apresenta da seguinte forma:


```
lift/
├── app.py
├── requirements.txt
├── lib/
│   ├── auth.py
│   └── storage.py
└── tests/
    └── test_app.py
```

Essas são as dependencias descritas no arquivo "requirements.txt":


```
Flask==3.0.0
gunicorn==21.2.0
requests==2.31.0
python-dotenv==1.0.0
psycopg2-binary==2.9.9
```

O arquivo deverá ser criado seguindo as melhores práticas. Além disso, duas variáveis de ambiente precisam estar declaradas no runtime do arquivo:


```
DATABASE_URL
API_KEY
```

A porta a ser exposta é a 8080.

A aplicação é carregada através do comando abaixo:

```
gunicorn --bind 0.0.0.0:8080 --workers 4 app:app
```


# Format

O arquivo precisa estar com os comandos agrupados(RUN, CMD, ENV, etc) e precisa conter um comentário para cada agrupamento resumindo o que está sendo realizado.