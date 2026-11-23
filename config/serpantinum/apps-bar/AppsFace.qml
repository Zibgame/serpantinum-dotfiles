import QtQuick
import QtQuick.Controls
import Quickshell
import "../../../"

Item {
    id: root

    property var module: null
    property string orientation: module ? module.orientation : "horizontal"
    readonly property bool isVertical: orientation === "vertical"
    readonly property bool moduleActive: module ? module.moduleActive : true
    readonly property var barWindow: module ? module.barWindow : null

    function s(value) {
        if (barWindow && typeof barWindow.cs === "function") return barWindow.cs(value);
        if (typeof Scaler !== "undefined" && typeof Scaler.s === "function") return Math.round(Scaler.s(value));
        return value;
    }

    ListModel {
        id: appsModel
    }

    function rebuild() {
        appsModel.clear();

        let groups = WindowTracker.groups || {};
        let order = WindowTracker.groupOrder || [];
        for (let i = 0; i < order.length; i++) {
            let key = order[i];
            let group = groups[key];
            if (!group || !group.windows || group.windows.length === 0) continue;

            let entry = AppMatcher.entry(group.desktopId || group.appId || key);
            let active = group.activeWindow || group.windows[0];
            let fallbackName = group.appId || (active ? active.title : "Application");

            appsModel.append({
                "groupKey": key,
                "appName": entry && entry.name ? entry.name : fallbackName,
                "appIcon": entry && entry.icon ? entry.icon : (group.appId || ""),
                "windowCount": group.count || group.windows.length,
                "isFocused": Boolean(group.focused)
            });
        }
    }

    function focusGroup(groupKey) {
        let group = WindowTracker.groups ? WindowTracker.groups[groupKey] : null;
        if (!group || !group.windows || group.windows.length === 0) return;

        let targetIndex = 0;
        if (group.windows.length > 1 && group.focused) {
            for (let i = 0; i < group.windows.length; i++) {
                if (group.windows[i].focused) {
                    targetIndex = (i + 1) % group.windows.length;
                    break;
                }
            }
        }
        WindowTracker.focusWindow(group.windows[targetIndex]);
    }

    Component.onCompleted: {
        WindowTracker.subscribe();
        rebuild();
    }

    Component.onDestruction: WindowTracker.unsubscribe()

    Connections {
        target: WindowTracker
        function onUpdated() { root.rebuild(); }
    }

    property real targetLength: moduleActive && appsModel.count > 0
        ? (isVertical ? appsColumn.implicitHeight : appsRow.implicitWidth) + s(12)
        : 0

    implicitWidth: isVertical ? (parent ? parent.width : 0) : targetLength
    implicitHeight: isVertical ? targetLength : (parent ? parent.height : 0)

    Row {
        id: appsRow
        visible: !root.isVertical
        anchors.centerIn: parent
        spacing: root.s(4)

        Repeater {
            model: appsModel
            delegate: appDelegate
        }
    }

    Column {
        id: appsColumn
        visible: root.isVertical
        anchors.centerIn: parent
        spacing: root.s(4)

        Repeater {
            model: appsModel
            delegate: appDelegate
        }
    }

    Component {
        id: appDelegate

        Rectangle {
            id: appButton

            required property string groupKey
            required property string appName
            required property string appIcon
            required property int windowCount
            required property bool isFocused

            readonly property real naturalWidth: root.s(18) + root.s(6)
                + Math.min(appLabel.implicitWidth, root.s(105))
                + (windowCount > 1 ? countLabel.implicitWidth + root.s(5) : 0)
                + root.s(14)

            width: root.isVertical ? root.s(30) : naturalWidth
            height: root.isVertical ? root.s(30) : Math.max(root.s(26), root.height - root.s(8))
            radius: Math.min(root.s(8), height / 2)
            color: isFocused
                ? Qt.alpha(ThemeBackend.mauve, 0.38)
                : (buttonArea.containsMouse ? Qt.alpha(ThemeBackend.surface2, 0.75) : "transparent")
            border.width: isFocused ? 1 : 0
            border.color: ThemeBackend.mauve

            Behavior on color { ColorAnimation { duration: 120 } }

            Image {
                id: appImage
                width: root.s(18)
                height: width
                anchors.left: parent.left
                anchors.leftMargin: root.isVertical ? (parent.width - width) / 2 : root.s(7)
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                mipmap: true
                source: {
                    let icon = appButton.appIcon || "";
                    if (!icon) return "";
                    if (icon.startsWith("file://") || icon.startsWith("image://")) return icon;
                    return icon.startsWith("/") ? "file://" + icon : "image://icon/" + icon;
                }
            }

            Text {
                id: fallbackIcon
                visible: appImage.source === "" || appImage.status === Image.Error
                anchors.centerIn: appImage
                text: appButton.appName ? appButton.appName.charAt(0).toUpperCase() : "?"
                color: ThemeBackend.text
                font.family: ThemeBackend.fontFamily
                font.pixelSize: root.s(14)
                font.weight: Font.Bold
            }

            Text {
                id: appLabel
                visible: !root.isVertical
                anchors.left: appImage.right
                anchors.leftMargin: root.s(6)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, root.s(105))
                text: appButton.appName
                color: ThemeBackend.text
                font.family: ThemeBackend.fontFamily
                font.pixelSize: root.s(12)
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                id: countLabel
                visible: !root.isVertical && appButton.windowCount > 1
                anchors.left: appLabel.right
                anchors.leftMargin: root.s(5)
                anchors.verticalCenter: parent.verticalCenter
                text: "×" + appButton.windowCount
                color: appButton.isFocused ? ThemeBackend.mauve : ThemeBackend.subtext0
                font.family: ThemeBackend.fontFamily
                font.pixelSize: root.s(10)
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: buttonArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.focusGroup(appButton.groupKey)
            }

            ToolTip.visible: buttonArea.containsMouse
            ToolTip.delay: 500
            ToolTip.text: appButton.appName + (appButton.windowCount > 1 ? " (" + appButton.windowCount + " fenêtres)" : "")
        }
    }
}
