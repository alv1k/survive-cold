/**
 * server.js
 * Высокопроизводительный сервер многопользовательской игры "Survive the Cold: 7 Relics".
 * Работает на чистом Node.js (без сторонних зависимостей npm).
 * Поддерживает:
 * - HTTP веб-сервер (http://localhost:3000)
 * - WebSocket синхронизацию мира (RFC 6455)
 * - Игроков, чат, общий Алтарь, реликвии, дропы, постройки и погоду.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = process.env.PORT || 3000;
const MAP_SIZE = 12000;

// --- СОСТОЯНИЕ МИРА СЕРВЕРА (AUTHORITATIVE STATE) ---
let worldState = {
  weatherState: 'Clear',
  weatherTimer: 0,
  altarPlacedRelics: 0,
  isBunkerOpen: false,
  relics: [],
  droppedItems: [],
  fieldCampfires: [],
  spikeTraps: [],
  structures: [],
  airDrops: []
};

// Спавн 7 Реликвий
function initServerRelics() {
  const spawns = [
    { x: 1800, y: 2200 },
    { x: 2100, y: 9800 },
    { x: 5200, y: 3500 },
    { x: 6200, y: 7800 },
    { x: 7800, y: 4200 },
    { x: 8600, y: 9200 },
    { x: 9800, y: 6200 }
  ];
  worldState.relics = spawns.map((s, idx) => ({
    id: idx + 1,
    x: s.x,
    y: s.y,
    collected: false,
    carriedBy: null
  }));
}
initServerRelics();

const clients = new Map(); // socket -> playerData
let nextPlayerId = 1;

// --- HTTP SERVER ---
const server = http.createServer((req, res) => {
  let reqUrl = req.url.split('?')[0];
  let filePath = path.join(__dirname, reqUrl === '/' ? 'index.html' : reqUrl);
  
  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    let ext = path.extname(filePath);
    let contentType = 'text/html; charset=utf-8';
    if (ext === '.js') contentType = 'application/javascript; charset=utf-8';
    if (ext === '.css') contentType = 'text/css; charset=utf-8';
    if (ext === '.json') contentType = 'application/json; charset=utf-8';
    
    res.writeHead(200, {
      'Content-Type': contentType,
      'Access-Control-Allow-Origin': '*'
    });
    fs.createReadStream(filePath).pipe(res);
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('404 Not Found');
  }
});

// --- WEBSOCKET RFC 6455 IMPLEMENTATION ---
const WS_GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

server.on('upgrade', (req, socket, head) => {
  if (!req.headers['upgrade'] || req.headers['upgrade'].toLowerCase() !== 'websocket') {
    socket.destroy();
    return;
  }

  const key = req.headers['sec-websocket-key'];
  if (!key) {
    socket.destroy();
    return;
  }

  const acceptKey = crypto
    .createHash('sha1')
    .update(key + WS_GUID)
    .digest('base64');

  const headers = [
    'HTTP/1.1 101 Switching Protocols',
    'Upgrade: websocket',
    'Connection: Upgrade',
    'Sec-WebSocket-Accept: ' + acceptKey,
    '\r\n'
  ];

  socket.write(headers.join('\r\n'));

  // Инициализация игрока
  const playerId = 'player_' + (nextPlayerId++);
  const playerColor = ['#38bdf8', '#4ade80', '#f59e0b', '#c084fc', '#ec4899', '#fde047'][Math.floor(Math.random() * 6)];
  
  const playerData = {
    id: playerId,
    name: 'Выживший #' + (nextPlayerId - 1),
    x: 3350 + (Math.random() - 0.5) * 60,
    y: 6000 + (Math.random() - 0.5) * 60,
    angle: 0,
    health: 100,
    warmth: 100,
    hunger: 100,
    clothingLevel: 0,
    relicsInHand: 0,
    isSprinting: false,
    color: playerColor,
    equippedItem: null
  };

  clients.set(socket, playerData);
  console.log(`[+] Игрок подключился: ${playerData.name} (${playerId}) | Всего онлайн: ${clients.size}`);

  // Отправляем игроку приветственный пакет и состояние мира
  sendWsMessage(socket, {
    type: 'init',
    yourId: playerId,
    playerData: playerData,
    worldState: worldState,
    players: Array.from(clients.values())
  });

  // Оповещаем остальных игроков
  broadcast({
    type: 'player_joined',
    player: playerData
  }, socket);

  // Чтение входящих фреймов
  let buffer = Buffer.alloc(0);

  socket.on('data', (chunk) => {
    buffer = Buffer.concat([buffer, chunk]);
    
    while (buffer.length >= 2) {
      const firstByte = buffer[0];
      const secondByte = buffer[1];
      const isFinal = (firstByte & 0x80) !== 0;
      const opcode = firstByte & 0x0f;
      const isMasked = (secondByte & 0x80) !== 0;
      let payloadLen = secondByte & 0x7f;
      
      let headerLen = 2;
      if (payloadLen === 126) {
        if (buffer.length < 4) break;
        payloadLen = buffer.readUInt16BE(2);
        headerLen = 4;
      } else if (payloadLen === 127) {
        if (buffer.length < 10) break;
        payloadLen = Number(buffer.readBigUInt64BE(2));
        headerLen = 10;
      }

      const maskKeyLen = isMasked ? 4 : 0;
      if (buffer.length < headerLen + maskKeyLen + payloadLen) {
        break; // Ждем следующий кусок данных
      }

      let maskKey = null;
      if (isMasked) {
        maskKey = buffer.slice(headerLen, headerLen + 4);
      }

      const payload = buffer.slice(headerLen + maskKeyLen, headerLen + maskKeyLen + payloadLen);
      buffer = buffer.slice(headerLen + maskKeyLen + payloadLen);

      // Размаскирование
      if (isMasked) {
        for (let i = 0; i < payload.length; i++) {
          payload[i] ^= maskKey[i % 4];
        }
      }

      if (opcode === 0x8) {
        // Close frame
        socket.end();
        break;
      } else if (opcode === 0x9) {
        // Ping -> Pong
        const pong = Buffer.from([0x8a, 0x00]);
        socket.write(pong);
      } else if (opcode === 0x1) {
        // Text message
        try {
          const msg = JSON.parse(payload.toString('utf8'));
          handleClientMessage(socket, playerData, msg);
        } catch (e) {
          console.error('Ошибка парсинга WS сообщения:', e);
        }
      }
    }
  });

  socket.on('close', () => {
    clients.delete(socket);
    console.log(`[-] Игрок отключился: ${playerData.name} (${playerId}) | Всего онлайн: ${clients.size}`);
    broadcast({
      type: 'player_left',
      id: playerId
    });
  });

  socket.on('error', (err) => {
    clients.delete(socket);
  });
});

// Отправка WS сообщения одному клиенту
function sendWsMessage(socket, data) {
  if (socket.destroyed || !socket.writable) return;
  const jsonStr = JSON.stringify(data);
  const payload = Buffer.from(jsonStr, 'utf8');
  const len = payload.length;

  let frame;
  if (len <= 125) {
    frame = Buffer.alloc(2 + len);
    frame[0] = 0x81; // FIN + text opcode
    frame[1] = len;  // Not masked
    payload.copy(frame, 2);
  } else if (len <= 65535) {
    frame = Buffer.alloc(4 + len);
    frame[0] = 0x81;
    frame[1] = 126;
    frame.writeUInt16BE(len, 2);
    payload.copy(frame, 4);
  } else {
    frame = Buffer.alloc(10 + len);
    frame[0] = 0x81;
    frame[1] = 127;
    frame.writeBigUInt64BE(BigInt(len), 2);
    payload.copy(frame, 10);
  }

  socket.write(frame);
}

// Рассылка всем клиентам
function broadcast(data, exceptSocket = null) {
  for (const [s, p] of clients.entries()) {
    if (s !== exceptSocket) {
      sendWsMessage(s, data);
    }
  }
}

// --- ОБРАБОТЧИК СОБЫТИЙ КЛИЕНТА ---
function handleClientMessage(socket, player, msg) {
  switch (msg.type) {
    case 'set_name':
      player.name = String(msg.name || player.name).slice(0, 16);
      broadcast({ type: 'player_updated', player: player });
      break;

    case 'player_move':
      player.x = msg.x;
      player.y = msg.y;
      player.angle = msg.angle;
      player.health = msg.health;
      player.warmth = msg.warmth;
      player.hunger = msg.hunger;
      player.clothingLevel = msg.clothingLevel;
      player.relicsInHand = msg.relicsInHand;
      player.isSprinting = msg.isSprinting;
      player.equippedItem = msg.equippedItem;
      break;

    case 'attack':
      broadcast({
        type: 'remote_attack',
        playerId: player.id,
        weapon: msg.weapon,
        x: msg.x,
        y: msg.y,
        tx: msg.tx,
        ty: msg.ty
      }, socket);
      break;

    case 'pickup_relic':
      const relic = worldState.relics.find(r => r.id === msg.relicId);
      if (relic && !relic.collected) {
        relic.collected = true;
        relic.carriedBy = player.id;
        broadcast({
          type: 'relic_collected',
          relicId: relic.id,
          playerId: player.id,
          playerName: player.name
        });
      }
      break;

    case 'place_altar':
      const count = msg.count || 1;
      worldState.altarPlacedRelics = Math.min(7, worldState.altarPlacedRelics + count);
      if (worldState.altarPlacedRelics >= 7) {
        worldState.isBunkerOpen = true;
      }
      broadcast({
        type: 'altar_updated',
        placedRelics: worldState.altarPlacedRelics,
        isBunkerOpen: worldState.isBunkerOpen,
        playerName: player.name
      });
      break;

    case 'place_structure':
      const newStructure = {
        id: Date.now() + Math.random(),
        type: msg.structureType,
        x: msg.x,
        y: msg.y,
        placedBy: player.name,
        fuelSeconds: msg.fuelSeconds || 90
      };
      if (msg.structureType === 'campfire') worldState.fieldCampfires.push(newStructure);
      else if (msg.structureType === 'spike') worldState.spikeTraps.push(newStructure);
      else worldState.structures.push(newStructure);

      broadcast({
        type: 'structure_placed',
        structure: newStructure
      });
      break;

    case 'drop_item':
      const newDrop = {
        id: Date.now() + Math.random(),
        itemId: msg.itemId,
        count: msg.count,
        x: msg.x,
        y: msg.y
      };
      worldState.droppedItems.push(newDrop);
      broadcast({
        type: 'item_dropped',
        drop: newDrop
      });
      break;

    case 'chat':
      const chatText = String(msg.text || '').trim().slice(0, 100);
      if (chatText.length > 0) {
        broadcast({
          type: 'chat_message',
          sender: player.name,
          color: player.color,
          text: chatText,
          time: new Date().toLocaleTimeString()
        });
      }
      break;
  }
}

// Регулярная рассылка состояния мира (20 FPS)
setInterval(() => {
  if (clients.size === 0) return;

  // Серверный погодный цикл
  worldState.weatherTimer++;
  if (worldState.altarPlacedRelics >= 7) {
    worldState.weatherState = 'Clear';
  } else {
    if (worldState.weatherTimer < 1400) worldState.weatherState = 'Clear';
    else if (worldState.weatherTimer < 2000) worldState.weatherState = 'Fog';
    else if (worldState.weatherTimer < 3000) worldState.weatherState = 'Blizzard';
    else worldState.weatherTimer = 0;
  }

  const syncPayload = {
    type: 'world_sync',
    weatherState: worldState.weatherState,
    altarPlacedRelics: worldState.altarPlacedRelics,
    isBunkerOpen: worldState.isBunkerOpen,
    players: Array.from(clients.values())
  };

  broadcast(syncPayload);
}, 50);

server.listen(PORT, () => {
  console.log(`\n======================================================`);
  console.log(`❄️  SURVIVE THE COLD: MULTIPLAYER SERVER IS LIVE!`);
  console.log(`🌐  Локальный адрес: http://localhost:${PORT}`);
  console.log(`👥  Сетевой протокол: WebSocket RFC 6455`);
  console.log(`======================================================\n`);
});
