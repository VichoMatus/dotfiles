pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.pill as Pill
import qs.modules.notch

Scope {
    id: notchRoot
    property var batteryScreen: null
    LazyLoader {
        active: notchRoot.batteryScreen !== null
        component: BatteryMenu {
            screen: notchRoot.batteryScreen
            onDismissed: notchRoot.batteryScreen = null
        }
    }
    Pill.PillTrayMenu { id: trayMenu }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: window
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            color: "transparent"
            WlrLayershell.namespace: "quickshell:vicho-notch"
            WlrLayershell.layer: WlrLayer.Top
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: visible ? 42 : 0
            implicitHeight: face.height + 2
            visible: GlobalStates.barOpen && !GlobalStates.screenLocked
                && !GameMode.hasFullscreenOnOutput(window.modelData.name)
            mask: Region {
                x: face.x - 14
                y: 0
                width: face.width + 28
                height: face.height
                Region { item: statusArea }
                Region { item: leftStatus }
            }
            property bool expanded: false
            property string levelKind: ""
            property string levelMessage: ""
            readonly property var brightnessMonitor: Brightness.getMonitorForScreen(window.modelData)
            readonly property real levelValue: levelKind === "brightness"
                ? (brightnessMonitor?.brightness ?? 0) : Audio.value
            readonly property bool levelOpen: levelKind.length > 0
            property bool dimmed: false
            property int shift: 0
            property string time: Qt.formatTime(new Date(), "HH:mm")
            property string dateText: Qt.formatDate(new Date(), "ddd dd/MM")
            readonly property var notice: !GlobalStates.screenLocked && GlobalStates.focusedScreen?.name === window.modelData.name
                ? (Notifications.popupList[Notifications.popupList.length - 1] ?? null) : null
            readonly property bool open: expanded || notice !== null || levelOpen
            readonly property bool playing: visible && MprisController.isPlaying
            onPlayingChanged: if (!playing) expanded = false
            property int waveStep: 0
            Timer {
                interval: 125; running: window.playing; repeat: true
                onTriggered: window.waveStep = (window.waveStep + 1) % 16
            }
            onVisibleChanged: if (!visible) { expanded = false; levelKind = ""; levelTimer.stop(); if (trayMenu.hostWindow === window) trayMenu.close(); if (notchRoot.batteryScreen === window.modelData) notchRoot.batteryScreen = null }
            onExpandedChanged: if (expanded) closeTimer.restart(); else closeTimer.stop()
            onNoticeChanged: { dimmed = false; dimTimer.restart() }
            function wake() {
                dimmed = false; dimTimer.restart()
                if (expanded) closeTimer.restart()
                if (levelOpen && !levelSlider.pressed) levelTimer.restart()
            }
            function toggleMusic(): void {
                wake()
                if (playing) expanded = !expanded
            }
            Timer { id: closeTimer; interval: 4000; onTriggered: window.expanded = false }
            Timer { id: levelTimer; interval: 1800; onTriggered: window.levelKind = "" }
            Connections {
                target: GlobalStates
                function onNotchLevelRequested(kind: string, message: string): void {
                    if (!window.visible || GlobalStates.focusedScreen?.name !== window.modelData.name) return
                    window.levelKind = kind
                    window.levelMessage = message
                    window.wake()
                }
            }
            IpcHandler {
                target: "notch-" + window.modelData.name
                function toggle(): void { window.toggleMusic() }
                function menu(kind: string): void {
                    if (!window.visible) return
                    if (kind === "battery") notchRoot.batteryScreen = notchRoot.batteryScreen ? null : window.modelData
                    else if (kind === "wifi") GlobalStates.openSidebarRight(window.modelData.name)
                }
                function status(): string {
                    return JSON.stringify({visible: window.visible, expanded: window.expanded,
                        notification: window.notice !== null, dimmed: window.dimmed, shift: window.shift,
                        playing: window.playing, level: window.levelKind,
                        batteryMenu: notchRoot.batteryScreen !== null,
                        monitoring: leftStatus.acquired, appCount: leftStatus.apps.length})
                }
            }
            Timer {
                interval: 60000; running: window.visible; repeat: true
                onTriggered: {
                    window.time = Qt.formatTime(new Date(), "HH:mm")
                    window.dateText = Qt.formatDate(new Date(), "ddd dd/MM")
                }
            }
            Timer {
                id: dimTimer
                interval: 60000; running: window.visible; repeat: false
                onTriggered: window.dimmed = true
            }
            Timer {
                interval: 900000; running: window.visible; repeat: true
                onTriggered: window.shift = (window.shift + 1) % 4
            }
            component Cover: Item {
                id: cover
                property real cornerRadius: width / 2
                Image {
                    id: art
                    anchors.fill: parent
                    source: window.visible ? MediaArtwork.displaySource : ""
                    sourceSize: Qt.size(160, 160)
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }
                Rectangle {
                    id: artMask
                    anchors.fill: parent; radius: cover.cornerRadius
                    layer.enabled: true; visible: false
                }
                MultiEffect {
                    anchors.fill: parent; source: art
                    maskEnabled: true; maskSource: artMask
                    maskThresholdMin: 0.5; maskSpreadAtMin: 1
                    autoPaddingEnabled: false
                }
                Text {
                    anchors.centerIn: parent; text: "♪"; color: "#cccccc"
                    visible: art.status !== Image.Ready
                }
            }
            LeftStatus {
                id: leftStatus
                anchors.left: parent.left; anchors.leftMargin: 12
                y: [0, 1, 2, 1][window.shift]
                width: Math.min(implicitWidth, Math.max(0, window.width / 2 - face.width / 2 - 38))
                height: 42
                active: window.visible
                screenName: window.modelData.name
                opacity: window.dimmed && !leftHover.hovered ? 0.65 : 1
                HoverHandler { id: leftHover; onHoveredChanged: if (hovered) window.wake() }
            }
            Item {
                id: statusArea
                anchors.right: parent.right
                anchors.rightMargin: 16
                width: Math.min(statusRow.implicitWidth, Math.max(0, window.width / 2 - face.width / 2 - 32))
                height: 42
                clip: true
                opacity: window.dimmed && !statusHover.hovered ? 0.65 : 1
                HoverHandler { id: statusHover; onHoveredChanged: if (hovered) window.wake() }
                RowLayout {
                    id: statusRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: [0, 1, 2, 1][window.shift]
                    spacing: 14
                    Pill.Tray {
                        id: backgroundApps
                        barWindow: window
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: 30
                        menuOpen: trayMenu.shown && trayMenu.hostWindow === window
                        onMenuRequested: (item, anchorX, anchorY) => {
                            trayMenu.hostWindow = window
                            trayMenu.open(item, anchorX, anchorY)
                        }
                    }
                    Item {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 30
                        Item {
                            anchors.centerIn: parent; width: 24; height: 18
                            opacity: Network.wifiEnabled || Network.ethernet ? 1 : 0.45
                            Shape {
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    strokeWidth: 2.6; strokeColor: "#eeeeee"; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                                    PathSvg { path: "M 2 5.5 Q 12 -2 22 5.5" }
                                }
                                ShapePath {
                                    strokeWidth: 2.6; strokeColor: "#eeeeee"; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                                    PathSvg { path: "M 6 10 Q 12 5.5 18 10" }
                                }
                            }
                            Rectangle { width: 3.5; height: 3.5; radius: 1.75; x: 10.25; y: 13; color: "#eeeeee"; antialiasing: true }
                        }
                        MouseArea {
                            id: wifiMouse
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: GlobalStates.openSidebarRight(window.modelData.name)
                        }
                    }
                    Item {
                        visible: Battery.available
                        Layout.preferredWidth: batteryRow.implicitWidth + 8
                        Layout.preferredHeight: 30
                    RowLayout {
                        id: batteryRow
                        anchors.centerIn: parent
                        spacing: 7
                        Text {
                            text: Math.round(Battery.percentage * 100) + "%"
                            color: "#eeeeee"; font.pixelSize: 12
                        }
                        Item {
                            Layout.preferredWidth: 29; Layout.preferredHeight: 16
                            Rectangle {
                                width: 26; height: 13; radius: 3.5
                                anchors.verticalCenter: parent.verticalCenter
                                color: "transparent"; border.width: 1.2; border.color: "#eeeeee"
                                Rectangle {
                                    x: 2.5; y: 2.5; height: parent.height - 5; radius: 1.5
                                    width: Math.max(0, (parent.width - 5) * Math.max(0, Math.min(1, Battery.percentage)))
                                    color: Battery.isCharging ? "#73d58b" : PowerProfiles.profile === PowerProfile.PowerSaver ? "#f5cd54" : Battery.isLowAndNotCharging ? "#ee7777" : "#eeeeee"
                                }
                                Shape {
                                    anchors.centerIn: parent; width: 12; height: 15; visible: Battery.isCharging
                                    ShapePath {
                                        strokeColor: "#202020"; strokeWidth: 1; fillColor: "#eeeeee"
                                        PathSvg { path: "M 7 0 L 1 8 H 5 L 4 15 L 11 6 H 7 Z" }
                                    }
                                }
                            }
                            Rectangle {
                                width: 2; height: 5; radius: 1; color: "#bbbbbb"
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                        MouseArea {
                            id: batteryMouse
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Qt.callLater(() => { notchRoot.batteryScreen = window.modelData })
                            }
                        }
                    }
                }
            }
            Rectangle {
                id: face
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(window.width - 20, window.open ? 420 : window.playing ? 252 : 176)
                height: window.levelOpen ? (window.levelMessage.length > 0 ? 154 : 122)
                    : window.notice ? Math.min(300, noticeColumn.implicitHeight + 70)
                    : window.expanded ? 208 : 42
                color: "#000000"
                radius: 22
                // A square cap attaches the rounded body to the display edge.
                Rectangle { width: parent.width; height: 20; color: "black" }
                Shape {
                    x: -14; y: 0; width: 14; height: 14
                    ShapePath {
                        strokeWidth: 0; fillColor: "black"
                        PathSvg { path: "M 0 0 H 14 V 14 C 14 6 8 0 0 0 Z" }
                    }
                }
                Shape {
                    x: parent.width; y: 0; width: 14; height: 14
                    ShapePath {
                        strokeWidth: 0; fillColor: "black"
                        PathSvg { path: "M 0 0 H 14 C 6 0 0 6 0 14 Z" }
                    }
                }
                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                HoverHandler { id: hover; onHoveredChanged: if (hovered) window.wake() }
                Item {
                    id: compact
                    x: [0, 2, 0, -2][window.shift]
                    y: [0, 1, 2, 1][window.shift]
                    width: parent.width; height: 42
                    opacity: window.dimmed && !window.open && !hover.hovered ? 0.55 : 0.9
                    Behavior on opacity { NumberAnimation { duration: 500 } }
                    Cover {
                        width: 28; height: 28
                        anchors.left: parent.left; anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        visible: window.playing && !window.expanded
                    }
                    Text {
                        visible: window.playing
                        anchors.centerIn: parent
                        text: window.time; color: "#d5d5d5"
                        font.pixelSize: 16; font.weight: Font.DemiBold
                    }
                    Row {
                        visible: window.playing
                        anchors.right: parent.right; anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Repeater {
                            model: 5
                            Rectangle {
                                id: wave
                                required property int index
                                width: 3
                                // Decorative waves at 8 fps; no audio analyzer or continuous repaint.
                                height: window.playing ? 4 + 14 * Math.abs(Math.sin((window.waveStep + index * 2) * Math.PI / 8)) : 4
                                radius: 1.5; color: "#b8cbbf"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    Row {
                        visible: !window.playing
                        anchors.centerIn: parent
                        spacing: 24
                    Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: window.time; color: "#d5d5d5"
                            font.pixelSize: 16; font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: window.dateText; color: "#bcbcbc"; font.pixelSize: 13
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: window.toggleMusic()
                    }
                }
                ColumnLayout {
                    id: noticeColumn
                    anchors { top: parent.top; topMargin: 52; left: parent.left; right: parent.right; margins: 22 }
                    visible: window.notice !== null && !window.levelOpen
                    spacing: 8
                    Text {
                        Layout.fillWidth: true; color: "#aebbb3"; font.pixelSize: 12
                        textFormat: Text.PlainText
                        text: window.notice?.appName ?? ""
                    }
                    Text {
                        Layout.fillWidth: true; color: "#eeeeee"; font.pixelSize: 15; font.bold: true
                        wrapMode: Text.Wrap; textFormat: Text.PlainText
                        text: window.notice?.summary ?? ""
                    }
                    Flickable {
                        Layout.fillWidth: true
                        implicitHeight: Math.min(140, noticeBody.implicitHeight)
                        contentHeight: noticeBody.implicitHeight
                        clip: true
                        Text {
                            id: noticeBody
                            width: parent.width; color: "#c5c5c5"; font.pixelSize: 13
                            wrapMode: Text.Wrap; textFormat: Text.PlainText
                            text: String(window.notice?.body ?? "").replace(/<[^>]*>/g, "")
                        }
                    }
                    Text {
                        text: "Cerrar"; color: "#aebbb3"; font.pixelSize: 12
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (window.notice) Notifications.timeoutNotification(window.notice.notificationId)
                        }
                    }
                }
                RowLayout {
                    anchors { top: parent.top; topMargin: 58; left: parent.left; right: parent.right; margins: 24 }
                    visible: window.expanded && window.playing && !window.notice && !window.levelOpen
                    spacing: 20
                    Cover {
                        Layout.preferredWidth: 94; Layout.preferredHeight: 94
                        Layout.alignment: Qt.AlignVCenter
                        cornerRadius: 14
                    }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                        text: MediaArtwork.title || "Sin reproducción"
                        textFormat: Text.PlainText; color: "#eeeeee"; font.pixelSize: 16
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                        text: MediaArtwork.artist; textFormat: Text.PlainText
                        color: "#aaaaaa"; font.pixelSize: 12; elide: Text.ElideRight
                    }
                    Row {
                        Layout.alignment: Qt.AlignHCenter; spacing: 12
                        Repeater {
                            model: 3
                            Item {
                                id: transportButton
                                required property int index
                                width: 44; height: 36
                                enabled: index === 0 ? MprisController.canGoPrevious : index === 2 ? MprisController.canGoNext : MprisController.canTogglePlaying
                                opacity: enabled ? 1 : 0.3
                                Accessible.role: Accessible.Button
                                Accessible.name: index === 0 ? "Anterior" : index === 2 ? "Siguiente" : MprisController.isPlaying ? "Pausar" : "Reproducir"
                                Rectangle {
                                    anchors.fill: parent; radius: 10
                                    color: transportMouse.pressed ? "#25ffffff" : transportMouse.containsMouse ? "#12ffffff" : "transparent"
                                }
                                Shape {
                                    anchors.centerIn: parent; width: 32; height: 28
                                    scale: transportMouse.pressed ? 0.9 : 1
                                    ShapePath {
                                        strokeColor: "#eeeeee"; strokeWidth: 1
                                        joinStyle: ShapePath.RoundJoin; fillColor: "#eeeeee"
                                        PathSvg {
                                            path: transportButton.index === 0
                                                ? "M 15 5 L 3 14 L 15 23 Z M 29 5 L 17 14 L 29 23 Z"
                                                : transportButton.index === 2
                                                ? "M 3 5 L 15 14 L 3 23 Z M 17 5 L 29 14 L 17 23 Z"
                                                : MprisController.isPlaying
                                                ? "M 9 4 H 13 Q 14 4 14 5 V 23 Q 14 24 13 24 H 9 Q 8 24 8 23 V 5 Q 8 4 9 4 Z M 20 4 H 24 Q 25 4 25 5 V 23 Q 25 24 24 24 H 20 Q 19 24 19 23 V 5 Q 19 4 20 4 Z"
                                                : "M 10 3 L 27 13 Q 29 14 27 15 L 10 25 Q 8 26 8 24 V 4 Q 8 2 10 3 Z"
                                        }
                                    }
                                }
                                MouseArea {
                                    id: transportMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        window.wake()
                                        if (transportButton.index === 0) MprisController.previous()
                                        else if (transportButton.index === 2) MprisController.next()
                                        else MprisController.togglePlaying()
                                    }
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: progress.formatTime(progress.displayPosition)
                            color: "#aaaaaa"; font.pixelSize: 11
                        }
                    Controls.Slider {
                        id: progress
                        Layout.fillWidth: true
                        readonly property var player: MprisController.activePlayer
                        readonly property real trackLength: MprisController.lengthOf(player)
                        property real trackPosition: 0
                        readonly property real displayPosition: pressed ? value : trackPosition
                        function formatTime(seconds: real): string {
                            const total = Math.max(0, Math.floor(Number.isFinite(seconds) ? seconds : 0))
                            return Math.floor(total / 60) + ":" + String(total % 60).padStart(2, "0")
                        }
                        from: 0; to: Math.max(1, trackLength)
                        value: trackPosition
                        enabled: player !== null && (player?.canSeek ?? false)
                            && (player?.positionSupported ?? false) && trackLength > 0
                        function refresh(): void { trackPosition = MprisController.positionOf(player) }
                        onPlayerChanged: refresh()
                        onVisibleChanged: if (visible) refresh()
                        Timer {
                            interval: 1000; repeat: true
                            running: window.visible && window.expanded && !window.levelOpen && !window.notice && !progress.pressed
                            onTriggered: {
                                if (progress.player) progress.player.positionChanged()
                                progress.refresh()
                            }
                        }
                        onPressedChanged: {
                            if (pressed) closeTimer.stop()
                            else {
                                if (enabled) MprisController.seek(player, value)
                                refresh()
                                window.wake()
                            }
                        }
                        onMoved: {
                            if (!pressed && enabled) {
                                MprisController.seek(player, value)
                                refresh()
                                window.wake()
                            }
                        }
                        background: Rectangle {
                            x: progress.leftPadding; y: progress.topPadding + progress.availableHeight / 2 - height / 2
                            width: progress.availableWidth; height: 4; radius: 2; color: "#303630"
                            Rectangle { width: parent.width * progress.visualPosition; height: parent.height; radius: 2; color: "#b8cbbf" }
                        }
                        handle: Rectangle {
                            x: progress.leftPadding + progress.visualPosition * (progress.availableWidth - width)
                            y: progress.topPadding + progress.availableHeight / 2 - height / 2
                            width: 10; height: 10; radius: 5; color: "#dddddd"
                        }
                    }
                        Text {
                            text: progress.trackLength > 0
                                ? "−" + progress.formatTime(progress.trackLength - progress.displayPosition) : "--:--"
                            color: "#aaaaaa"; font.pixelSize: 11
                        }
                    }
                }
                }
                ColumnLayout {
                    anchors { top: parent.top; topMargin: 54; left: parent.left; right: parent.right; margins: 24 }
                    visible: window.levelOpen
                    spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true; color: "#dddddd"; font.pixelSize: 14
                            text: window.levelKind === "brightness" ? "Brillo" : Audio.sink?.audio?.muted ? "Volumen · silenciado" : "Volumen"
                        }
                        Text {
                            color: "#b8cbbf"; font.pixelSize: 14
                            text: Math.round(window.levelValue * 100) + "%"
                        }
                    }
                    Controls.Slider {
                        id: levelSlider
                        Layout.fillWidth: true
                        from: 0; to: window.levelKind === "volume" ? Audio.ceiling : 1
                        value: window.levelValue
                        onPressedChanged: if (pressed) levelTimer.stop(); else window.wake()
                        onMoved: {
                            if (window.levelKind === "brightness" && window.brightnessMonitor)
                                window.brightnessMonitor.brightness = value
                            else if (window.levelKind === "volume") Audio.setSinkVolume(value)
                            window.wake()
                        }
                        background: Rectangle {
                            x: levelSlider.leftPadding; y: levelSlider.topPadding + levelSlider.availableHeight / 2 - height / 2
                            width: levelSlider.availableWidth; height: 5; radius: 2.5; color: "#303630"
                            Rectangle { width: parent.width * levelSlider.visualPosition; height: parent.height; radius: 2.5; color: "#b8cbbf" }
                        }
                        handle: Rectangle {
                            x: levelSlider.leftPadding + levelSlider.visualPosition * (levelSlider.availableWidth - width)
                            y: levelSlider.topPadding + levelSlider.availableHeight / 2 - height / 2
                            width: 14; height: 14; radius: 7; color: "#dddddd"
                        }
                    }
                    Text {
                        Layout.fillWidth: true; visible: text.length > 0
                        text: window.levelMessage; color: "#cccccc"; wrapMode: Text.Wrap; font.pixelSize: 12
                    }
                }
            }
        }
    }
}
