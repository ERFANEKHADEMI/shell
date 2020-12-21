/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 * Copyright (C) 2017 Michael Spencer <sonrisesoftware@gmail.com>
 *
 * $BEGIN_LICENSE:GPL3+$
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * $END_LICENSE$
 ***************************************************************************/

import QtQuick 2.5
import QtQuick.Window 2.3
import QtQuick.Controls 2.0
import QtWayland.Compositor 1.0
import Liri.Shell 1.0 as LiriShell
import Liri.private.shell 1.0 as P
import "desktop"

P.WaylandOutput {
    id: output

    readonly property bool primary: liriCompositor.defaultOutput === this

    property var screen: null

    property var viewsBySurface: ({})

    property int idleInhibit: 0

    readonly property alias screenView: screenView
    readonly property Item surfacesArea: screenView.surfacesArea
    //readonly property alias idleDimmer: idleDimmer
    readonly property alias cursor: cursor

    readonly property var layers: QtObject {
        readonly property alias background: backgroundLayer
        readonly property alias bottom: bottomLayer
        readonly property alias top: topLayer
        readonly property alias overlay: overlayLayer
    }

    property var exportDmabufFrame: null

    property bool __idle: false

    sizeFollowsWindow: false
    automaticFrameCallback: screen && screen.enabled && screen.powerState === P.ScreenItem.PowerStateOn

    Connections {
        target: output.screen

        function onCurrentModeChanged(resolution, refreshRate) {
            output.setCurrentOutputMode(resolution, refreshRate);
        }
    }

    Component.onCompleted: {
        if (output.screen) {
            for (var i = 0; i < output.screen.modes.length; i++) {
                var screenMode = output.screen.modes[i];
                var isPreferred = output.screen.preferredMode.resolution === screenMode.resolution &&
                        output.screen.preferredMode.refreshRateRate === screenMode.refreshRate;
                var isCurrent = output.screen.currentMode.resolution === screenMode.resolution &&
                        output.screen.currentMode.refreshRate === screenMode.refreshRate;
                output.addOutputMode(screenMode.resolution, screenMode.refreshRate, isPreferred, isCurrent);
            }
        }
    }

    window: ApplicationWindow {
        id: outputWindow

        x: output.position.x
        y: output.position.y
        width: output.geometry.width
        height: output.geometry.height
        flags: Qt.Window | Qt.FramelessWindowHint
        screen: output.screen ? Qt.application.screens[output.screen.screenIndex] : null
        color: "black"
        visible: output.screen.enabled

        // Virtual Keyboard
        Loader {
            parent: outputWindow.overlay
            active: liriCompositor.settings.ui.inputMethod === "qtvirtualkeyboard"
            source: Qt.resolvedUrl("base/Keyboard.qml")
            x: (parent.width - width) / 2
            y: parent.height - height
            z: 999
            width: Math.max(parent.width / 2, 768)
        }

        // Keyboard handling
        P.KeyEventFilter {
            Keys.onPressed: {
                // Input wakes the output
                liriCompositor.wake();

                screenView.handleKeyPressed(event);
            }

            Keys.onReleased: {
                // Input wakes the output
                liriCompositor.wake();

                screenView.handleKeyReleased(event);
            }
        }

        // Mouse tracker
        P.WindowMouseTracker {
            id: mouseTracker

            anchors.fill: parent

            windowSystemCursorEnabled: false

            onMouseXChanged: {
                // Wake up
                liriCompositor.wake();

                // Update global mouse position
                liriCompositor.mousePos.x = output.position.x + mouseX;
            }
            onMouseYChanged: {
                // Wake up
                liriCompositor.wake();

                // Update global mouse position
                liriCompositor.mousePos.y = output.position.y + mouseY;
            }
            // TODO: Need to wake up with mouse button pressed, released and wheel

            // This is needed so the grab surface will receive pointer events
            WaylandQuickItem {
                surface: shellHelper.grabSurface
                focusOnClick: false
                touchEventsEnabled: false
                sizeFollowsSurface: true

                onSurfaceDestroyed: {
                    destroy();
                }
            }

            // Background
            Item {
                id: backgroundLayer

                anchors.fill: parent
            }

            // Bottom
            Item {
                id: bottomLayer

                anchors.fill: parent
            }

            // User interface
            ScreenView {
                id: screenView

                objectName: "screenView"
                anchors.fill: parent
            }

            // Top
            Item {
                id: topLayer

                anchors.fill: parent
            }

            // Overlays
            Item {
                id: overlayLayer

                anchors.fill: parent
            }

            // Flash for screenshots
            Rectangle {
                id: flash

                anchors.fill: parent

                color: "white"
                opacity: 0.0

                SequentialAnimation {
                    id: flashAnimation

                    OpacityAnimator {
                        easing.type: Easing.OutQuad
                        target: flash
                        from: 0.0
                        to: 1.0
                        duration: 250
                    }
                    OpacityAnimator {
                        easing.type: Easing.OutQuad
                        target: flash
                        from: 1.0
                        to: 0.0
                        duration: 250
                    }
                }
            }

            // Idle dimmer
            IdleDimmer {
                id: idleDimmer

                anchors.fill: parent

                output: output

                z: 1000002
            }
        }

        // Pointer cursor
        WaylandCursorItem {
            id: cursor

            parent: mouseTracker.parent
            seat: liriCompositor.defaultSeat

            x: mouseTracker.mouseX
            y: mouseTracker.mouseY
            z: 1000001

            visible: mouseTracker.containsMouse &&
                     !mouseTracker.windowSystemCursorEnabled &&
                     screenView.cursorVisible
        }
    }

    /*
     * Methods
     */

    function wake() {
        if (!__idle)
            return;

        console.debug("Power on output", manufacturer, model);
        idleDimmer.fadeOut();
        screen.powerState = P.ScreenItem.PowerStateOn;
        __idle = false;
    }

    function idle() {
        if (__idle)
            return;

        console.debug("Standby output", manufacturer, model);
        idleDimmer.fadeIn();
        __idle = true;
    }

    function flash() {
        flashAnimation.start();
    }
}
