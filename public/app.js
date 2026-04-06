const pairSelect = document.getElementById('pair-select');
const viewButton = document.getElementById('view-button');
const refreshButton = document.getElementById('refresh-button');
const message = document.getElementById('message');
const quoteCard = document.getElementById('quote-card');
const pairLabel = document.getElementById('pair-label');
const askValue = document.getElementById('ask-value');
const bidValue = document.getElementById('bid-value');
const spreadValue = document.getElementById('spread-value');
const assetList = document.getElementById('asset-list');

const api = {
  async fetchJson(path) {
    const response = await fetch(path);
    const payload = await response.json().catch(() => ({ error: response.statusText }));

    if (!response.ok) {
      throw new Error(payload.error || 'Erro na resposta da API');
    }

    return payload;
  },

  async loadTicker(pair) {
    return this.fetchJson(`/api/ticker/${encodeURIComponent(pair)}`);
  },

  async loadAssets() {
    return this.fetchJson('/api/assets');
  },
};

function showMessage(text, type = 'info') {
  message.textContent = text;
  message.className = `message ${type}`;
}

function updateQuote(data) {
  const ask = parseFloat(data.ask);
  const bid = parseFloat(data.bid);

  quoteCard.classList.remove('hidden');
  pairLabel.textContent = data.symbol || '-';
  askValue.textContent = data.ask || '-';
  bidValue.textContent = data.bid || '-';
  spreadValue.textContent = !Number.isNaN(ask) && !Number.isNaN(bid) ? (ask - bid).toFixed(6) : '-';
}

async function loadTicker() {
  const pair = pairSelect.value.trim();

  if (!pair) {
    showMessage('Selecione um par válido para buscar a cotação.', 'error');
    return;
  }

  showMessage('Buscando cotação...', 'info');

  try {
    const data = await api.loadTicker(pair);
    updateQuote(data);
    showMessage('Cotação carregada com sucesso.', 'success');
  } catch (error) {
    showMessage(error.message, 'error');
    quoteCard.classList.add('hidden');
    console.error(error);
  }
}

async function loadAssets() {
  showMessage('Carregando lista de assets...', 'info');

  try {
    const data = await api.loadAssets();
    assetList.innerHTML = '';

    data.slice(0, 12).forEach((item) => {
      const li = document.createElement('li');
      li.textContent = `${item.symbol} — ${item.name}`;
      assetList.appendChild(li);
    });

    showMessage('Assets carregados com sucesso.', 'success');
  } catch (error) {
    assetList.innerHTML = '';
    showMessage(error.message, 'error');
    console.error(error);
  }
}

viewButton.addEventListener('click', loadTicker);
refreshButton.addEventListener('click', loadTicker);

window.addEventListener('DOMContentLoaded', () => {
  loadAssets();
  loadTicker();
});
