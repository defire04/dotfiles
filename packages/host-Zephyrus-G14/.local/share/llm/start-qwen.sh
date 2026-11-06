#!/bin/bash
# Qwen3.8 27B (IQ4_XS) на RTX 5080 Laptop: API и чат на http://127.0.0.1:8080.
# Обычно запускается через qwen-web, qwen-code (они вызывают qwen-server.sh).
# Здесь настройки по умолчанию (32K, MTP 3, effort medium), флаги после имени скрипта их перекрывают.
# MTP задаётся переменной QWEN_MTP (0 = выключен): флаг --spec-type складывается в список, а не перекрывается.
# Настройки выбраны замерами 02–03.11.2026: ~/Programming/AI/llm-bench/results.md
LLM_DIR="$HOME/.local/share/llm"
MTP=${QWEN_MTP:-3}
spec=()
[ "$MTP" != 0 ] && spec=(--spec-type draft-mtp --spec-draft-n-max "$MTP")
exec llama-server \
    -m "$LLM_DIR/models/Qwen3.8-27B-UD-IQ4_XS.gguf" \
    --alias qwen3.8-27b \
    --host 127.0.0.1 --port 8080 \
    -ngl 99 -fa on -lm none -t 12 -np 1 \
    --ctx-size 32768 -ctk q4_0 -ctv q4_0 \
    "${spec[@]}" \
    --jinja --chat-template-file "$LLM_DIR/qwen3.8-chat.jinja" --reasoning-format deepseek \
    --reasoning-effort medium --no-context-shift --cache-reuse 256 \
    -b 2048 -ub 512 \
    --temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0 \
    "$@"
