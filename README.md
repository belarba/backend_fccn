# Backend Video API

Esta API fornece acesso a vídeos da plataforma Pexels, permitindo buscar vídeos populares, pesquisar por termos específicos e obter detalhes de vídeos individuais.

## Tecnologias Utilizadas

- Ruby 3.4.2
- Rails 8.0.2
- RSpec (testes)
- Pexels API
- Dotenv (gerenciamento de variáveis de ambiente)
- Rubocop (para enfatizar melhores práticas)

## Pré-requisitos

- Ruby 3.4.2 (recomenda-se usar [rbenv](https://github.com/rbenv/rbenv) ou [rvm](https://rvm.io/) para gerenciamento de versões)
- Bundler
- Git

## Configuração Inicial

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/backend_fccn.git
cd backend_fccn
```

### 2. Instale as dependências

```bash
bundle install
```

### 3. Configure as variáveis de ambiente

Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:

```
PEXELS_API_KEY=sua_chave_da_api_pexels
BACKEND_API_KEY=chave_para_autenticacao_da_api
```

Para obter uma chave da API Pexels, registre-se em [https://www.pexels.com/api/](https://www.pexels.com/api/).

A `BACKEND_API_KEY` é uma chave que você define para proteger seu backend. Ela será necessária para autenticar requisições à API.


## Executando o Projeto

### Ambiente de Desenvolvimento

Para iniciar o servidor em modo de desenvolvimento:

```bash
bin/dev
# ou
bin/rails server
```

O servidor estará disponível em: http://localhost:3001 por padrão

### Testes

Para executar todos os testes:

```bash
bundle exec rspec
```

Para executar testes específicos:

```bash
bundle exec rspec spec/path/to/test_file.rb
```

## Estrutura do Projeto

A aplicação segue os princípios SOLID e está estruturada da seguinte forma:

- **app/controllers**: Controladores da API
- **app/services**: Serviços que implementam a lógica de negócios
  - `video_provider_interface.rb`: Interface para provedores de vídeo
  - `video_formatter_service.rb`: Serviço para formatação de resultados
  - `video_filter_service.rb`: Serviço para filtragem de vídeos
  - `pexels_video_provider.rb`: Implementação do provedor de vídeos Pexels
  - `video_provider_factory.rb`: Factory para criar provedores de vídeo
- **spec**: Testes automatizados

## Endpoints da API

### Listar Vídeos

```
GET /api/v1/videos
```

**Parâmetros de consulta:**
- `query`: Termo de busca (opcional)
- `page`: Página dos resultados (padrão: 1)
- `per_page`: Itens por página (padrão: 10)
- `size`: Filtro de tamanho (HD, FullHD, 4K)

**Cabeçalhos:**
```
Authorization: sua_backend_api_key
```

**Exemplo de resposta:**
```json
{
  "items": [
    {
      "id": 1234,
      "width": 1920,
      "height": 1080,
      "duration": 30,
      "user_name": "Nome do Usuário",
      "video_files": [
        {
          "link": "https://exemplo.com/video.mp4",
          "quality": "hd",
          "width": 1280,
          "height": 720
        }
      ],
      "video_pictures": [
        "https://exemplo.com/thumbnail.jpg"
      ]
    }
  ],
  "page": 1,
  "per_page": 10,
  "total_pages": 5
}
```

### Obter Detalhes de um Vídeo

```
GET /api/v1/videos/:id
```

**Cabeçalhos:**
```
Authorization: sua_backend_api_key
```

**Exemplo de resposta:**
```json
{
  "id": 1234,
  "width": 1920,
  "height": 1080,
  "duration": 30,
  "user": {
    "name": "Nome do Usuário",
    "url": "https://www.pexels.com/user/nome-do-usuario/"
  },
  "video_files": {
    "sd": [
      {
        "link": "https://exemplo.com/video_sd.mp4",
        "quality": "sd",
        "width": 640,
        "height": 360,
        "file_type": "video/mp4"
      }
    ],
    "hd": [
      {
        "link": "https://exemplo.com/video_hd.mp4",
        "quality": "hd",
        "width": 1280,
        "height": 720,
        "file_type": "video/mp4"
      }
    ],
    "full_hd": [
      {
        "link": "https://exemplo.com/video_full_hd.mp4",
        "quality": "hd",
        "width": 1920,
        "height": 1080,
        "file_type": "video/mp4"
      }
    ],
    "uhd": []
  },
  "video_pictures": [
    "https://exemplo.com/thumb1.jpg"
  ],
  "resolution": "FullHD",
  "url": "https://www.pexels.com/video/1234/"
}
```

## Cache

A API utiliza caching para reduzir o número de chamadas à API Pexels:

- As listagens de vídeos são cacheadas por 30 minutos
- Os detalhes de vídeos individuais são cacheados por 1 hora

## Contribuindo

1. Faça um fork do projeto
2. Crie sua branch de feature (`git checkout -b feature/nome-da-feature`)
3. Commit suas alterações (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nome-da-feature`)
5. Crie um novo Pull Request

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para mais detalhes.
