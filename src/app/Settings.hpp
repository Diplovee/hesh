#pragma once

#include <QList>
#include <QHash>
#include <QString>

#include <memory>

#include "devices/DeviceProfile.hpp"

class QSettings;

namespace Hesh {

class Settings final
{
public:
    Settings(QString organization = QStringLiteral("Hesh"),
             QString application = QStringLiteral("Hesh"),
             QString filePath = {});
    ~Settings();

    Settings(const Settings&) = delete;
    Settings& operator=(const Settings&) = delete;

    QList<DeviceRecord> loadDevices() const;
    void saveDevices(const QList<DeviceRecord>& devices);

    QString selectedDeviceId() const;
    void setSelectedDeviceId(const QString& id);

    QHash<QString, QString> loadShortcuts() const;
    void saveShortcuts(const QHash<QString, QString>& shortcuts);

private:
    std::unique_ptr<QSettings> m_settings;
};

} // namespace Hesh
