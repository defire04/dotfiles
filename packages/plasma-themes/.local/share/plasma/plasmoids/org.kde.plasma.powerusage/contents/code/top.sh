#!/bin/sh
# Для окошка виджета: топ-20 по процессору (% от всего CPU, процессы с одним именем
# суммируются), загрузка всего CPU и число процессов, мощность процессора со встроенной AMD,
# загрузка AMD и состояние NVIDIA. power_state не будит NVIDIA.
LC_ALL=C top -b -n 2 -d 1 -w 512 | awk -v n="$(nproc)" '
    /^top -/ { i++ }
    i == 2 && /^Tasks:/ { tasks = $2 }
    i == 2 && /^%Cpu/ { for (f = 1; f <= NF; f++) if ($(f + 1) ~ /^id/) idle = $f }
    i == 2 && $1 ~ /^[0-9]+$/ && $12 != "top" { c[$12] += $9 }
    END {
        printf "total %.1f %d\n", 100 - idle, tasks
        for (k in c) if (c[k] > 0) printf "%.2f %s\n", c[k] / n, k
    }' | { read -r total; echo "$total"; sort -rn | head -20; }
# Питание чипа из gpu_metrics встроенной AMD (формат v3.0, мВт, смещения по
# struct gpu_metrics_v3_0 в ядре): 112 — весь чип, 124 — графика, 132 — все ядра CPU.
# Остаток чипа — контроллер памяти, шина, видеодекодер, вывод на экран.
m=/sys/bus/pci/devices/0000:65:00.0/gpu_metrics
if [ "$(od -An -tu1 -j2 -N2 "$m" 2>/dev/null | tr -s ' ')" = " 3 0" ]; then
    echo "soc $(od -An -tu4 -j112 -N4 "$m") $(od -An -tu4 -j124 -N4 "$m") $(od -An -tu4 -j132 -N4 "$m")" | tr -s ' '
fi
echo "gpu $(cat /sys/bus/pci/devices/0000:65:00.0/gpu_busy_percent 2>/dev/null) $(cat /sys/bus/pci/devices/0000:64:00.0/power_state 2>/dev/null || echo off)"
