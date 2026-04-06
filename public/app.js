const pairSelect = document.getElementById('pair-select');
const viewButton = document.getElementById('view-button');
const refreshButton = document.getElementById('refresh-button');
const autoRefreshToggle = document.getElementById('auto-refresh-toggle');
const countdownLabel = document.getElementById('countdown-label');
const message = document.getElementById('message');
const quoteCard = document.getElementById('quote-card');
const pairLabel = document.getElementById('pair-label');
const askValue = document.getElementById('ask-value');
const bidValue = document.getElementById('bid-value');
const spreadValue = document.getElementById('spread-value');
const assetList = document.getElementById('asset-list');
const compareAssetSelect = document.getElementById('compare-asset-select');
const compareButton = document.getElementById('compare-button');
const comparisonTable = document.getElementById('comparison-table-body');
const historyTable = document.getElementById('history-table-body');

let historyRecords = [];
let refreshTimer = null;
let countdownTimer = null;
let countdown = 30;

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

  async compareAsset(asset) {
    return this.fetchJson(`/api/compare/${encodeURIComponent(asset)}`);
  },
};

function showMessage(text, type = 'info') {
  message.textContent = text;
  message.className = `message ${type}`;
}

function animateQuote() {
  quoteCard.classList.add('fade-updated');
  setTimeout(() => {
    quoteCard.classList.remove('fade-updated');
  }, 400);
}

function updateQuote(data) {
  const ask = parseFloat(data.ask);
  const bid = parseFloat(data.bid);
  const spread = !Number.isNaN(ask) && !Number.isNaN(bid) ? (ask - bid).toFixed(6) : '-';

  quoteCard.classList.remove('hidden');
  pairLabel.textContent = data.symbol || '-';
  askValue.textContent = data.ask || '-';
  bidValue.textContent = data.bid || '-';
  spreadValue.textContent = spread;

  animateQuote();
}

function renderHistory() {
  historyTable.innerHTML = '';

  historyRecords.forEach((entry) => {
    const row = document.createElement('tr');
    row.innerHTML = `
      <td>${entry.pair}</td>
      <td>${entry.price}</td>
      <td>${entry.time}</td>
    `;
    historyTable.appendChild(row);
  });
}

function addToHistory(pair, price) {
  const time = new Date().toLocaleTimeString('pt-BR', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });

  historyRecords.unshift({ pair, price, time });
  historyRecords = historyRecords.slice(0, 5);
  renderHistory();
}

function setCountdownLabel() {
  countdownLabel.textContent = `Próxima em ${countdown}s`;
}

function startAutoRefresh() {
  if (refreshTimer) return;

  countdown = 30;
  setCountdownLabel();

  refreshTimer = setInterval(() => {
    loadTicker(true);
  }, 30000);

  countdownTimer = setInterval(() => {
    countdown = countdown <= 1 ? 30 : countdown - 1;
    setCountdownLabel();
  }, 1000);
}

function stopAutoRefresh() {
  clearInterval(refreshTimer);
  clearInterval(countdownTimer);
  refreshTimer = null;
  countdownTimer = null;
  countdown = 30;
  setCountdownLabel();
}

function renderAssets(data) {
  assetList.innerHTML = '';

  data.slice(0, 12).forEach((item) => {
    const li = document.createElement('li');
    li.textContent = `${item.symbol} — ${item.name}`;
    assetList.appendChild(li);
  });
}

function renderCompareResults(data) {
  comparisonTable.innerHTML = '';

  data.comparisons.forEach((item) => {
    const row = document.createElement('tr');
    const ask = item.ask || '-';
    const bid = item.bid || '-';
    const spread = item.error
      ? '-'
      : (!Number.isNaN(parseFloat(ask)) && !Number.isNaN(parseFloat(bid))
        ? (parseFloat(ask) - parseFloat(bid)).toFixed(6)
        : '-');
    const status = item.error ? `<span class="status-error">${item.error}</span>` : '<span class="status-success">ok</span>';

    row.innerHTML = `
      <td>${item.pair}</td>
      <td>${ask}</td>
      <td>${bid}</td>
      <td>${spread}</td>
      <td>${status}</td>
    `;
    comparisonTable.appendChild(row);
  });
}

async function loadTicker(isAuto = false) {
  const pair = pairSelect.value.trim();

  if (!pair) {
    showMessage('Selecione um par válido para buscar a cotação.', 'error');
    return;
  }

  if (!isAuto) {
    showMessage('Buscando cotação...', 'info');
  }

  try {
    const data = await api.loadTicker(pair);
    updateQuote(data);
    addToHistory(pair, data.ask || data.bid || '-');
    if (!isAuto) showMessage('Cotação carregada com sucesso.', 'success');
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
    renderAssets(data);
    showMessage('Assets carregados com sucesso.', 'success');
  } catch (error) {
    assetList.innerHTML = '';
    showMessage(error.message, 'error');
    console.error(error);
  }
}

async function performComparison() {
  const asset = compareAssetSelect.value.trim();

  if (!asset) {
    showMessage('Selecione um asset para comparar.', 'error');
    return;
  }

  showMessage('Comparando asset...', 'info');

  try {
    const data = await api.compareAsset(asset);
    renderCompareResults(data);
    showMessage('Comparação carregada com sucesso.', 'success');

    data.comparisons
      .filter((item) => !item.error)
      .forEach((item) => {
        addToHistory(item.pair, item.ask || item.bid || '-');
      });
  } catch (error) {
    showMessage(error.message, 'error');
    console.error(error);
  }
}

viewButton.addEventListener('click', () => loadTicker(false));
refreshButton.addEventListener('click', () => loadTicker(false));
autoRefreshToggle.addEventListener('change', (event) => {
  if (event.target.checked) {
    startAutoRefresh();
  } else {
    stopAutoRefresh();
  }
});
compareButton.addEventListener('click', performComparison);

window.addEventListener('DOMContentLoaded', () => {
  loadAssets();
  loadTicker(false);
  setCountdownLabel();
});
