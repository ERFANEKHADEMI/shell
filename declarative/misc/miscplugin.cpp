/****************************************************************************
 * This file is part of Hawaii.
 *
 * Copyright (C) 2014-2016 Pier Luigi Fiorini
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

#include <QtQml>

#include "formats.h"
#include "miscplugin.h"

static QObject *formatsProvider(QQmlEngine *, QJSEngine *)
{
    return new Formats();
}

void MiscPlugin::registerTypes(const char *uri)
{
    // @uri org.hawaiios.misc
    Q_ASSERT(uri == QLatin1String("org.hawaiios.misc"));

    qmlRegisterSingletonType<Formats>(uri, 0, 1, "Format", formatsProvider);
    qRegisterMetaType<QLocale::FormatType>();
    qmlRegisterUncreatableType<KFormat>(uri, 0, 1, "FormatTypes", "");
}
