#!/bin/bash
# llama-server для pi на ноуте (RTX 5080 Laptop 16 ГБ, 30 ГиБ) в режиме роутера: модели и их настройки
# в ~/.config/llama/pi-models.ini, в видеопамяти одна за раз (--models-max 1). Pi выбирает модель через /model,
# роутер выгружает прежнюю и загружает новую (до минуты). По умолчанию Q4_K_XL (~/.pi/agent/settings.json).
exec llama-server --models-preset "$HOME/.config/llama/pi-models.ini" --models-max 1 --host 127.0.0.1 --port 8080
