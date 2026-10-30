pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.services

PanelWindow {
    id: menu
    signal dismissed()
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:vicho-battery-menu"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    function chooseProfile(name: string): bool {
        const profiles = {"power-saver": PowerProfile.PowerSaver, "balanced": PowerProfile.Balanced, "performance": PowerProfile.Performance}
        if (!(name in profiles) || (name === "performance" && !PowerProfiles.hasPerformanceProfile)) return false
        PowerProfiles.profile = profiles[name]
        return true
    }
    IpcHandler {
        target: "notch-battery-menu"
        function choose(name: string): bool { return menu.chooseProfile(name) }
        function close(): void { menu.dismissed() }
    }
    function duration(seconds: real): string {
        if (!Number.isFinite(seconds) || seconds <= 0) return "Calculando…"
        const minutes = Math.floor(seconds / 60)
        return Math.floor(minutes / 60) + " h " + String(minutes % 60).padStart(2, "0") + " min"
    }
    MouseArea { anchors.fill: parent; onPressed: menu.dismissed() }
    Rectangle {
        id: card
        anchors.right: parent.right; anchors.rightMargin: 12
        y: 46; width: Math.min(330, menu.width - 24)
        height: details.implicitHeight + 36
        radius: 14; color: "#f0242426"; border.width: 1; border.color: "#555558"
        MouseArea { anchors.fill: parent }
        ColumnLayout {
            id: details
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Batería"; color: "#eeeeee"; font.pixelSize: 15; font.bold: true; Layout.fillWidth: true }
                Text { text: Math.round(Battery.percentage * 100) + "%"; color: "#eeeeee"; font.pixelSize: 15 }
            }
            Text {
                Layout.fillWidth: true; color: "#bbbbbf"; font.pixelSize: 12; wrapMode: Text.Wrap
                text: Battery.isCharging ? "Cargando · adaptador conectado" : Battery.onBattery ? "Usando batería" : "Adaptador conectado · sin cargar"
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#454548" }
            RowLayout {
                Layout.fillWidth: true
                Text { text: Battery.isCharging ? "Potencia de carga" : "Consumo reportado"; color: "#bcbcc0"; font.pixelSize: 12; Layout.fillWidth: true }
                Text { text: Number.isFinite(Battery.energyRate) ? Math.abs(Battery.energyRate).toFixed(1) + " W" : "No disponible"; color: "#eeeeee"; font.pixelSize: 12 }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: Battery.isCharging ? "Hasta completar carga" : "Tiempo restante"; color: "#bcbcc0"; font.pixelSize: 12; Layout.fillWidth: true }
                Text { text: Battery.isCharging ? menu.duration(Battery.timeToFull) : Battery.onBattery ? menu.duration(Battery.timeToEmpty) : "Con corriente"; color: "#eeeeee"; font.pixelSize: 12 }
            }
            Text {
                Layout.fillWidth: true; text: "Estimaciones del sistema; varían con el uso."; color: "#99999f"; font.pixelSize: 11; wrapMode: Text.Wrap
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#454548" }
            Text { text: "Modo de energía"; color: "#eeeeee"; font.pixelSize: 12; font.bold: true }
            Repeater {
                model: [
                    { name: "Ahorro de batería", key: "power-saver", profile: PowerProfile.PowerSaver },
                    { name: "Balanceado", key: "balanced", profile: PowerProfile.Balanced },
                    { name: "Rendimiento", key: "performance", profile: PowerProfile.Performance }
                ]
                Controls.RadioDelegate {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.name
                    checked: PowerProfiles.profile === modelData.profile
                    enabled: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                    onClicked: menu.chooseProfile(modelData.key)
                    contentItem: Text { text: parent.text; color: parent.enabled ? "#eeeeee" : "#77777b"; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; leftPadding: 26 }
                    indicator: Rectangle {
                        x: 2; anchors.verticalCenter: parent.verticalCenter; width: 15; height: 15; radius: 7.5
                        color: parent.checked ? "#3478f6" : "transparent"; border.color: parent.checked ? "#3478f6" : "#77777b"
                        Rectangle { anchors.centerIn: parent; width: 5; height: 5; radius: 2.5; color: "white"; visible: parent.parent.checked }
                    }
                    background: Rectangle { radius: 6; color: parent.hovered ? "#35ffffff" : "transparent" }
                }
            }
            Text {
                Layout.fillWidth: true; color: "#99999f"; font.pixelSize: 11; wrapMode: Text.Wrap
                text: "El cambio manual dura hasta conectar o desconectar el cargador."
            }
        }
    }
    Item {
        focus: menu.visible
        Keys.onEscapePressed: menu.dismissed()
    }
}
