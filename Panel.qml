import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Model.js" as Model

// JDownloader in the bar: the replacement for the tray icon that cannot work
// under Wayland. Left = panel · right = bring the window back / tuck it away
// (or launch) · middle = send a link from the clipboard.
Panel {
  id: root
  moduleName: "io.github.johnandrewsx.jdownloader"
  ipcTarget: "io.github.johnandrewsx.jdownloader"
  manageIpc: false

  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace("file://", "").replace(/\/$/, "")

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color accent: Color.accent
  readonly property color dim: Util.alpha(foreground, 0.58)
  readonly property color faint: Util.alpha(foreground, 0.38)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool present: jd.running || jd.alive || jd.starting
  // Do not dim before the first answer — the icon would blink on every shell start.
  readonly property color barIconColor: present || !jd.statusKnown ? barForeground : Util.alpha(barForeground, 0.45)
  readonly property color iconColor: present ? foreground : dim

  property bool showSettings: false
  property string newFolderText: ""

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Service {
    id: jd
    settings: root.settings
    pluginDir: root.pluginDir
    moduleName: root.moduleName
  }

  onOpenedChanged: {
    if (opened) { jd.markSeen(); jd.refreshAll() }
    else root.showSettings = false
  }

  // Settings live inline in the layout entry of shell.json. The shell replaces
  // the entry wholesale, so always send the complete object.
  function persist(key, value) {
    var next = ({})
    var current = root.settings || ({})
    for (var k in current) next[k] = current[k]
    next[key] = value
    if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function") {
      if (bar.shell.updateEntryInline(root.moduleName, next)) return
    }
    Quickshell.execDetached(["omarchy-shell", "-q", "shell", "setBarWidget",
      root.moduleName, String(key), JSON.stringify(value), "{}"])
  }

  function addFolder(text) {
    var path = String(text || "").trim()
    if (path === "") return
    var list = jd.extraFolders.slice()
    if (list.indexOf(path) !== -1) { jd.say(jd.tr("folders.duplicate")); return }
    list.push(path)
    persist("extraFolders", list)
    root.newFolderText = ""
    jd.say(jd.tr("folders.added"))
  }

  function removeFolder(path) {
    var list = jd.extraFolders.filter(function(p) { return p !== path })
    persist("extraFolders", list)
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function status(): string { return JSON.stringify(jd.status) }
    function window(): string { jd.toggleWindow(); return "ok" }
    function launch(): string { jd.launch(); return "ok" }
    function clipboard(): string { jd.addFromClipboard(); return "ok" }
    function add(url: string): string { jd.addUrls([url]); return "ok" }
    function rescan(): string { jd.rescan(); return "ok" }
    function quit(): string { jd.quit(); return "ok" }
    function folders(): string { return JSON.stringify(jd.watchDirs) }
    function summary(): string {
      return JSON.stringify({
        language: jd.language,
        running: jd.running, alive: jd.alive, hidden: jd.hidden, focused: jd.focused, starting: jd.starting,
        defaultFolder: jd.defaultFolder, watchDirs: jd.watchDirs, folders: jd.folders,
        active: jd.active.length, recent: jd.recent.length, unseen: jd.unseenCount,
        lastFinished: jd.lastFinished, uiScale: jd.uiScale, smoothing: jd.smoothing,
        displayDirty: jd.displayDirty, actionStatus: jd.actionStatus, lastError: jd.lastError,
        lastFailure: jd.lastFailure, status: jd.status
      })
    }
  }

  // ---- bar button ---------------------------------------------------------------
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    foreground: root.barIconColor
    active: root.opened
    tooltipText: Model.barTooltip(jd.tr, jd.status, jd.active.length, jd.unseenCount, jd.version)
    iconComponent: Component {
      Item {
        Text {
          anchors.centerIn: parent
          text: Model.GLYPH.download
          textFormat: Text.PlainText
          color: root.opened ? root.urgent : root.barIconColor
          font.family: root.fontFamily
          font.pixelSize: Style.bar.iconFont
          renderType: Text.NativeRendering
        }
        // Dot top right: finished-and-unseen (urgent), else "something is happening" (pulsing).
        Rectangle {
          id: badge
          visible: jd.unseenCount > 0 || jd.active.length > 0
          width: Style.space(5)
          height: width
          radius: width / 2
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.rightMargin: -Style.space(1)
          anchors.topMargin: -Style.space(1)
          color: jd.unseenCount > 0 ? root.urgent : root.barIconColor
          SequentialAnimation on opacity {
            running: badge.visible && jd.unseenCount === 0 && jd.active.length > 0
            loops: Animation.Infinite
            NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
            onRunningChanged: if (!running) badge.opacity = 1.0
          }
        }
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) jd.toggleWindow()
      else if (buttonCode === Qt.MiddleButton) jd.addFromClipboard()
      else root.toggle()
    }
  }

  // ---- panel -------------------------------------------------------------------
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(680))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: folderInput.activeFocus
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: jd.toggleWindow()
      onMoveRequested: function(dx, dy) {}
      onTextKey: function(t) {
        var k = String(t).toLowerCase()
        if (k === "h" || k === "w") jd.toggleWindow()
        else if (k === "l") jd.addFromClipboard()
        else if (k === "o") jd.openFolder("")
        else if (k === "r") jd.refreshAll()
        else if (k === "s") root.showSettings = !root.showSettings
        else if (k === "q") jd.quit()
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(12)

          // -- header ----------------------------------------------------------
          PanelHero {
            id: hero
            width: parent.width
            title: "JDownloader"
            meta: Model.heroMeta(jd.tr, jd.status, jd.active.length, jd.unseenCount)
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconOpacity: root.present ? 1.0 : 0.5
            iconComponent: Component {
              Text {
                text: Model.GLYPH.download
                textFormat: Text.PlainText
                color: root.iconColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                renderType: Text.NativeRendering
              }
            }
            trailingControl: Component {
              PanelActionButton {
                iconText: !jd.running ? Model.GLYPH.play : (jd.hidden ? Model.GLYPH.maximize : Model.GLYPH.minimize)
                tooltipText: Model.toggleHint(jd.tr, jd.status, jd.clickAction)
                foreground: hero.foreground
                fontFamily: hero.fontFamily
                bordered: true
                enabled: !jd.busy
                onClicked: jd.toggleWindow()
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: jd.actionStatus !== "" || jd.lastError !== ""
            width: parent.width
            text: jd.lastError !== "" ? jd.lastError : jd.actionStatus
            color: jd.lastError !== "" ? root.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          // -- actions --------------------------------------------------------
          Row {
            width: parent.width
            spacing: Style.space(8)

            ActionChip { iconText: Model.GLYPH.paste; label: jd.tr("action.link"); tip: jd.tr("action.link.tip"); onClicked: jd.addFromClipboard() }
            ActionChip { iconText: Model.GLYPH.folderOpen; label: jd.tr("action.folder"); tip: jd.tr("action.folder.tip"); enabled: jd.defaultFolder !== ""; onClicked: jd.openFolder("") }
            ActionChip { iconText: Model.GLYPH.refresh; label: jd.tr("action.refresh"); tip: jd.tr("action.refresh.tip"); onClicked: jd.refreshAll() }
            ActionChip { iconText: Model.GLYPH.cog; label: jd.tr("action.more"); tip: jd.tr("action.more.tip"); active: root.showSettings; onClicked: root.showSettings = !root.showSettings }
            ActionChip { iconText: Model.GLYPH.power; label: jd.tr("action.quit"); tip: jd.tr("action.quit.tip"); enabled: jd.running; onClicked: jd.quit() }
          }

          Text {
            visible: !root.present && jd.statusKnown
            textFormat: Text.PlainText
            width: parent.width
            text: jd.tr("notRunning.hint")
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          // -- in progress -----------------------------------------------------
          PanelSeparator { visible: jd.active.length > 0; foreground: root.foreground }

          Column {
            visible: jd.active.length > 0
            width: parent.width
            spacing: Style.space(6)

            PanelSectionHeader { text: jd.tr("section.inProgress"); foreground: root.foreground; fontFamily: root.fontFamily }

            Repeater {
              model: jd.active.slice(0, 6)
              FileRow { width: column.width; file: modelData; working: true }
            }

            Text {
              visible: jd.active.length > 6
              textFormat: Text.PlainText
              text: jd.tr("list.more", { n: jd.active.length - 6 })
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          // -- finished ----------------------------------------------------------
          PanelSeparator { foreground: root.foreground }

          Column {
            width: parent.width
            spacing: Style.space(6)

            PanelSectionHeader { text: jd.tr("section.finished"); foreground: root.foreground; fontFamily: root.fontFamily }

            Text {
              visible: jd.recent.length === 0
              textFormat: Text.PlainText
              width: parent.width
              text: jd.watchDirs.length === 0 ? jd.tr("list.noFolders") : jd.tr("list.nothingYet")
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }

            Repeater {
              model: jd.recent
              FileRow { width: column.width; file: modelData }
            }
          }

          // -- settings ---------------------------------------------------------
          PanelSeparator { visible: root.showSettings; foreground: root.foreground }

          Column {
            visible: root.showSettings
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader { text: jd.tr("section.folders"); foreground: root.foreground; fontFamily: root.fontFamily }

            Toggle {
              width: parent.width
              label: jd.tr("folders.default")
              description: jd.defaultFolder !== "" ? Model.shortPath(jd.defaultFolder, jd.home) : jd.tr("folders.default.missing")
              checked: jd.watchDefaultFolder
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.persist("watchDefaultFolder", !jd.watchDefaultFolder)
            }

            Repeater {
              model: jd.extraFolders
              FolderRow { width: column.width; path: modelData }
            }

            Row {
              width: parent.width
              spacing: Style.space(8)

              TextField {
                id: folderInput
                width: parent.width - addButton.width - parent.spacing
                text: root.newFolderText
                placeholderText: jd.tr("folders.placeholder")
                foreground: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                onTextChanged: root.newFolderText = text
                onAccepted: root.addFolder(text)
              }
              PanelActionButton {
                id: addButton
                anchors.verticalCenter: parent.verticalCenter
                iconText: Model.GLYPH.plus
                tooltipText: jd.tr("folders.add")
                foreground: root.foreground
                fontFamily: root.fontFamily
                bordered: true
                enabled: root.newFolderText.trim() !== ""
                onClicked: root.addFolder(root.newFolderText)
              }
            }

            Text {
              textFormat: Text.PlainText
              width: parent.width
              text: jd.tr("folders.note")
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Toggle {
              width: parent.width
              label: jd.tr("notify.label")
              description: jd.tr("notify.description")
              checked: jd.notifyOnFinish
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.persist("notifyOnFinish", !jd.notifyOnFinish)
            }

            Dropdown {
              width: parent.width
              label: jd.tr("click.label")
              value: jd.clickAction
              options: Model.options(jd.tr, "click", Model.CLICK_VALUES)
              fontFamily: root.fontFamily
              onChanged: function(v) { root.persist("clickAction", String(v)) }
            }

            Dropdown {
              width: parent.width
              label: jd.tr("language.label")
              value: jd.languageSetting
              options: Model.options(jd.tr, "language", Model.LANGUAGE_VALUES)
              fontFamily: root.fontFamily
              onChanged: function(v) { root.persist("language", String(v)) }
            }

            PanelSectionHeader { text: jd.tr("section.appearance"); foreground: root.foreground; fontFamily: root.fontFamily }

            Dropdown {
              width: parent.width
              label: jd.tr("scale.label")
              value: jd.uiScale
              options: Model.options(jd.tr, "scale", Model.SCALE_VALUES)
              fontFamily: root.fontFamily
              onChanged: function(v) { jd.setDisplay(String(v), jd.smoothing) }
            }

            Dropdown {
              width: parent.width
              label: jd.tr("smoothing.label")
              value: jd.smoothing
              options: Model.options(jd.tr, "smoothing", Model.SMOOTHING_VALUES)
              fontFamily: root.fontFamily
              onChanged: function(v) { jd.setDisplay(jd.uiScale, String(v)) }
            }

            Text {
              textFormat: Text.PlainText
              width: parent.width
              text: jd.tr("appearance.note")
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Button {
              visible: jd.running || jd.alive
              text: jd.tr(jd.displayDirty ? "restart.now" : "restart")
              iconText: Model.GLYPH.restart
              bordered: true
              foreground: jd.displayDirty ? root.urgent : root.foreground
              fontFamily: root.fontFamily
              enabled: !jd.busy
              tooltipText: jd.tr("restart.tip")
              onClicked: jd.restartJd()
            }
          }

          // -- footer ------------------------------------------------------------
          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: jd.tr("footer.keys")
            color: root.faint
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }

  // ---- building blocks ---------------------------------------------------------------
  component ActionChip: Item {
    id: chip
    property string iconText: ""
    property string label: ""
    property string tip: ""
    property bool active: false
    signal clicked()

    width: (column.width - Style.space(8) * 4) / 5
    height: chipButton.height + chipLabel.implicitHeight + Style.space(4)

    PanelActionButton {
      id: chipButton
      anchors.horizontalCenter: parent.horizontalCenter
      iconText: chip.iconText
      tooltipText: chip.tip
      foreground: chip.active ? root.urgent : root.foreground
      fontFamily: root.fontFamily
      bordered: true
      enabled: chip.enabled
      onClicked: chip.clicked()
    }
    Text {
      id: chipLabel
      anchors.top: chipButton.bottom
      anchors.topMargin: Style.space(4)
      anchors.horizontalCenter: parent.horizontalCenter
      textFormat: Text.PlainText
      text: chip.label
      color: chip.enabled ? root.dim : root.faint
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  component FileRow: CursorSurface {
    id: fileRow
    property var file: null
    property bool working: false
    readonly property string fileName: file ? String(file.name || "") : ""

    foreground: root.foreground
    implicitHeight: fileContent.implicitHeight + Style.spacing.rowPaddingX

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton && !fileRow.working) jd.openFile(fileRow.file)
        else jd.revealFile(fileRow.file)
      }
      onEntered: if (root.bar) root.bar.showTooltip(fileRow, jd.tr(fileRow.working ? "file.tip.working" : "file.tip.done"))
      onExited: if (root.bar) root.bar.hideTooltip(fileRow)
    }

    RowLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: fileRow.working ? Model.GLYPH.download : Model.fileGlyph(fileRow.fileName)
        color: fileRow.working ? root.dim : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        id: fileContent
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: Model.plain(fileRow.fileName)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideMiddle
        }

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: fileRow.working
            ? jd.tr("file.soFar", { size: Model.formatBytes(fileRow.file ? fileRow.file.size : 0) }) + " · " + Model.shortPath(fileRow.file ? fileRow.file.dir : "", jd.home)
            : Model.fileMeta(jd.tr, fileRow.file, jd.home, jd.nowMs)
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideMiddle
        }
      }
    }
  }

  component FolderRow: CursorSurface {
    id: folderRow
    property string path: ""
    readonly property var report: {
      var expanded = Model.expandHome(path, jd.home)
      for (var i = 0; i < jd.folders.length; i++) {
        var f = jd.folders[i]
        if (f && (f.path === path || f.path === expanded)) return f
      }
      return null
    }

    foreground: root.foreground
    implicitHeight: folderContent.implicitHeight + Style.spacing.rowPaddingX

    RowLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(6)
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: Model.GLYPH.folder
        color: folderRow.report && folderRow.report.exists ? root.foreground : root.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        renderType: Text.NativeRendering
      }

      ColumnLayout {
        id: folderContent
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: Model.plain(Model.shortPath(folderRow.path, jd.home))
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideMiddle
        }
        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: !folderRow.report ? "" : (!folderRow.report.exists ? jd.tr("folders.missing")
            : jd.tr("folders.summary", { files: folderRow.report.files, bytes: Model.formatBytes(folderRow.report.bytes) })
              + (folderRow.report.parts > 0 ? jd.tr("folders.summary.parts", { n: folderRow.report.parts }) : ""))
          color: folderRow.report && !folderRow.report.exists ? root.urgent : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }

      PanelActionButton {
        iconText: Model.GLYPH.folderOpen
        tooltipText: jd.tr("folders.open")
        foreground: root.foreground
        fontFamily: root.fontFamily
        enabled: !!(folderRow.report && folderRow.report.exists)
        onClicked: jd.openFolder(Model.expandHome(folderRow.path, jd.home))
      }
      PanelActionButton {
        iconText: Model.GLYPH.close
        tooltipText: jd.tr("folders.remove")
        foreground: root.foreground
        hoverColor: root.urgent
        fontFamily: root.fontFamily
        onClicked: root.removeFolder(folderRow.path)
      }
    }
  }
}
