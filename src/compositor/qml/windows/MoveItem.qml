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
import Liri.WaylandServer 1.0 as WS

Item {
    id: moveItem

    property bool moving: false

    onMovingChanged: {
        shellHelper.grabCursor(moving ? WS.LiriShell.MoveGrabCursor : WS.LiriShell.ArrowGrabCursor);
    }

    ParallelAnimation {
        id: moveAnimation

        SmoothedAnimation { id: xAnimator; target: moveItem; property: "x"; easing.type: Easing.InOutQuad; duration: 450 }
        SmoothedAnimation { id: yAnimator; target: moveItem; property: "y"; easing.type: Easing.InOutQuad; duration: 450 }
    }

    function animateTo(dx, dy) {
        xAnimator.to = dx;
        yAnimator.to = dy;
        moveAnimation.start();
    }
}
