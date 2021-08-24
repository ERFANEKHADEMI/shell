// SPDX-FileCopyrightText: 2017 Michael Spencer <sonrisesoftware@gmail.com>
// SPDX-FileCopyrightText: 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQml 2.1
import QtQuick 2.15
import QtQuick.Window 2.15
import QtWayland.Compositor 1.15
import Liri.Launcher 1.0 as Launcher
import Liri.XWayland 1.0 as LXW
import Liri.WaylandServer 1.0 as WS
import Liri.Session 1.0 as Session
import Liri.Shell 1.0 as LS
import Liri.private.shell 1.0 as P
import "base"
import "desktop"
import "windows"

P.WaylandCompositor {
    id: liriCompositor

    property point mousePos: Qt.point(0, 0)

    property int idleInhibit: 0

    readonly property alias settings: settings

    readonly property alias windows: __private.windows
    readonly property bool hasMaxmizedShellSurfaces: __private.maximizedShellSurfaces > 0
    readonly property bool hasFullscreenShellSurfaces: __private.fullscreenShellSurfaces > 0

    readonly property alias showModalOverlay: liriModal.grabbed

    readonly property alias applicationManager: applicationManager
    readonly property alias shellHelper: shellHelper

    defaultSeat.keymap {
        layout: settings.keyboard.layouts[0] ? settings.keyboard.layouts[0] : "us"
        variant: settings.keyboard.variants[0] ? settings.keyboard.variants[0] : ""
        options: settings.keyboard.options[0] ? settings.keyboard.options[0] : ""
        model: settings.keyboard.model
        rules: settings.keyboard.rules[0] ? settings.keyboard.rules[0] : ""
    }

    onCreatedChanged: {
        if (liriCompositor.created) {
            console.debug("Compositor created");

            Session.SessionManager.setEnvironment("WAYLAND_DISPLAY", liriCompositor.socketName);
            SessionInterface.registerService();

            if (xwayland.enabled)
                xwayland.startServer();
        }
    }

    onSurfaceRequested: {
        var surface = surfaceComponent.createObject(liriCompositor, {});
        surface.initialize(liriCompositor, client, id, version);
    }

    /*
     * Window management
     */

    QtObject {
        id: __private

        property var windows: []
        property int maximizedShellSurfaces: 0
        property int fullscreenShellSurfaces: 0
    }

    /*
     * Output management
     */

    P.ScreenModel {
        id: screenModel
        fileName: screenConfigurationFileName
    }

    Component {
        id: outputModeComponent

        WS.WlrOutputModeV1 {}
    }

    Component {
        id: outputConfigComponent

        WS.WlrOutputConfigurationV1 {
            id: configuration

            onReadyToTest: {
                if (!screenModel.testConfiguration(configuration))
                    configuration.sendFailed();
            }
            onReadyToApply: {
                screenModel.applyConfiguration(configuration);
            }
        }
    }

    WS.WlrOutputManagerV1 {
        id: outputManager

        onConfigurationRequested: {
            var configuration = outputConfigComponent.createObject(outputManager);
            configuration.initialize(outputManager, resource);
        }
    }

    Instantiator {
        model: screenModel
        delegate: Output {
            compositor: liriCompositor
            screen: screenItem
            position: screenItem.position
            manufacturer: screenItem.manufacturer
            model: screenItem.model
            physicalSize: screenItem.physicalSize
            subpixel: screenItem.subpixel
            transform: screenItem.transform
            scaleFactor: screenItem.scaleFactor

            Component.onCompleted: {
                // Set this as default output if configured
                if (!liriCompositor.defaultOutput && screenItem.name === settings.outputs.primary)
                    liriCompositor.defaultOutput = this;

                // Fallback to the first one
                if (!liriCompositor.defaultOutput)
                    liriCompositor.defaultOutput = this;
            }
        }

        onObjectRemoved: {
            // Move all windows that fit entirely the removed output to the primary output,
            // unless the output remove is the primary one (this shouldn't happen)
            if (object === liriCompositor.defaultOutput)
                return;
            for (var surface in object.viewsBySurface) {
                var view = object.viewsBySurface[surface];
                if (view.primary && view.output === object) {
                    view.window.moveItem.x = liriCompositor.defaultOutput.position.x + 20;
                    view.window.moveItem.y = liriCompositor.defaultOutput.position.y + 20;
                }
            }
        }
    }

    Instantiator {
        id: headManager

        model: screenModel
        delegate: WS.WlrOutputHeadV1 {
            manager: outputManager
            name: screenItem.name
            description: screenItem.description
            physicalSize: screenItem.physicalSize
            position: screenItem.position
            transform: screenItem.transform
            scale: screenItem.scaleFactor

            Component.onCompleted: {
                for (var i = 0; i < screenItem.modes.length; i++) {
                    var screenMode = screenItem.modes[i];
                    var mode = outputModeComponent.createObject(this, {size: screenMode.resolution, refresh: screenMode.refreshRate});

                    addMode(mode);

                    if (screenItem.preferredMode === screenMode)
                        preferredMode = mode;

                    if (screenItem.currentMode === screenMode)
                        currentMode = mode;
                }
            }
        }
    }

    /*
     * Extensions
     */

    QtWindowManager {
        showIsFullScreen: false
        onOpenUrl: Session.Launcher.launchCommand("xdg-open %1".arg(url))
    }

    // Liri shell

    WS.LiriShell {
        id: shellHelper

        property bool isReady: false

        onShortcutBound: {
            shortcutComponent.incubateObject(keyBindings, { shortcut: shortcut });
        }
        onReady: {
            isReady = true;
            shellHelperTimer.running = false;

            for (var i = 0; i < outputs.length; i++)
                outputs[i].desktop.state = "session";
        }
        onTerminateRequested: {
            liriCompositor.quit();
        }
    }

    WS.LiriModalManager {
        id: liriModal
    }

    Timer {
        id: shellHelperTimer

        interval: 15000
        running: true
        onTriggered: {
            for (var i = 0; i < outputs.length; i++)
                outputs[i].desktop.state = "session";
        }
    }

    WS.LiriOsd {
        id: liriOsd
    }

    Component {
        id: shortcutComponent

        Shortcut {
            property WS.LiriShortcut shortcut: null

            context: Qt.ApplicationShortcut
            sequence: shortcut ? shortcut.sequence : ""
            enabled: shellHelper.isReady
            onActivated: {
                shortcut.activate();
            }
        }
    }

    // Layer shell

    WS.WlrLayerShellV1 {
        id: layerShell

        function getModelForLayer(layerSurface, output) {
            if (layerSurface.nameSpace === "dialog")
                return output.modalOverlayModel;

            switch (layerSurface.layer) {
            case WS.WlrLayerShellV1.BackgroundLayer:
                return output.backgroundLayerModel;
            case WS.WlrLayerShellV1.BottomLayer:
                return output.bottomLayerModel;
            case WS.WlrLayerShellV1.TopLayer:
                return output.topLayerModel;
            case WS.WlrLayerShellV1.OverlayLayer:
                return output.overlayLayerModel;
            default:
                return undefined;
            }
        }

        onLayerSurfaceCreated: {
            var output = layerSurface.output;
            if (!output)
                output = liriCompositor.defaultOutput;

            var model = getModelForLayer(layerSurface, output);
            model.append({layerSurface: layerSurface, output});
        }
    }

    // Decorations

    XdgDecorationManagerV1 {
        preferredMode: settings.ui.clientSideDecoration ? XdgToplevel.ClientSideDecoration : XdgToplevel.ServerSideDecoration
    }

    WS.LiriDecorationManager {
        onDecorationCreated: {
            decoration.foregroundColorChanged.connect(function(color) {
                decoration.surface.foregroundColor = color;
            });
            decoration.backgroundColorChanged.connect(function(color) {
                decoration.surface.backgroundColor = color;
            });
        }
    }

    // Foreign toplevel management

    WS.WlrForeignToplevelManagerV1 {
        id: foreignToplevelManager
    }

    // Screen copy

    P.ScreenCast {
        id: screenCast

        onFrameAvailable: {
            for (var i = 0; i < outputs.length; i++) {
                var output = outputs[i];

                if (output.screen.screen === screen) {
                    output.exportDmabufFrame.frame(size, offset, 0, 0, drmFormat, modifier, numObjects);
                    break;
                }
            }
        }
        onObjectAvailable: {
            for (var i = 0; i < outputs.length; i++) {
                var output = outputs[i];
                if (!output.exportDmabufFrame)
                    continue;

                if (output.screen.screen === screen) {
                    output.exportDmabufFrame.object(index, fd, size, offset, stride, planeIndex);
                    break;
                }
            }
        }
        onCaptureReady: {
            for (var i = 0; i < outputs.length; i++) {
                var output = outputs[i];
                if (!output.exportDmabufFrame)
                    continue;

                if (output.screen.screen === screen) {
                    output.exportDmabufFrame.ready(tv_sec, tv_nsec);
                    output.exportDmabufFrame = null;
                    screenCast.disable(screen);
                    break;
                }
            }
        }
    }

    WS.WlrExportDmabufManagerV1 {
        onOutputCaptureRequested: {
            if (frame.output.screen) {
                frame.output.exportDmabufFrame = frame;
                screenCast.enable(frame.output.screen.screen);
            }
        }
    }

    WS.WlrScreencopyManagerV1 {
        onCaptureOutputRequested: {
            frame.ready.connect(function() {
                frame.copy("desktop");
                liriCompositor.flash();
            });
        }
    }

    WS.LiriColorPickerManager {
        layerName: "desktop"
    }

    // Shells

    Component {
        id: xdgToplevelComponent

        XdgToplevelWindow {
            id: window

            onMaximizedChanged: {
                if (maximized)
                    __private.maximizedShellSurfaces++;
                else
                    __private.maximizedShellSurfaces--;
            }
            onFullscreenChanged: {
                if (fullscreen)
                    __private.fullscreenShellSurfaces++;
                else
                    __private.fullscreenShellSurfaces--;
            }

            Component.onDestruction: {
                // Remove from the list of xdg-shell toplevels
                var toplevelIndex = xdgShell.toplevels.indexOf(toplevel);
                if (toplevelIndex >= 0)
                    xdgShell.toplevels.splice(toplevelIndex, 1);

                // Remove from the list of windows
                var windowIndex = windows.indexOf(window);
                if (windowIndex >= 0)
                    windows.splice(windowIndex, 1);
            }
        }
    }

    XdgShell {
        id: xdgShell

        property var toplevels: ([])

        onToplevelCreated: {
            var window = xdgToplevelComponent.createObject(xdgShell, {xdgSurface: xdgSurface, toplevel: toplevel});
            for (var i = 0; i < outputs.length; i++)
                outputs[i].currentWorkspace.shellSurfaces.append({shellSurface: xdgSurface, window: window, output: outputs[i]});
            toplevels.push(toplevel);
            windows.push(window);
        }
    }

    Component {
        id: xwaylandWindowComponent

        XWaylandWindow {
            id: window

            Component.onDestruction: {
                // Remove from the list of windows
                var windowIndex = windows.indexOf(window);
                if (windowIndex >= 0)
                    windows.splice(windowIndex, 1);
            }
        }
    }

    Component {
        id: shellSurfaceComponent

        LXW.XWaylandShellSurface {}
    }

    LXW.XWayland {
        id: xwayland

        enabled: liriCompositor.settings.shell.enableXwayland
        manager: LXW.XWaylandManager {
            id: manager
            onShellSurfaceRequested: {
                var shellSurface = shellSurfaceComponent.createObject(manager);
                shellSurface.initialize(manager, window, geometry, overrideRedirect, parentShellSurface);
            }
            onShellSurfaceCreated: {
                var window = xwaylandWindowComponent.createObject(manager, {shellSurface: shellSurface});
                for (var i = 0; i < outputs.length; i++)
                    outputs[i].currentWorkspace.xwaylandShellSurfaces.append({shellSurface: shellSurface, window: window, output: outputs[i]});
                windows.push(window);
            }
        }
        onServerStarted: {
            console.info("Xwayland server started");
            Session.SessionManager.setEnvironment("DISPLAY", displayName);
        }
    }

    // Text input

    TextInputManager {}

    /*
     * D-Bus
     */

    P.MultimediaKeysServer {
        id: multimediakeysServer
    }

    P.OsdServer {
        id: osdServer

        onTextRequested: {
            liriOsd.showText(iconName, text);
        }
        onProgressRequested: {
            liriOsd.showProgress(iconName, value);
        }
    }

    /*
     * Components
     */

    // Surface component
    Component {
        id: surfaceComponent

        WaylandSurface {
            id: surface

            property color foregroundColor: "transparent"
            property color backgroundColor: "transparent"

            Component.onDestruction: {
                for (var i = 0; i < outputs.length; i++)
                    delete outputs[i].viewsBySurface[surface];
            }
        }
    }

    /*
     * Miscellaneous
     */

    // Holds move items in the compositor space
    Item {
        id: rootItem
    }

    Launcher.ApplicationManager {
        id: applicationManager
    }

    Launcher.LauncherModel {
        id: launcherModel
        sourceModel: applicationManager
    }

    ShellSettings {
        id: settings
    }

    KeyBindings {
        id: keyBindings
    }

    Timer {
        id: idleTimer

        interval: settings.session.idleDelay * 1000
        running: true
        repeat: true
        onTriggered: {
            var i, output, idleHint = false;
            for (i = 0; i < outputs.length; i++) {
                output = outputs[i];
                if (idleInhibit + output.idleInhibit == 0) {
                    output.idle();
                    idleHint = true;
                }
            }

            Session.SessionManager.idle = idleHint;
        }
    }

    /*
     * Methods
     */

    function wake() {
        var i;
        for (i = 0; i < outputs.length; i++) {
            idleTimer.restart();
            outputs[i].wake();
        }

        Session.SessionManager.idle = false;
    }

    function idle() {
        var i;
        for (i = 0; i < outputs.length; i++)
            outputs[i].idle();

        Session.SessionManager.idle = true;
    }

    function flash() {
        var i;
        for (i = 0; i < outputs.length; i++)
            outputs[i].flash();
    }

    function activateApp(appId) {
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].appId === appId) {
                windows[i].minimized = false;
                for (var j = 0; j < outputs.length; j++)
                    outputs[j].viewsBySurface[windows[i].surface].takeFocus();
            }
        }
    }

    function setAppMinimized(appId, minimized) {
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].appId === appId)
                windows[i].minimized = minimized;
        }
    }

    function quit() {
        layerShell.closeAllSurfaces();
        shellHelper.sendQuit();

        for (var i = 0; i < outputs.length; i++)
            outputs[i].window.close();

        Qt.quit();
    }
}
