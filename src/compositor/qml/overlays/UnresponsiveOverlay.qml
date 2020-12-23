/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini
 *
 * Author(s):
 *    Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Colorize {
    property alias window: root.source

    id: root
    hue: 0.0
    saturation: 0.5
    lightness: -0.5
    z: 1

    Behavior on opacity {
        NumberAnimation {
            easing.type: Easing.Linear
            duration: 250
        }
    }

    // Automatically ping the surface
    Timer {
        running: window.unresponsive
        interval: 10000
        onTriggered: window.pingSurface()
    }

    // Block input on the surface
    MouseArea {
        anchors.fill: parent
        enabled: window.unresponsive
        cursorShape: Qt.BusyCursor
        z: 1
    }

    ColumnLayout {
        anchors.fill: parent
        enabled: window.unresponsive
        z: 2

        Item {
            Layout.fillHeight: true
        }

        Text {
            font.bold: true
            font.pointSize: 14
            color: "#f1f1f1"
            text: qsTr("Application is not responding")
            horizontalAlignment: Qt.AlignHCenter

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
        }

        Text {
            font.pointSize: 10
            color: "#f1f1f1"
            text: qsTr("This application is unresponsive, you may choose to wait " +
                       "a short while for it to continue or force the application to " +
                       "quit entirely.")
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.Wrap

            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
        }

        RowLayout {
            Button {
                text: qsTr("Wait")
                onClicked: window.pingSurface()
            }

            Button {
                text: qsTr("Force Quit")
                onClicked: window.child.surface.client.kill()
            }

            Layout.alignment: Qt.AlignHCenter
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
