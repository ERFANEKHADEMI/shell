/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
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

import QtQuick 2.0
import QtWayland.Compositor 1.0
import Liri.private.shell 1.0 as P

P.XdgPopupV5 {
    id: xdgPopup

    readonly property alias mapped: details.mapped
    property bool activated: false
    readonly property bool minimized: false
    readonly property bool maximized: false
    readonly property bool fullscreen: false
    readonly property string title: ""

    property string canonicalAppId: surface ? applicationManager.canonicalizeAppId(surface.appId) : ""
    property string iconName: ""

    property bool decorated: false

    property WaylandSurface parentWlSurface: parentSurface
    property point offset: position

    readonly property bool responsive: true

    readonly property alias moveItem: moveItem

    QtObject {
        id: details

        property bool mapped: false
    }

    MoveItem {
        id: moveItem

        parent: rootItem
        width: surface ? surface.width : 0
        height: surface ? surface.height : 0
    }

    Connections {
        target: surface
        onHasContentChanged: {
            if (surface.hasContent) {
                // Set mapped flag which will make Chrome play the animation
                details.mapped = surface.hasContent;
            }
        }
    }

    Component.onDestruction: {
        __private.handleShellSurfaceDestroyed(xdgPopup);

        // Unset mapped flag which will make Chrome play the animation
        details.mapped = false;
    }
}
