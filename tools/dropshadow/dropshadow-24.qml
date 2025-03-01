// SPDX-FileCopyrightText: 2021 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15
import Fluid.Effects 1.0 as FluidEffects

ApplicationWindow {
    width: 150
    height: 150
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    visible: true

    Rectangle {
        anchors.centerIn: parent
        width: parent.width / 3
        height: parent.height / 3
        color: "purple"
        radius: 4

        Rectangle {
            anchors.fill: parent
            color: "purple"
        }

        layer.enabled: true
        layer.effect: FluidEffects.Elevation {
            elevation: 24
        }
    }
}
