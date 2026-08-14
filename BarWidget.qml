import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "scripts/lunar_converter.js" as LunarConverter

BarWidget {
    id: root
    moduleName: "io.github.tuthan.omarchy-lunar-calendar"

    property date currentDate: new Date()
    property var lunarData: ({})
    property var moonData: ({})
    property real timeZoneOffset: 7.0 // UTC+7
    property bool panelTogglePending: false

    function refresh() {
        currentDate = new Date()
        var d = currentDate.getDate()
        var m = currentDate.getMonth() + 1
        var y = currentDate.getFullYear()

        lunarData = LunarConverter.convertSolarToLunar(d, m, y, timeZoneOffset)
        moonData = LunarConverter.getMoonPhase(d, m, y)
        if (panelLoader.item && typeof panelLoader.item.refresh === "function") {
            panelLoader.item.refresh()
        }
    }

    Component.onCompleted: {
        refresh()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        onDateChanged: root.refresh()
    }

    readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

    function open() {
        if (panelLoader.item && typeof panelLoader.item.open === "function") panelLoader.item.open()
    }

    function close() {
        if (panelLoader.item && typeof panelLoader.item.close === "function") panelLoader.item.close()
    }

    function togglePanel() {
        if (panelLoader.item && typeof panelLoader.item.toggle === "function") {
            panelLoader.item.toggle()
            return
        }
        // The bar can receive a click while the panel Loader is still
        // resolving its QML source. Preserve that click until the panel is
        // ready instead of silently dropping it.
        panelTogglePending = !panelTogglePending
    }

    readonly property real openPanelIndicatorWidth: button.width
    readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))

    function injectPanel() {
        var target = panelLoader.item
        if (!target) return
        if ("bar" in target) target.bar = root.bar
        if ("settings" in target) target.settings = root.settings
        if ("anchorItem" in target) target.anchorItem = button
        if ("hostWidget" in target) target.hostWidget = root
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    onBarChanged: injectPanel()
    onSettingsChanged: injectPanel()

    Loader {
        id: panelLoader
        active: true
        source: Qt.resolvedUrl("Panel.qml")
        asynchronous: false
        visible: false
        onLoaded: {
            root.injectPanel()
            Qt.callLater(root.injectPanel)
            if (root.panelTogglePending && item && typeof item.toggle === "function") {
                root.panelTogglePending = false
                item.toggle()
            }
        }
        onStatusChanged: if (status === Loader.Error)
            console.warn("io.github.tuthan.omarchy-lunar-calendar panel failed to load:", errorString())
    }

    IpcHandler {
        target: "io.github.tuthan.omarchy-lunar-calendar"
        function refresh(): void { root.refresh() }
        function open(): void { root.open() }
        function close(): void { root.close() }
        function show(): void { root.open() }
        function hide(): void { root.close() }
        function toggle(): void { root.togglePanel() }
    }

    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: (moonData.phaseIcon || "🌘") + " " + Qt.formatDateTime(currentDate, "dd/MM") + " • " + (lunarData.lunarDay === 1 ? "Mùng 1" : (lunarData.lunarDay === 15 ? "Rằm" : (lunarData.lunarDay ? (lunarData.lunarDay + "/" + lunarData.lunarMonth) : "Âm")))
        onPressed: function(b) {
            root.togglePanel()
        }
    }
}
