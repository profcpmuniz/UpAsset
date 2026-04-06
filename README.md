# Uphold Explorer

Aplicação de estudo pessoal para explorar a API pública da Uphold.

## Como iniciar

### Ambiente de desenvolvimento local

1. Instale Ruby 3.4.x e Bundler.
2. Instale as dependências do projeto:

```bash
bundle install
```

3. Inicie o servidor Rails na porta 3000 e vincule-o a `0.0.0.0`:

```bash
bin/rails server -b 0.0.0.0 -p 3000
```

4. Abra o navegador em:

```text
http://localhost:3000
```

### Iniciar em uma máquina nova

1. Clone o repositório:

```bash
git clone https://github.com/profcpmuniz/UpAsset.git
cd UpAsset
```

2. Instale Ruby 3.4.x e Bundler.

- Em sistemas Debian/Ubuntu, você pode usar `rbenv` ou `ruby-build`:

```bash
sudo apt update
sudo apt install -y git curl libssl-dev libreadline-dev zlib1g-dev
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-installer | bash
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
rbenv install 3.4.7
rbenv global 3.4.7
gem install bundler
```

- Alternativamente, use `rvm` ou `asdf` de acordo com sua preferência.

3. Execute `bundle install`.
4. Inicie o servidor com `bin/rails server -b 0.0.0.0 -p 3000`.

### Executar com Docker

1. Construa a imagem Docker:

```bash
docker build -t uphold-explorer .
```

2. Execute o container mapeando para a porta 3000:

```bash
docker run --rm -p 3000:80 -e RAILS_MASTER_KEY=$(cat config/master.key) uphold-explorer
```

3. Abra o navegador em:

```text
http://localhost:3000
```

> Se você estiver usando Codespaces ou outro ambiente em nuvem, garanta que a porta `3000` esteja exposta.

## Estrutura principal

- `app/controllers/api_controller.rb` — proxy de rotas para a API Uphold usando `net/http`
- `config/routes.rb` — rotas: `/api/ticker/:pair` e `/api/assets`
- `public/index.html` — frontend vanilla HTML
- `public/style.css` — estilos de interface
- `public/app.js` — lógica de frontend e consumo dos endpoints

## API da Uphold

A aplicação consome o endpoint público da Uphold em:

- Base URL: `https://api.uphold.com/v0`

Principais endpoints usados:

- `GET /assets`
  - Lista todos os assets suportados pela Uphold.
  - Usado para preencher a lista de principais ativos no frontend.

- `GET /ticker/{pair}`
  - Retorna dados de cotação para o par informado, por exemplo `BTC-USD`, `ETH-EUR`, etc.
  - O frontend exibe `ask`, `bid` e calcula o spread (`ask - bid`).

### Como o proxy Rails funciona

O Rails expõe rotas locais para evitar CORS no browser:

- `GET /api/assets` → proxy para `https://api.uphold.com/v0/assets`
- `GET /api/ticker/:pair` → proxy para `https://api.uphold.com/v0/ticker/:pair`

O backend também trata erros da API e retorna JSON amigável para o frontend.

## Documentação oficial da Uphold

A documentação pública da Uphold está disponível em:

- https://docs.uphold.com/#introduction

Principais detalhes de API usados neste projeto:

- `GET /assets`
  - Retorna um array de objetos que representam ativos suportados.
  - Cada ativo normalmente inclui campos como `symbol`, `name` e `currency`.

- `GET /ticker/{pair}`
  - Retorna o livro de ordens ou dados de cotação para o par de moedas.
  - Exemplo de resposta inclui campos como `symbol`, `ask`, `bid`, `high`, `low`, `volume` e `updatedAt`.

- O projeto usa o Rails para consumir esses endpoints via proxy e não expõe diretamente o host da Uphold para o browser.

## Notas técnicas

- Não há persistência de banco de dados.
- O Rails atua como backend API/proxy para evitar erros de CORS.
- O frontend é estático e servido diretamente pela pasta `public/`.
