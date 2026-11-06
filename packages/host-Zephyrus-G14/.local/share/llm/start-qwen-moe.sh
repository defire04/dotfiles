#!/bin/bash
# Qwen3.6-35B-A3B (MoE, UD-Q4_K_XL 22,9 ГБ) на RTX 5080 Laptop: API на http://127.0.0.1:8080.
# Часть экспертов в оперативке (--n-cpu-moe), окно до 256K, ~78–88 т/с пусто (как IQ4_XS, квант точнее).
# --n-cpu-moe 24 подобран под 256K с ~1,2 ГиБ запаса видеопамяти (замер 04.11.2026, 23 впритык, 22 не влезает,
# ~/Programming/AI/llm-bench/runs/agent/qwen3.6-35b-a3b/fit). Прежний IQ4_XS: модель ...-UD-IQ4_XS.gguf и ncm 18. Своих уровней effort у модели нет.
# --load-mode none: файл целиком в памяти программы, эксперты не вытесняются из кэша (+7%, 90 т/с против 85, 05.11.2026).
# Сэмплинг «precise coding» из карточки Qwen3.6. Флаги после имени скрипта перекрывают эти.
LLM_DIR="$HOME/.local/share/llm"
MTP=${QWEN_MTP:-2}
spec=()
[ "$MTP" != 0 ] && spec=(--spec-type draft-mtp --spec-draft-n-max "$MTP")
exec llama-server \
    -m "$LLM_DIR/models/MoE/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf" \
    --alias qwen3.6-35b-a3b \
    --host 127.0.0.1 --port 8080 \
    -ngl 99 --n-cpu-moe 24 --load-mode none -fa on -t 12 -np 1 \
    --ctx-size 262144 -ctk q8_0 -ctv q8_0 \
    "${spec[@]}" \
    --jinja --reasoning-format deepseek \
    --no-context-shift --cache-reuse 256 \
    -b 2048 -ub 512 \
    --temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 0.0 \
    "$@"
