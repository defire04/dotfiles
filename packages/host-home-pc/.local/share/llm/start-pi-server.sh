#!/bin/bash
# llama-server для qwen-pi на ПК (RTX 4070 Super 12 ГБ, 30 ГиБ). Настройки из замеров llm-bench 06.11.2026:
# IQ4_XS (18 ГБ) вместо Q4_K_XL, чтобы рядом работали IDEA и Docker (оперативки до 15 ГиБ против 28);
# 30 слоёв экспертов в оперативке: самый быстрый вариант с запасом видеопамяти от 1 ГБ (66 т/с на пустом окне);
# без --load-mode none: модель в кэше файлов, система отдаёт память IDEA, а не сжимает модель в zram;
# --presence-penalty 1.5: без штрафа модель дважды зацикливалась в размышлениях (прогоны pi3, pi3b).
exec "$HOME/.local/src/llama.cpp/build/bin/llama-server" \
  -m "$HOME/.local/share/llm/models/MoE/Qwen3.6-35B-A3B-UD-IQ4_XS.gguf" --alias qwen3.6-35b-a3b \
  --host 127.0.0.1 --port 8080 -ngl 99 --n-cpu-moe ${QWEN_NCM:-30} -fa on -t 8 -np 1 \
  --ctx-size ${QWEN_CTX:-204800} -ctk q8_0 -ctv q8_0 --spec-type draft-mtp --spec-draft-n-max 2 \
  --jinja --reasoning-format deepseek --no-context-shift --cache-reuse 256 -b 2048 -ub 512 \
  --temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 1.5
