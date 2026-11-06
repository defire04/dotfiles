#!/bin/bash
# llama-server для pi на ноуте (RTX 5080 Laptop 16 ГБ, 30 ГиБ). Настройки из замеров llm-bench:
# Q4_K_XL (22,9 ГБ): лучший прогон на ноуте (11 мин, 7,5 после починки); 24 слоя экспертов в оперативке
# под окно 256K с ~1,2 ГиБ запаса видеопамяти (04.11.2026); --load-mode none: +7%, 90 т/с против 85 (05.11.2026);
# --presence-penalty 1.5: без штрафа модель зацикливалась в размышлениях (ПК, прогоны pi3, pi3b, 06.11.2026).
# Если рядом тяжёлая IDEA и Docker и памяти мало: убрать --load-mode none или взять IQ4_XS с --n-cpu-moe 18.
exec llama-server \
  -m "$HOME/.local/share/llm/models/MoE/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf" --alias qwen3.6-35b-a3b \
  --host 127.0.0.1 --port 8080 -ngl 99 --n-cpu-moe ${QWEN_NCM:-24} --load-mode none -fa on -t 12 -np 1 \
  --ctx-size ${QWEN_CTX:-262144} -ctk q8_0 -ctv q8_0 --spec-type draft-mtp --spec-draft-n-max 2 \
  --jinja --reasoning-format deepseek --no-context-shift --cache-reuse 256 -b 2048 -ub 512 \
  --temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 1.5
