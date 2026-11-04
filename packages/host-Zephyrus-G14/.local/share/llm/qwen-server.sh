#!/bin/bash
# Поднимает llama-server с Qwen на 127.0.0.1:8080 с нужными настройками и ждёт готовности.
# Использование: qwen-server.sh <окно> <mtp> [effort] [модель]
#   окно  — токенов контекста, например 32768
#   mtp   — сколько слов угадывает помощник MTP, 0 = без MTP
#   effort — xhigh | medium | low, по умолчанию medium (или $QWEN_EFFORT), только для 27b
#   модель — 27b (Qwen3.8-27B, start-qwen.sh) | moe (Qwen3.6-35B-A3B, start-qwen-moe.sh), по умолчанию 27b
# Если сервер уже работает с теми же настройками, ничего не делает; с другими перезапускает.
CTX=$1
MTP=$2
EFFORT=${3:-${QWEN_EFFORT:-medium}}
MODEL=${4:-27b}
URL=http://127.0.0.1:8080
LLM_DIR="$HOME/.local/share/llm"
STATE="$LLM_DIR/server.conf"
WANT="model=$MODEL ctx=$CTX mtp=$MTP effort=$EFFORT"
[ "$MODEL" = moe ] && WANT="model=moe ctx=$CTX mtp=$MTP"

if curl -sf "$URL/health" >/dev/null; then
    [ "$(cat "$STATE" 2>/dev/null)" = "$WANT" ] && exit 0
    echo "Перезапускаю Qwen: $(cat "$STATE" 2>/dev/null) → $WANT" >&2
    pkill -x llama-server
    while pgrep -x llama-server >/dev/null; do sleep 0.5; done
else
    echo "Запускаю Qwen: $WANT (лог: $LLM_DIR/server.log)..." >&2
fi

echo "$WANT" > "$STATE"
if [ "$MODEL" = moe ]; then
    QWEN_MTP="$MTP" setsid "$LLM_DIR/start-qwen-moe.sh" --ctx-size "$CTX" >"$LLM_DIR/server.log" 2>&1 &
else
    QWEN_MTP="$MTP" setsid "$LLM_DIR/start-qwen.sh" --ctx-size "$CTX" --reasoning-effort "$EFFORT" \
        >"$LLM_DIR/server.log" 2>&1 &
fi
for _ in $(seq 180); do
    curl -sf "$URL/health" >/dev/null && exit 0
    sleep 1
done
echo "Сервер не поднялся, смотри $LLM_DIR/server.log" >&2
exit 1
