// SPDX-FileCopyrightText: 2017 Michael Spencer <sonrisesoftware@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

#include "frequentmodel.h"

#include <QtCore/QDebug>
#include <QtCore/QFileInfo>

#include "applicationmanager.h"
#include "usagetracker.h"

QString appIdFromDesktopFile(const QString &desktopFile)
{
    return QFileInfo(desktopFile).completeBaseName();
}

FrequentAppsModel::FrequentAppsModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    sort(0, Qt::DescendingOrder);

    connect(UsageTracker::instance(), &UsageTracker::updated, this, &FrequentAppsModel::invalidate);
}

bool FrequentAppsModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    QModelIndex sourceIndex = sourceModel()->index(sourceRow, 0, sourceParent);
    QString appId = sourceModel()->data(sourceIndex, ApplicationManager::AppIdRole).toString();

    AppUsage *app = UsageTracker::instance()->usageForAppId(appId);

    return app != nullptr && app->score > 0;
}

bool FrequentAppsModel::lessThan(const QModelIndex &source_left,
                                 const QModelIndex &source_right) const
{
    QString leftAppId = sourceModel()->data(source_left, ApplicationManager::AppIdRole).toString();
    QString rightAppId = sourceModel()->data(source_right, ApplicationManager::AppIdRole).toString();

    AppUsage *leftApp = UsageTracker::instance()->usageForAppId(leftAppId);
    AppUsage *rightApp = UsageTracker::instance()->usageForAppId(rightAppId);

    if (leftApp == nullptr) {
        return false;
    } else if (rightApp == nullptr) {
        return true;
    } else {
        return leftApp->score < rightApp->score;
    }
}
