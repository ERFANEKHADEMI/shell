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

#include <QtQml/QtQml>

#include "application.h"
#include "applicationmanager.h"
#include "categoriesmodel.h"
#include "frequentmodel.h"
#include "launchermodel.h"
#include "pagemodel.h"

class LauncherPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri)
    {
        // @uri Liri.Launcher
        Q_ASSERT(QLatin1String(uri) == QLatin1String("Liri.Launcher"));

        qmlRegisterType<ApplicationManager>(uri, 1, 0, "ApplicationManager");
        qmlRegisterType<CategoriesModel>(uri, 1, 0, "CategoriesModel");
        qmlRegisterType<LauncherModel>(uri, 1, 0, "LauncherModel");
        qmlRegisterType<PageModel>(uri, 1, 0, "PageModel");
        qmlRegisterType<FrequentAppsModel>(uri, 1, 0, "FrequentAppsModel");
        qmlRegisterUncreatableType<Application>(uri, 1, 0, "Application",
                                                QStringLiteral("Cannot instantiate Application"));
        qmlRegisterUncreatableType<DesktopFileAction>(uri, 1, 0, "DesktopFileAction",
                                                      QStringLiteral("Cannot instantiate DesktopFileAction"));
    }
};

#include "plugin.moc"
