# Backend Video API

Esta API fornece acesso a vídeos da plataforma Pexels, permitindo buscar vídeos populares, pesquisar por termos específicos e obter detalhes de vídeos individuais.

## Tecnologias Utilizadas

- Ruby 3.4.2
- Rails 8.0.2
- RSpec (testes)
- VCR (gravação de cassetes para testes)
- Pexels API
- Dotenv (gerenciamento de variáveis de ambiente)
- Jbuilder (formatação de respostas JSON)
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
#### Ambiente de Desenvolvimento
Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:

```
PEXELS_API_KEY=sua_chave_da_api_pexels
FRONTEND_ACCESS_PASSWORD=senha_para_autenticacao_do_frontend
```

#### Ambiente de Teste
Crie um arquivo `.env.test` na raiz do projeto com variáveis para teste:

```
RAILS_ENV=test
PEXELS_API_KEY=test_pexels_api_key
FRONTEND_ACCESS_PASSWORD=test_password
```

#### Obtendo Chaves
- Para obter uma chave da API Pexels, registre-se em [https://www.pexels.com/api/](https://www.pexels.com/api/)
- O `FRONTEND_ACCESS_PASSWORD` é uma senha que você define para proteger o acesso ao frontend
- Para testes, use senhas fictícias que simulem as credenciais reais

#### Importante
- Adicione `.env*` ao seu `.gitignore` para não versionar credenciais
- Mantenha as senhas de teste diferentes das de produção
- Nunca compartilhe credenciais reais publicamente

## Executando o Projeto

### Ambiente de Desenvolvimento

Para iniciar o servidor em modo de desenvolvimento:

```bash
bin/dev
# ou
bin/rails server
```

O servidor estará disponível em: http://localhost:3001 por padrão

## Autenticação

A API atualmente utiliza autenticação baseada em sessão. O fluxo de autenticação é:

1. O cliente envia uma requisição POST para `/api/v1/auth/session` com a senha de acesso
2. Se a senha estiver correta, a sessão é marcada como autenticada
3. Todas as requisições subsequentes utilizam essa sessão para autenticação

## Testes

### Executando os Testes

Para executar todos os testes:

```bash
bundle exec rspec
```

### Configuração do VCR

Este projeto utiliza a gem VCR para gravar e reproduzir chamadas de API externas durante os testes. 

#### Como Funciona

- VCR grava as respostas das chamadas de API em "cassetes" (arquivos YAML)
- Nas execuções subsequentes dos testes, usa as respostas gravadas em vez de fazer chamadas reais
- Ajuda a manter os testes rápidos e consistentes

#### Configurações Principais

No arquivo `spec/spec_helper.rb`, o VCR está configurado com as seguintes opções:

```ruby
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.ignore_localhost = true
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [ :method, :uri, :body ]
  }

  # Filtra a chave da API Pexels nas cassetes
  config.filter_sensitive_data('<PEXELS_API_KEY>') { ENV['PEXELS_API_KEY'] }
end
```

#### Modos de Gravação

- `:new_episodes`: Grava apenas novas interações não capturadas anteriormente
- `:once`: Grava apenas se não existir uma cassete
- `:none`: Falha se tentar fazer uma chamada de rede não capturada

#### Usando VCR nos Testes

Adicione o decorator `vcr` aos seus testes:

```ruby
it 'fetches videos', vcr: { cassette_name: 'videos/fetch' } do
  # Seu teste
end
```

#### Gerenciando Cassetes

- As cassetes são armazenadas em `spec/fixtures/vcr_cassettes/`
- Inclua esta pasta no controle de versão
- Verifique se não contém informações sensíveis

#### Regenerando e Mantendo Cassetes

O VCR está configurado para regravar automaticamente cassetes após um período definido:

```ruby
# No arquivo spec/spec_helper.rb
VCR.configure do |config|
  # ... outras configurações
  config.default_cassette_options = {
    record: :new_episodes,
    re_record_interval: 30.days,  # Regrava cassetes mais antigas que 30 dias
    match_requests_on: [:method, :uri, :body]
  }
end
```

Além disso, disponibilizamos tarefas Rake para manutenção manual das cassetes:

```bash
# Limpar cassetes mais antigas que 30 dias
rails vcr:clean_old

# Remover todas as cassetes para regravação completa
rails vcr:regenerate
```

É recomendável executar estas tarefas periodicamente (por exemplo, mensalmente) ou quando ocorrerem mudanças significativas na API externa.

## Estrutura do Projeto

A aplicação segue os princípios SOLID e está estruturada da seguinte forma:

- **app/controllers**: Controladores da API
  - `api/v1/auth_controller.rb`: Gerencia autenticação
  - `api/v1/base_controller.rb`: Controller base com verificação de autenticação
  - `api/v1/videos_controller.rb`: Endpoints de vídeo
- **app/services**: Serviços que implementam a lógica de negócios
  - `video_provider_interface.rb`: Interface para provedores de vídeo
  - `video_formatter_service.rb`: Serviço para formatação de resultados
  - `video_filter_service.rb`: Serviço para filtragem de vídeos
  - `pexels_video_provider.rb`: Implementação do provedor de vídeos Pexels
  - `video_provider_factory.rb`: Factory para criar provedores de vídeo
- **app/views**: Templates Jbuilder para formatação das respostas JSON
  - `api/v1/videos/_video.json.jbuilder`: Partial para reutilização da estrutura de vídeo
  - `api/v1/videos/index.json.jbuilder`: Template para listar vídeos
  - `api/v1/videos/show.json.jbuilder`: Template para exibir detalhes de um vídeo
- **spec**: Testes automatizados

## Arquitetura da API

Esta API segue o padrão Model-View-Controller (MVC):

- **Models**: Representados pelos serviços que encapsulam a lógica de negócios e interação com APIs externas
- **Views**: Templates Jbuilder que definem o formato e estrutura das respostas JSON
- **Controllers**: Controladores que processam requisições, delegam para os serviços apropriados e renderizam as views

A utilização do Jbuilder para formatação de JSON permite uma melhor organização do código, reutilização de fragmentos comuns através de partials, e manutenção mais fácil do formato da API.

## Endpoints da API

### Autenticação

```
POST /api/v1/auth/session
```

**Parâmetros do corpo:**
- `password`: Senha de acesso definida em FRONTEND_ACCESS_PASSWORD

**Exemplo de resposta:**
```json
{
  "status": "success"
}
```

### Listar Vídeos

```
GET /api/v1/videos
```

**Parâmetros de consulta:**
- `query`: Termo de busca (opcional)
- `page`: Página dos resultados (padrão: 1)
- `per_page`: Itens por página (padrão: 10)
- `size`: Filtro de tamanho (HD, FullHD, 4K)

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

### TODO: Implementação de JWT

Para melhor suporte a múltiplos clientes e maior escalabilidade, planeja-se migrar de autenticação baseada em sessão para tokens JWT (JSON Web Tokens). Isso trará os seguintes benefícios:

- Autenticação stateless (sem estado) que funciona melhor em ambientes distribuídos
- Possibilidade de incluir identificação do cliente e outras informações no token
- Expiração automática de tokens para maior segurança
- Padrão da indústria que facilita integração com outros sistemas

A implementação envolverá:
- Adicionar a gem JWT
- Criar um módulo para codificar/decodificar tokens
- Modificar os controllers para usar tokens em vez de sessões
- Atualizar a documentação da API

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para mais detalhes.
