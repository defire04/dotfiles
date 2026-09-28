import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasma5support 2.0 as P5Support

// Батарея в панели: значок, процент и мелкие ватты
PlasmoidItem {
    id: root

    property string batteryPath: ""
    property string acPath: ""
    property int percent: -1
    property string status: ""      // Charging / Discharging / Full / Not charging
    property bool acOnline: false
    property real watts: 0

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

    preferredRepresentation: fullRepresentation
    toolTipMainText: "Батарея " + (percent >= 0 ? percent + "%" : "—")
    toolTipSubText: {
        var s = charging ? "Заряжается" : status === "Full" ? "Заряжена"
              : acOnline ? "От сети" : "Разряжается"
        return wattsText ? s + " · " + wattsText : s
    }

    // без батареи (десктоп) виджет не занимает места
    Plasmoid.status: batteryPath ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus

    fullRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing
        visible: root.batteryPath !== ""

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

    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
            root.handle(source, data["exit code"] === 0 ? data["stdout"] : null)
        }
    }

    function handle(source, out) {
        if (source === "ls /sys/class/power_supply") {
            var devs = (out || "").split("\n")
            var bat = devs.filter(d => d.startsWith("BAT"))[0]
            var ac = devs.filter(d => d.startsWith("AC") || d.startsWith("ADP"))[0]
            if (bat) batteryPath = "/sys/class/power_supply/" + bat
            if (ac) acPath = "/sys/class/power_supply/" + ac
            refresh()
            return
        }
        if (out === null) return
        // capacity, status, voltage_now, current_now, online
        var v = out.trim().split("\n")
        percent = parseInt(v[0], 10)
        status = v[1]
        watts = parseFloat(v[2]) / 1e6 * parseFloat(v[3]) / 1e6
        acOnline = v[4] === "1"
        if (isNaN(watts)) watts = 0
    }

    function refresh() {
        if (!batteryPath) {
            ds.connectSource("ls /sys/class/power_supply")
            return
        }
        var b = batteryPath
        ds.connectSource("cat " + b + "/capacity " + b + "/status " + b + "/voltage_now "
                + b + "/current_now" + (acPath ? " " + acPath + "/online" : ""))
    }

    Timer {
        interval: plasmoid.configuration.updateInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
