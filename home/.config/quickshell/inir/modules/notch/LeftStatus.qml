pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import qs
import qs.services
import qs.modules.common.widgets

Item {
    id: root
    property bool active: false
    property string screenName: ""
    property bool acquired: false
    property bool initialized: false
    readonly property var apps: TaskbarApps.apps.filter(app => app.toplevels.length > 0)
    implicitWidth: 34 + metrics.implicitWidth + appRow.implicitWidth + 40
    implicitHeight: 42
    function sync(): void {
        if (!initialized) return
        if (active === acquired) return
        acquired = active
        if (acquired) ResourceUsage.keepAlive()
        else ResourceUsage.releaseKeepAlive()
        CompositorService.setSortingConsumer("notch:" + screenName, acquired)
    }
    onActiveChanged: sync()
    Component.onCompleted: { initialized = true; sync() }
    Component.onDestruction: {
        if (acquired) ResourceUsage.releaseKeepAlive()
        CompositorService.setSortingConsumer("notch:" + screenName, false)
    }
    RowLayout {
        anchors.fill: parent
        spacing: 12
        Item {
            Layout.preferredWidth: 28; Layout.preferredHeight: 34
            CustomIcon {
                anchors.centerIn: parent; width: 19; height: 19
                source: "cachyos-symbolic"; colorize: true; color: "#eeeeee"
            }
        }
        Row {
            id: metrics
            Layout.alignment: Qt.AlignVCenter
            spacing: 12
            Text {
                text: "CPU " + Math.round(ResourceUsage.cpuUsage * 100) + "%"
                color: "#dddddd"; font.pixelSize: 11
            }
            Text {
                text: ResourceUsage.memoryTotal > 0
                    ? "RAM " + (ResourceUsage.memoryUsed / 1048576).toFixed(1) + "/" + (ResourceUsage.memoryTotal / 1048576).toFixed(1) + "G"
                    : "RAM —"
                color: "#dddddd"; font.pixelSize: 11
            }
        }
        Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 14; color: "#555555"; visible: root.apps.length > 0 }
        Flickable {
            id: applications
            Layout.fillWidth: true; Layout.preferredHeight: 34
            contentWidth: appRow.implicitWidth; contentHeight: height
            clip: true; boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick
            Row {
                id: appRow
                spacing: 4
                Repeater {
                    model: root.apps
                    Item {
                        id: app
                        required property var modelData
                        readonly property bool focused: modelData.toplevels.some(window => window.activated)
                        width: 30; height: 34
                        Rectangle {
                            anchors.fill: parent; radius: 7
                            color: app.focused ? "#22ffffff" : appMouse.containsMouse ? "#14ffffff" : "transparent"
                        }
                        Image {
                            anchors.centerIn: parent; width: 21; height: 21
                            source: AppSearch.getIconSource(app.modelData.appId, "application-x-executable")
                            sourceSize: Qt.size(32, 32); fillMode: Image.PreserveAspectFit
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: app.focused ? 10 : 3; height: 2; radius: 1
                            color: app.focused ? "#dddddd" : "#888888"
                        }
                        Accessible.role: Accessible.Button
                        Accessible.name: app.modelData.appId
                        MouseArea {
                            id: appMouse
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const windows = app.modelData.toplevels
                                if (!windows.length) return
                                const focused = windows.findIndex(window => window.activated)
                                windows[(focused + 1) % windows.length].activate()
                            }
                            onWheel: wheel => {
                                applications.contentX = Math.max(0, Math.min(applications.contentWidth - applications.width,
                                    applications.contentX - wheel.angleDelta.y / 120 * 34))
                            }
                        }
                    }
                }
            }
        }
    }
}
