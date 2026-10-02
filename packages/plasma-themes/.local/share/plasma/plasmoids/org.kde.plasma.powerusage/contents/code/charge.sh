#!/bin/sh
# Последняя зарядка по истории UPower (хранит её сам, без нашего фона).
# rate — запись каждые ~30 с с состоянием: по ней точно видно, когда подключили и отключили.
# charge — процент на каждом изменении: по нему «с какого процента» и «до какого».
# Вывод: charge <начало> <с %> <конец или 0, если ещё на зарядке> <до %>
dev=$(upower -e | grep -m1 battery_) || exit 1
hist() {
    gdbus call --system --dest org.freedesktop.UPower --object-path "$dev" \
        --method org.freedesktop.UPower.Device.GetHistory "$1" 2592000 5000 |
        tr ')' '\n' | sed 's/uint32 //g; s/[][(,]/ /g' | awk 'NF == 3'
}
# состояния UPower: 1 заряжается, 4 заряжена, 5 ждёт зарядки — всё это «от сети»
{ hist rate | sed 's/^/r /'; hist charge | sed 's/^/c /'; } | awk '
    $1 == "r" { n++; rt[n] = $2; ac[n] = ($4 == 1 || $4 == 4 || $4 == 5) }
    $1 == "c" { m++; ct[m] = $2; cp[m] = $3; cs[m] = $4 }
    END {
        # записи идут от новых к старым
        for (i = 1; i <= n && !ac[i]; i++) ;
        if (i > n) exit 1
        end = (i > 1) ? rt[i - 1] : 0           # первая запись «от батареи» после зарядки
        for (j = i; j < n && ac[j + 1]; j++) ;
        start = rt[j]
        # «до %»: последний процент не позже отключения; «с %»: последний процент от батареи до начала
        for (k = 1; k <= m; k++) if (!to && (end == 0 || ct[k] <= end)) to = cp[k]
        for (k = 1; k <= m; k++) if (ct[k] <= start && cs[k] == 2) { from = cp[k]; break }
        printf "charge %d %d %d %d\n", start, from, end, to
    }'
