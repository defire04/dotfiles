import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasma5support 2.0 as P5Support

// Батарея в панели: значок, процент и мелкие ватты.
// Клик — окошко с двумя вкладками (листаются): «Сейчас» (ватты, топ процессов)
// и «Датчики» (температуры, вентиляторы, ватты, NVIDIA; мин/макс за мониторинг).
PlasmoidItem {
    id: root

    property string batteryPath: ""
    property string acPath: ""
    property int percent: -1
    property string status: ""      // Charging / Discharging / Full / Not charging
    property bool acOnline: false
    property real watts: 0
    property real voltage: 0        // В
    property real chargeNow: 0      // мкА·ч
    property real chargeFull: 0
    property real chargeDesign: 0
    property int chargeLimit: 100   // порог заряда (asusctl / ROG Control Center)
    property real voltageDesign: 0  // номинальное напряжение, В — для перевода мА·ч в Вт·ч
    property string rogProfile: ""  // quiet / balanced / performance (platform_profile)
    property string muxSet: ""      // gpu_mux_mode: 1 гибрид, 0 Ultimate — действует после перезагрузки
    property string muxNow: ""      // фактический: экран на AMD -> "1", иначе "0"
    property bool eco: false        // dgpu_disable: NVIDIA выключена
    property string uv: ""          // андервольт CPU (-15 …), "" — не установлен cpu-undervolt
    property bool ecoBoot: false
    property string kbd: ""         // подсветка клавиатуры 0..3
    property var ppt: []            // [CPU SPL, sPPT, fPPT, NVIDIA TGP, Dynamic Boost], W    // выбрана «Интегрированная»: NVIDIA выключается при загрузке
    // Режим видеокарты как в ROG Control Center; для Ultimate — то, что будет после перезагрузки
    readonly property string gpuModeSet: muxSet === "0" ? "ultimate" : (eco || ecoBoot) ? "integrated" : muxSet === "1" ? "hybrid" : ""
    property var topList: []        // [{name, cpu}] — топ процессов, всегда topRows строк
    property var topAvg: ({})       // имя -> сглаженный % CPU (чтобы список не прыгал)
    readonly property int topRows: 15   // сколько показать — решает высота окошка (минимум 5)
    property string amdBusy: ""
    property string nvidiaState: ""
    property string cpuTotal: ""
    property int tasks: 0
    property real socWatts: -1      // весь чип AMD, W
    property real gfxWatts: 0       // встроенная графика
    property real coreWatts: 0      // ядра процессора
    property bool pinned: false     // кнопка-булавка: окошко не закрывается при клике мимо
    property var lastCharge: null   // {start, from, end, to}: секунды и проценты; end 0 — ещё на зарядке

    // Вкладка «Датчики»
    property var cur: ({})          // ключ -> текущее значение
    property var stats: ({})        // ключ -> {min, max} за мониторинг
    property bool monitoring: false
    property double monStart: 0
    property double monEnd: 0
    property var cpuPrev: null      // [total, idle] из /proc/stat прошлого опроса
    readonly property bool nvAwake: cur.nv_state === "D0"

    // ключ, подпись, единица, знаков после запятой, заголовок группы перед строкой
    readonly property var sensorDefs: [
        { key: "t_cpu",   name: "Процессор (Tctl)",  unit: "°C", dec: 0, header: "Температуры" },
        { key: "t_amd",   name: "Графика AMD",       unit: "°C", dec: 0 },
        { key: "nv_temp", name: "NVIDIA",            unit: "°C", dec: 0, nv: true },
        { key: "t_ssd",   name: "SSD",               unit: "°C", dec: 0 },
        { key: "t_wifi",  name: "Wi-Fi",             unit: "°C", dec: 0 },
        { key: "t_board", name: "Плата (ACPI)",      unit: "°C", dec: 0 },
        { key: "fan_cpu", name: "CPU",               unit: "", dec: 0, header: "Вентиляторы, об/мин" },
        { key: "fan_gpu", name: "GPU",               unit: "", dec: 0 },
        { key: "bat_w",   name: "Батарея (весь ноут)", unit: "W", dec: 1, header: "Питание" },
        { key: "soc_w",   name: "Чип AMD",           unit: "W", dec: 1 },
        { key: "core_w",  name: "  ядра процессора", unit: "W", dec: 1 },
        { key: "gfx_w",   name: "  графика AMD",     unit: "W", dec: 1 },
        { key: "nv_w",    name: "NVIDIA",            unit: "W", dec: 1, nv: true },
        { key: "cpu",     name: "Процессор",         unit: "%", dec: 0, header: "Нагрузка" },
        { key: "amd",     name: "Графика AMD",       unit: "%", dec: 0 },
        { key: "nv_util", name: "NVIDIA",            unit: "%", dec: 0, nv: true },
        { key: "nv_clk",  name: "NVIDIA, частота",   unit: "МГц", dec: 0, nv: true },
        { key: "nv_mem",  name: "NVIDIA, память",    unit: "МиБ", dec: 0, nv: true },
        { key: "ram",     name: "ОЗУ",               unit: "%", dec: 0 }
    ]

    hideOnWindowDeactivate: !pinned

    // Скрипты рядом, в contents/code/
    function codePath(f) { return "sh '" + Qt.resolvedUrl("../code/" + f).toString().replace("file://", "") + "'" }
    readonly property string topCmd: codePath("top.sh")
    readonly property string chargeCmd: codePath("charge.sh")
    readonly property string sensorsCmd: codePath("sensors.sh") + (monitoring ? " nv" : "")

    readonly property bool charging: status === "Charging"
    readonly property string iconName: {
        if (percent < 0) return "battery-missing"
        var step = Math.round(percent / 10) * 10
        var name = "battery-" + (step < 10 ? "00" + step : step < 100 ? "0" + step : "100")
        return (charging || (acOnline && status !== "Discharging")) ? name + "-charging" : name
    }
    readonly property string wattsText: {
        if (acOnline && Math.abs(watts) < 0.1) return ""
        return Math.abs(watts).toLocaleString(Qt.locale(), 'f', 1) + " W"
    }
    // Сколько берём от блока питания (оценка; датчика на входе нет):
    // в батарею + чип AMD (меряется) + «остальное» (выучено от батареи) + NVIDIA (если известна)
    readonly property real acEstimate: {
        if (!acOnline || socWatts < 0) return -1
        var intoBattery = charging ? Math.abs(watts) : 0
        return intoBattery + socWatts + plasmoid.configuration.restWatts + (nvAwake && cur.nv_w !== undefined ? cur.nv_w : 0)
    }
    readonly property bool acEstimateMissesNvidia: nvAwake && cur.nv_w === undefined

    // Учим «остальное» от батареи, когда NVIDIA спит (иначе её ватты попали бы сюда)
    function learnRest() {
        if (acOnline || charging || socWatts < 0 || nvAwake || Math.abs(watts) < 1) return
        var rest = Math.abs(watts) - socWatts
        if (rest < 1 || rest > 30) return
        var old = plasmoid.configuration.restWatts
        plasmoid.configuration.restWatts = Math.round((old * 0.9 + rest * 0.1) * 10) / 10
    }

    readonly property string statusText: charging ? "Заряжается" : status === "Full" ? "Заряжена"
                                       : acOnline ? "От сети" : "Разряжается"

    preferredRepresentation: compactRepresentation
    toolTipMainText: "Батарея " + (percent >= 0 ? percent + "%" : "—")
    toolTipSubText: wattsText ? statusText + " · " + wattsText : statusText

    // без батареи (десктоп) виджет не занимает места
    Plasmoid.status: batteryPath ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus

    // В панели: ватты, значок, процент. Клик — окошко.
    compactRepresentation: MouseArea {
        visible: root.batteryPath !== ""
        Layout.minimumWidth: row.implicitWidth
        Layout.preferredWidth: row.implicitWidth
        Layout.maximumWidth: row.implicitWidth
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: row
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            // красная точка — идёт мониторинг
            Rectangle {
                visible: root.monitoring
                color: Kirigami.Theme.negativeTextColor
                radius: width / 2
                Layout.preferredWidth: Kirigami.Units.smallSpacing * 2
                Layout.preferredHeight: Layout.preferredWidth
            }
            PlasmaComponents.Label {
                visible: text !== ""
                text: root.wattsText
                font.pointSize: Math.max(plasmoid.configuration.fontSize - 3, 7)
                opacity: 0.6
                Layout.rightMargin: Kirigami.Units.largeSpacing
            }
            Kirigami.Icon {
                source: root.iconName
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            }
            PlasmaComponents.Label {
                text: root.percent >= 0 ? root.percent + "%" : "—"
                font.pointSize: plasmoid.configuration.fontSize
                font.bold: plasmoid.configuration.fontBold
            }
        }
    }

    onExpandedChanged: if (root.expanded) { topAvg = ({}); ds.connectSource(root.topCmd); ds.connectSource(root.sensorsCmd) }

    // Топ процессов — только пока окошко открыто (top занимает 1 с)
    Timer {
        interval: 3000
        repeat: true
        running: root.expanded
        onTriggered: ds.connectSource(root.topCmd)
    }
    // Датчики — пока окошко открыто или идёт мониторинг
    Timer {
        interval: 2000
        repeat: true
        running: root.expanded || root.monitoring
        onTriggered: ds.connectSource(root.sensorsCmd)
    }
    // Тикает длительность мониторинга в окошке
    Timer {
        id: clock
        property double now: Date.now()
        interval: 1000
        repeat: true
        running: root.monitoring && root.expanded
        onTriggered: now = Date.now()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 23
        Layout.preferredHeight: col.implicitHeight + Kirigami.Units.largeSpacing * 2
        // min = max: окошко ровно по содержимому. Иначе Plasma берёт запомненный размер
        // (popupHeight в appletsrc) и снизу остаётся пустота
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight
        Layout.maximumWidth: Layout.preferredWidth
        Layout.maximumHeight: Layout.preferredHeight

        component Row2: RowLayout {
            property alias name: n.text
            property alias value: v.text
            property bool strong: false
            Layout.fillWidth: true
            PlasmaComponents.Label { id: n; Layout.fillWidth: true; elide: Text.ElideRight; font.bold: strong }
            PlasmaComponents.Label { id: v; font.bold: strong; font.features: { "tnum": 1 } }
        }
        // Группа строк под заголовком
        component Card: ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
        }
        component Caption: PlasmaComponents.Label {
            opacity: 0.6
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            Layout.topMargin: Kirigami.Units.smallSpacing
        }
        component Num: PlasmaComponents.Label {
            horizontalAlignment: Text.AlignRight
            font.features: { "tnum": 1 }
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Kirigami.Icon {
                    source: root.iconName
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }
                ColumnLayout {
                    spacing: 0
                    Kirigami.Heading { level: 3; text: root.percent >= 0 ? root.percent + "%" : "—" }
                    // «Заряжается · до 100 % 22 мин» / «Разряжается · осталось 4 ч 10 мин»
                    PlasmaComponents.Label {
                        opacity: 0.7
                        text: root.statusText + (root.timeLeft ? " · " + root.timeLeft.replace(" ~", " ").replace("Осталось", "осталось").replace("До", "до") : "")
                    }
                }
                Item { Layout.fillWidth: true }
                // Ватты со знаком и подписью: на зарядке — сколько входит в батарею (не расход
                // ноутбука, он от сети не виден), от батареи — весь расход ноутбука
                ColumnLayout {
                    spacing: 0
                    visible: root.wattsText !== ""
                    Kirigami.Heading {
                        level: 3
                        Layout.alignment: Qt.AlignRight
                        text: (root.charging ? "+" : root.acOnline ? "" : "−") + root.wattsText
                        color: root.charging ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                    }
                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignRight
                        opacity: 0.6
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        text: root.charging ? "в батарею" : root.acOnline ? "" : "расход"
                              + (root.acEstimate >= 0 ? (root.charging ? " · " : "") + "от сети ≈ " + Math.round(root.acEstimate) + " W" + (root.acEstimateMissesNvidia ? " + NVIDIA" : "") : "")
                        PlasmaComponents.ToolTip.text: root.acOnline
                            ? "«в батарею» — меряется. «от сети» — оценка ±2–3 W: в батарею + чип AMD + экран/ОЗУ/Wi-Fi/SSD (" + plasmoid.configuration.restWatts.toLocaleString(Qt.locale(), 'f', 1) + " W, выучено от батареи)" + (root.acEstimateMissesNvidia ? ". NVIDIA работает — её ватты видны только при мониторинге" : "")
                            : "Сколько отдаёт батарея — это весь расход ноутбука"
                        PlasmaComponents.ToolTip.visible: wh.hovered
                        HoverHandler { id: wh }
                    }
                }
                PlasmaComponents.ToolButton {
                    icon.name: "window-pin"
                    checkable: true
                    checked: root.pinned
                    onToggled: root.pinned = checked
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: root.pinned ? "Открепить" : "Закрепить"
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                    PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            PlasmaComponents.ProgressBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                from: 0; to: 100
                value: Math.max(root.percent, 0)
            }

            PlasmaComponents.TabBar {
                id: tabs
                Layout.fillWidth: true
                currentIndex: swipe.currentIndex
                PlasmaComponents.TabButton { text: "Сейчас" }
                PlasmaComponents.TabButton { text: "Датчики" + (root.monitoring ? " ●" : "") }
                PlasmaComponents.TabButton { text: "Режимы" }
            }

            QQC2.SwipeView {
                id: swipe
                Layout.fillWidth: true
                // все вкладки одной высоты — по самой длинной; на «Сейчас» свободное место
                // занимает список процессов
                Layout.preferredHeight: Math.max(page1.implicitHeight, page2.implicitHeight, page3.implicitHeight)
                currentIndex: tabs.currentIndex
                clip: true

                // ---- Вкладка «Сейчас»: куда уходят ватты и кто грузит процессор
                Item {
                ColumnLayout {
                    id: page1
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    Caption { text: "Батарея"; visible: root.chargeFull > 0 }
                    Card {
                        visible: root.chargeFull > 0
                        Row2 {
                            name: "Здоровье"
                            value: Math.round(root.chargeFull / root.chargeDesign * 100) + " %"
                                   + (root.voltageDesign ? "  (" + root.fmtWh(root.chargeFull) + " из " + root.fmtWh(root.chargeDesign) + " Вт·ч)" : "")
                            PlasmaComponents.ToolTip.text: "Сколько энергии батарея вмещает сейчас и сколько вмещала новой. Со временем ёмкость падает — это нормально"
                            PlasmaComponents.ToolTip.visible: hh0.hovered
                            HoverHandler { id: hh0 }
                        }
                        Row2 {
                            visible: root.lastChargeText !== ""
                            name: root.lastCharge && !root.lastCharge.end ? "На зарядке" : "Последняя зарядка"
                            value: root.lastChargeText
                            PlasmaComponents.ToolTip.text: !root.lastCharge ? "" : !root.lastCharge.end
                                ? "Подключена " + root.fmtWhen(root.lastCharge.start)
                                : "Заряжалась " + root.fmtWhen(root.lastCharge.start) + " – " + root.fmtWhen(root.lastCharge.end)
                                  + ", от батареи уже " + root.fmtHours((Date.now() / 1000 - root.lastCharge.end) / 3600)
                            PlasmaComponents.ToolTip.visible: hh1.hovered
                            HoverHandler { id: hh1 }
                        }
                    }

                    // Чип меряется и от сети; «Экран, ОЗУ…» — только от батареи (нужен общий расход)
                    Caption { text: "Питание"; visible: root.socWatts >= 0 }
                    Card {
                        visible: root.socWatts >= 0
                        Row2 { name: "Ядра процессора"; value: root.fmtW(root.coreWatts) }
                        Row2 { name: "Графика AMD"; value: root.fmtW(root.gfxWatts) }
                        Row2 {
                            name: "Остальное в чипе"
                            value: root.fmtW(root.socWatts - root.gfxWatts - root.coreWatts)
                            PlasmaComponents.ToolTip.text: "Контроллер памяти, шина, видеодекодер, вывод на экран"
                            PlasmaComponents.ToolTip.visible: hh.hovered
                            HoverHandler { id: hh }
                        }
                        Row2 {
                            visible: !root.acOnline
                            name: "Экран, ОЗУ, Wi-Fi, SSD"
                            value: root.fmtW(Math.abs(root.watts) - root.socWatts)
                            PlasmaComponents.ToolTip.text: "Отдельных датчиков нет: разница между батареей и чипом. Экран ~4,5–5 W (замер 30.09, яркость 45 %)"
                            PlasmaComponents.ToolTip.visible: hh2.hovered
                            HoverHandler { id: hh2 }
                        }
                    }

                    Caption { text: "Процессор" + (root.cpuTotal ? " · " + root.cpuTotal + " %, процессов " + root.tasks : "") }
                    // Растягивается на свободное место: строк столько, сколько влезает (минимум 5)
                    Item {
                        id: procArea
                        readonly property real rowH: rowMeasure.implicitHeight
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: rowH * 5
                        implicitHeight: rowH * 5
                        clip: true
                        PlasmaComponents.Label { id: rowMeasure; visible: false; text: "X" }
                        ColumnLayout {
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            spacing: 0
                            Repeater {
                                model: root.topList.slice(0, Math.max(1, Math.floor(procArea.height / procArea.rowH)))
                                delegate: Row2 {
                                    required property var modelData
                                    required property int index
                                    name: modelData.name
                                    value: modelData.cpu
                                    strong: index === 0
                                }
                            }
                            PlasmaComponents.Label {
                                visible: root.topList.length === 0
                                text: root.nvidiaState ? "всё почти простаивает" : "собираю…"
                                opacity: 0.7
                            }
                        }
                    }

                    Caption { text: "Видеокарты"; visible: root.nvidiaState !== "" }
                    Card {
                        visible: root.nvidiaState !== ""
                        Row2 { name: "AMD (встроенная)"; value: root.amdBusy + " %" }
                        Row2 { name: "NVIDIA"; value: root.nvidiaState }
                    }
                }
                }

                // ---- Вкладка «Датчики»: как psensor, мин/макс с начала мониторинга
                Item {
                ColumnLayout {
                    id: page2
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                        PlasmaComponents.Button {
                            icon.name: root.monitoring ? "media-playback-stop" : "media-record"
                            text: root.monitoring ? "Остановить" : "Начать мониторинг"
                            PlasmaComponents.ToolTip.text: "Мин и макс — с момента нажатия. Идёт и при закрытом окошке"
                            PlasmaComponents.ToolTip.visible: hovered
                            PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                            onClicked: root.monitoring ? root.stopMonitoring() : root.startMonitoring()
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            visible: root.monStart !== 0
                            opacity: 0.7
                            text: (root.monitoring ? "идёт " : "было ")
                                  + root.fmtDuration((root.monitoring ? clock.now : root.monEnd) - root.monStart)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Caption { text: "Датчик"; Layout.fillWidth: true }
                        Caption { text: "Сейчас"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: Kirigami.Units.gridUnit * 4 }
                        Caption { text: "Мин"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: Kirigami.Units.gridUnit * 4 }
                        Caption { text: "Макс"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: Kirigami.Units.gridUnit * 4 }
                    }

                    Repeater {
                        model: root.sensorDefs
                        delegate: ColumnLayout {
                            required property var modelData
                            required property int index
                            readonly property var st: root.stats[modelData.key]
                            spacing: 0
                            Layout.fillWidth: true
                            // строки NVIDIA — только когда она работает или уже есть мин/макс
                            visible: !modelData.nv || modelData.key === "nv_temp" || root.nvAwake || st !== undefined

                            Caption { visible: modelData.header !== undefined; text: modelData.header || "" }
                            // строки через одну с лёгкой полосой; полоса за краями — размер не меняется
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: srow.implicitHeight
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.leftMargin: -Kirigami.Units.smallSpacing
                                    anchors.rightMargin: -Kirigami.Units.smallSpacing
                                    radius: Kirigami.Units.cornerRadius
                                    color: index % 2 ? Qt.alpha(Kirigami.Theme.textColor, 0.05) : "transparent"
                                }
                            RowLayout {
                                id: srow
                                anchors.fill: parent
                                PlasmaComponents.Label {
                                    text: modelData.name
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Num {
                                    text: modelData.nv && !root.nvAwake
                                        ? (root.cur.nv_state === "off" ? "выкл" : root.cur.nv_state ? "спит" : "—")
                                        : root.fmtSensor(modelData, root.cur[modelData.key])
                                }
                                Num { text: st ? root.fmtSensor(modelData, st.min) : "—"; opacity: 0.7 }
                                Num { text: st ? root.fmtSensor(modelData, st.max) : "—"; opacity: 0.7 }
                            }
                            }
                        }
                    }
                }
                }

                // ---- Вкладка «Режимы»: профиль питания и порог заряда
                Item {
                ColumnLayout {
                    id: page3
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    spacing: Kirigami.Units.smallSpacing

                    // Переключатель-сегменты в рамке; выбранный — акцентом и жирным
                    component Choice: Item {
                        id: choice
                        property var options: []     // [{id, name, icon}]
                        property string current: ""
                        property bool enabledAll: true
                        property bool equalWidth: true   // false — ширина по тексту (длинные названия)
                        signal picked(string id)
                        Layout.fillWidth: true
                        implicitHeight: seg.implicitHeight + 4

                        Rectangle {
                            anchors.fill: parent
                            radius: Kirigami.Units.cornerRadius
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.04)
                            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
                        }
                        RowLayout {
                            id: seg
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 2
                            Repeater {
                                model: choice.options
                                delegate: PlasmaComponents.Button {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: choice.equalWidth ? 1 : implicitWidth
                                    icon.name: modelData.icon || ""
                                    text: modelData.name
                                    checkable: true
                                    checked: choice.current === modelData.id
                                    highlighted: checked
                                    font.bold: checked
                                    enabled: choice.enabledAll
                                    onClicked: { checked = Qt.binding(() => choice.current === modelData.id); choice.picked(modelData.id) }
                                }
                            }
                        }
                    }

                    // Заголовок блока; пояснение — во всплывающей подсказке
                    component Section: PlasmaComponents.Label {
                        property string tip: ""
                        opacity: 0.6
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.topMargin: Kirigami.Units.largeSpacing
                        PlasmaComponents.ToolTip.text: tip
                        PlasmaComponents.ToolTip.visible: tip !== "" && sh.hovered
                        PlasmaComponents.ToolTip.delay: Kirigami.Units.toolTipDelay
                        HoverHandler { id: sh }
                    }

                    Section {
                        text: "Профиль работы"
                        Layout.topMargin: 0
                        tip: "Тот же ползунок KDE. ROG ставит сам: от сети — Производительный, от батареи — Тихий"
                    }
                    Choice {
                        options: [
                            { id: "quiet", name: "Тихий" },
                            { id: "balanced", name: "Сбалансированный" },
                            { id: "performance", name: "Производительный" }
                        ]
                        current: root.rogProfile
                        equalWidth: false
                        onPicked: id => root.setRogProfile(id)
                    }

                    Section {
                        text: "Видеокарта · NVIDIA " + (root.eco ? "выключена" : root.nvAwake ? "работает" : "спит")
                        tip: "Интегрированная — NVIDIA выключена (~0 W). Гибридная — включается сразу, для игр. Ultimate — экран на NVIDIA, после перезагрузки"
                    }
                    Choice {
                        options: [
                            { id: "integrated", name: "Интегрированная" },
                            { id: "hybrid", name: "Гибридная" },
                            { id: "ultimate", name: "Ultimate" }
                        ]
                        current: root.gpuModeSet
                        onPicked: id => root.setGpuMode(id)
                    }
                    PlasmaComponents.Label {
                        readonly property bool muxPending: root.muxNow !== "" && root.muxSet !== root.muxNow
                        readonly property bool ecoPending: root.ecoBoot && !root.eco
                        visible: muxPending || ecoPending
                        color: Kirigami.Theme.negativeTextColor
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        text: "⟳ После перезагрузки: " + (muxPending ? (root.muxSet === "0" ? "Ultimate" : "Гибридная") : "Интегрированная")
                    }

                    Section {
                        text: "Андервольт CPU"
                        visible: root.uv !== ""
                        tip: "Curve Optimizer, как в G-Helper. Держится после сна и смены профиля. При зависаниях — уменьшить"
                    }
                    Choice {
                        visible: root.uv !== ""
                        options: [{ id: "0", name: "Выкл" }, { id: "-10", name: "−10" }, { id: "-15", name: "−15" }, { id: "-20", name: "−20" }]
                        current: root.uv
                        onPicked: id => root.setUv(id)
                    }

                    Section {
                        text: "Заряжать до"
                        tip: "Если ноут почти всегда от сети — 80 % продлевает жизнь батареи. Перед поездкой — 100 %"
                    }
                    Choice {
                        options: [{ id: "60", name: "60 %" }, { id: "80", name: "80 %" }, { id: "100", name: "100 %" }]
                        current: String(root.chargeLimit)
                        onPicked: id => root.setChargeLimit(parseInt(id, 10))
                    }

                    Section { text: "Подсветка клавиатуры"; visible: root.kbd !== "" }
                    Choice {
                        visible: root.kbd !== ""
                        options: [{ id: "0", name: "Выкл" }, { id: "1", name: "Низкая" }, { id: "2", name: "Средняя" }, { id: "3", name: "Высокая" }]
                        current: root.kbd
                        onPicked: id => root.setKbd(id)
                    }

                    Section {
                        text: "Лимиты мощности"
                        visible: root.ppt.length >= 5
                        tip: "Задаёт прошивка ASUS для текущего профиля. CPU: длительный / долгий буст / короткий буст. NVIDIA: TGP + Dynamic Boost"
                    }
                    ColumnLayout {
                        visible: root.ppt.length >= 5
                        spacing: 0
                        Layout.fillWidth: true
                        Row2 { name: "CPU"; value: root.ppt.slice(0, 3).join(" / ") + " W" }
                        Row2 { name: "NVIDIA"; value: root.ppt[3] + " W + " + root.ppt[4] + " W буст" }
                    }
                }
                }
            }
        }
    }

    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
            root.handle(source, data["exit code"] === 0 || source.startsWith("grep ") ? data["stdout"] : null)
        }
    }

    function handle(source, out) {
        if (source === topCmd) {
            if (out !== null) parseTop(out)
            return
        }
        if (source === chargeCmd) {
            var c = (out || "").trim().split(" ")
            lastCharge = c[0] === "charge" ? { start: +c[1], from: +c[2], end: +c[3], to: +c[4] } : null
            return
        }
        if (source === sensorsCmd) {
            if (out !== null) parseSensors(out)
            return
        }
        if (source === "ls /sys/class/power_supply") {
            var devs = (out || "").split("\n")
            var bat = devs.filter(d => d.startsWith("BAT"))[0]
            var ac = devs.filter(d => d.startsWith("AC") || d.startsWith("ADP"))[0]
            if (bat) batteryPath = "/sys/class/power_supply/" + bat
            if (ac) acPath = "/sys/class/power_supply/" + ac
            refresh()
            return
        }
        // остальное — команды переключения (asusctl, gpu-toggle-ui): их вывод не нужен
        if (!source.startsWith("grep ") || !out) return
        // строки «путь:значение» от grep -H
        var v = {}
        out.split("\n").forEach(l => {
            var i = l.indexOf(":")
            if (i > 0) v[l.slice(0, i).split("/").pop()] = l.slice(i + 1)
        })
        percent = parseInt(v.capacity, 10)
        status = v.status || ""
        voltage = parseFloat(v.voltage_now) / 1e6
        watts = voltage * parseFloat(v.current_now) / 1e6
        chargeNow = parseFloat(v.charge_now) || 0
        chargeFull = parseFloat(v.charge_full) || 0
        chargeDesign = parseFloat(v.charge_full_design) || 0
        voltageDesign = (parseFloat(v.voltage_min_design) || 0) / 1e6
        chargeLimit = parseInt(v.charge_control_end_threshold, 10) || 100
        acOnline = v.online === "1"
        if (isNaN(watts)) watts = 0
    }

    // «3 ч 25 мин»
    function fmtHours(h) {
        if (!isFinite(h) || h <= 0) return "—"
        var m = Math.round(h * 60)
        return (m >= 60 ? Math.floor(m / 60) + " ч " : "") + (m % 60) + " мин"
    }
    readonly property string timeLeft: {
        var w = Math.abs(watts)
        if (w < 0.5 || !chargeFull) return ""
        if (status === "Discharging") return "Осталось ~" + fmtHours(chargeNow * voltage / 1e6 / w)
        if (charging) return "До " + chargeLimit + " % ~" + fmtHours((chargeFull * chargeLimit / 100 - chargeNow) * voltage / 1e6 / w)
        return ""
    }

    // «сегодня 00:23» / «вчера 22:21» / «28.09 14:05»
    function fmtWhen(sec) {
        var d = new Date(sec * 1000), today = new Date()
        today.setHours(0, 0, 0, 0)
        var days = Math.round((today - new Date(d).setHours(0, 0, 0, 0)) / 86400000)
        var day = days === 0 ? "сегодня" : days === 1 ? "вчера" : Qt.formatDate(d, "dd.MM")
        return day + " " + Qt.formatTime(d, "hh:mm")
    }
    // «15 → 100 % · сегодня 00:23» (когда сняли с зарядки) или «с 15 % · с 22:21» (ещё заряжается)
    readonly property string lastChargeText: {
        var c = lastCharge
        if (!c) return ""
        if (!c.end) return (c.from ? "с " + c.from + " % · " : "") + "с " + fmtWhen(c.start).replace("сегодня ", "")
        return (c.from ? c.from + " → " : "") + c.to + " % · " + fmtWhen(c.end)
    }

    // мкА·ч -> Вт·ч по номинальному напряжению
    function fmtWh(c) {
        return Math.round(c / 1e6 * voltageDesign)
    }

    // Режим ROG через asusd, как в ROG Control Center
    function setRogProfile(p) {
        rogProfile = p
        ds.connectSource("asusctl profile set " + p.charAt(0).toUpperCase() + p.slice(1))
    }

    // Режим видеокарты — всё делает gpu-toggle (root, через gpu-toggle-ui с уведомлением):
    // integrated — NVIDIA выключается при каждой загрузке (сразу — если никто не держит),
    // hybrid — сразу; ultimate — MUX, после перезагрузки
    function setGpuMode(m) {
        if (m === "integrated") ecoBoot = true
        else ecoBoot = false
        ds.connectSource("$HOME/.local/bin/gpu-toggle-ui mode " + m)
    }

    // Андервольт CPU: sudo cpu-undervolt set N (разрешено без пароля в /etc/sudoers.d)
    function setUv(v) {
        uv = v
        ds.connectSource("sudo -n /usr/local/bin/cpu-undervolt set " + v)
    }

    function setKbd(level) {
        kbd = level
        ds.connectSource("asusctl leds set " + ["off", "low", "med", "high"][parseInt(level, 10)])
    }

    function fmtW(w) {
        return Math.max(w, 0).toLocaleString(Qt.locale(), 'f', 1) + " W"
    }

    function fmtSensor(def, v) {
        if (v === undefined || v === null || isNaN(v)) return "—"
        return Number(v).toLocaleString(Qt.locale(), 'f', def.dec) + (def.unit ? " " + def.unit : "")
    }

    function fmtDuration(ms) {
        var s = Math.max(Math.floor(ms / 1000), 0)
        var h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60)
        s = s % 60
        return (h ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    function startMonitoring() {
        stats = ({})
        monStart = Date.now()
        clock.now = monStart
        monEnd = 0
        monitoring = true
        ds.connectSource(sensorsCmd)
    }

    function stopMonitoring() {
        monitoring = false
        monEnd = Date.now()
    }

    function parseSensors(out) {
        var c = { nv_state: "" }
        out.trim().split("\n").forEach(l => {
            var f = l.trim().split(/\s+/)
            switch (f[0]) {
            case "t_cpu": case "t_amd": case "t_ssd": case "t_wifi": case "t_board":
                c[f[0]] = parseInt(f[1], 10) / 1000; break
            case "fan_cpu": case "fan_gpu": case "ram":
                c[f[0]] = parseFloat(f[1]); break
            case "amd_busy":
                c.amd = parseFloat(f[1]); break
            case "bat":
                // от сети батарея не показывает расход ноутбука
                if (f[3] !== "1") c.bat_w = Math.abs(parseFloat(f[1]) * parseFloat(f[2]) / 1e12)
                break
            case "soc":
                c.soc_w = parseInt(f[1], 10) / 1000
                c.gfx_w = parseInt(f[2], 10) / 1000
                c.core_w = parseInt(f[3], 10) / 1000
                break
            case "cpu": {
                // user nice system idle iowait irq softirq steal
                var n = f.slice(1).map(x => parseInt(x, 10))
                var total = n.slice(0, 8).reduce((a, b) => a + b, 0)
                var idle = n[3] + n[4]
                if (cpuPrev && total > cpuPrev[0])
                    c.cpu = 100 * (1 - (idle - cpuPrev[1]) / (total - cpuPrev[0]))
                cpuPrev = [total, idle]
                break
            }
            case "rog":
                root.rogProfile = f[1]; break
            case "mux":
                root.muxSet = f[1] || ""
                root.muxNow = f[2] === "connected" ? "1" : f[2] ? "0" : ""
                break
            case "eco":
                root.eco = f[1] === "1"; break
            case "uv":
                root.uv = f[1] || ""; break
            case "kbd":
                root.kbd = f[1] || ""; break
            case "ppt":
                root.ppt = f.slice(1).filter(x => x !== ""); break
            case "ecoboot":
                root.ecoBoot = f[1] === "1"; break
            case "nv_state":
                c.nv_state = f[1]; break
            case "nv":
                c.nv_temp = parseFloat(f[1]); c.nv_w = parseFloat(f[2]); c.nv_util = parseFloat(f[3])
                c.nv_clk = parseFloat(f[4]); c.nv_mem = parseFloat(f[5])
                break
            }
        })
        cur = c
        if (!monitoring) return
        var s = Object.assign({}, stats)
        for (var k in c) {
            var v = c[k]
            if (typeof v !== "number" || isNaN(v)) continue
            if (!s[k]) s[k] = { min: v, max: v }
            else s[k] = { min: Math.min(s[k].min, v), max: Math.max(s[k].max, v) }
        }
        stats = s
    }

    function parseTop(out) {
        var fresh = {}
        out.trim().split("\n").forEach(l => {
            var m = l.match(/^([0-9.]+) (.+)$/)
            if (l.startsWith("total ")) {
                var t = l.split(" ")
                cpuTotal = parseFloat(t[1]).toLocaleString(Qt.locale(), 'f', 1)
                tasks = parseInt(t[2], 10)
            } else if (l.startsWith("soc ")) {
                var w = l.split(" ")
                socWatts = parseInt(w[1], 10) / 1000
                gfxWatts = parseInt(w[2], 10) / 1000
                coreWatts = parseInt(w[3], 10) / 1000
                learnRest()
            } else if (l.startsWith("gpu ")) {
                var g = l.split(" ")
                amdBusy = g[1] || "?"
                nvidiaState = g[2] === "D3cold" ? "спит"
                            : g[2] === "off" ? "выключена" : "работает (" + g[2] + ")"
            } else if (m) {
                fresh[m[2]] = parseFloat(m[1])
            }
        })
        // Сглаживание: половина старого значения + половина нового; пропавший процесс
        // плавно угасает, а не исчезает сразу
        var first = Object.keys(topAvg).length === 0
        var avg = {}
        for (var k in topAvg) avg[k] = topAvg[k] / 2
        for (k in fresh) avg[k] = first ? fresh[k] : (avg[k] || 0) + fresh[k] / 2
        for (k in avg) if (avg[k] < 0.01) delete avg[k]
        topAvg = avg
        var list = Object.keys(avg).sort((x, y) => avg[y] - avg[x]).slice(0, topRows)
            .map(k => ({ name: k, cpu: avg[k].toLocaleString(Qt.locale(), 'f', 1) + " %" }))
        topList = list
    }

    function refresh() {
        if (!batteryPath) {
            ds.connectSource("ls /sys/class/power_supply")
            return
        }
        // один процесс grep на все файлы: запуск процесса дороже самого чтения
        var files = ["capacity", "status", "voltage_now", "current_now", "charge_now", "charge_full",
                     "charge_full_design", "voltage_min_design", "charge_control_end_threshold"]
                    .map(f => batteryPath + "/" + f)
        if (acPath) files.push(acPath + "/online")
        ds.connectSource("grep -sH . " + files.join(" "))
    }

    // Последняя зарядка (история UPower) — только пока окошко открыто: сразу и раз в 30 с
    Timer {
        interval: 30000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: ds.connectSource(root.chargeCmd)
    }

    Timer {
        interval: plasmoid.configuration.updateInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
