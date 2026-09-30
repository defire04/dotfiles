#!/bin/sh
# Для вкладки «Датчики» виджета: строки «ключ значение», только чтение sysfs — дёшево.
# NVIDIA (nvidia-smi) опрашивается, только если она уже проснулась (D0) и идёт мониторинг.
# Загрузку CPU виджет считает сам по разнице счётчиков /proc/stat между опросами.

for h in /sys/class/hwmon/hwmon*; do
    case "$(cat "$h/name")" in
        k10temp)  echo "t_cpu $(cat "$h/temp1_input")" ;;
        amdgpu)   echo "t_amd $(cat "$h/temp1_input")" ;;
        nvme)     echo "t_ssd $(cat "$h/temp1_input")" ;;
        mt7925*)  echo "t_wifi $(cat "$h/temp1_input")" ;;
        acpitz)   echo "t_board $(cat "$h/temp1_input")" ;;
        asus)     echo "fan_cpu $(cat "$h/fan1_input")"; echo "fan_gpu $(cat "$h/fan2_input")" ;;
    esac
done 2>/dev/null

b=/sys/class/power_supply/BAT1
echo "bat $(cat $b/current_now) $(cat $b/voltage_now) $(cat /sys/class/power_supply/ACAD/online)"

# Питание чипа AMD из gpu_metrics v3.0 (мВт): 112 — весь чип, 124 — графика, 132 — ядра CPU
m=/sys/bus/pci/devices/0000:65:00.0/gpu_metrics
if [ "$(od -An -tu1 -j2 -N2 "$m" 2>/dev/null | tr -s ' ')" = " 3 0" ]; then
    echo "soc $(od -An -tu4 -j112 -N4 "$m") $(od -An -tu4 -j124 -N4 "$m") $(od -An -tu4 -j132 -N4 "$m")" | tr -s ' '
fi
echo "amd_busy $(cat /sys/bus/pci/devices/0000:65:00.0/gpu_busy_percent 2>/dev/null)"

head -1 /proc/stat
awk '/^MemTotal/ {t = $2} /^MemAvailable/ {a = $2} END {printf "ram %.1f\n", (t - a) * 100 / t}' /proc/meminfo

nv=/sys/bus/pci/devices/0000:64:00.0
st=$(cat $nv/power_state 2>/dev/null || echo off)
echo "nv_state $st"
# Только во время мониторинга ($1 = nv): опрос поднимает частоту и не даёт карте уснуть
if [ "$st" = D0 ] && [ "$1" = nv ]; then
    # температура, мощность, загрузка, частота, память
    nvidia-smi --query-gpu=temperature.gpu,power.draw,utilization.gpu,clocks.gr,memory.used \
        --format=csv,noheader,nounits 2>/dev/null | tr -d ' ' | awk -F, '{print "nv", $1, $2, $3, $4, $5}'
fi

# Режим ROG (он же профиль питания KDE): quiet / balanced / performance
echo "rog $(cat /sys/firmware/acpi/platform_profile 2>/dev/null)"
# MUX: 1 = гибрид, 0 = Ultimate (значение после перезагрузки); dgpu_disable: 1 = Eco.
# Фактический режим — к какой видеокарте подключён экран: статус eDP у AMD (card* у 65:00.0).
# Статус eDP у NVIDIA не читаем — это разбудило бы её.
a=/sys/class/firmware-attributes/asus-armoury/attributes
edp=$(cat /sys/bus/pci/devices/0000:65:00.0/drm/card*/card*-eDP-*/status 2>/dev/null | head -1)
echo "mux $(cat $a/gpu_mux_mode/current_value 2>/dev/null) $edp"
echo "eco $(cat $a/dgpu_disable/current_value 2>/dev/null)"
# «Интегрированная» при загрузке (флаг ставит gpu-toggle mode integrated)
[ -e /var/lib/gpu-toggle/integrated ] && echo "ecoboot 1" || echo "ecoboot 0"
