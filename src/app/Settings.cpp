#include "Settings.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>

namespace Hesh {

Settings::Settings(QString organization, QString application, QString filePath)
{
    if (filePath.isEmpty()) {
        m_settings = std::make_unique<QSettings>(std::move(organization), std::move(application));
    } else {
        m_settings = std::make_unique<QSettings>(std::move(filePath), QSettings::IniFormat);
    }
}

Settings::~Settings() = default;

QList<DeviceRecord> Settings::loadDevices() const
{
    const auto json = m_settings->value(QStringLiteral("devices")).toByteArray();
    if (json.isEmpty()) {
        return {};
    }

    const auto document = QJsonDocument::fromJson(json);
    if (!document.isArray()) {
        return {};
    }

    QList<DeviceRecord> records;
    for (const auto& value : document.array()) {
        if (!value.isObject()) {
            continue;
        }

        const auto record = deviceRecordFromJson(value.toObject());
        if (record.has_value()) {
            records.append(record.value());
        }
    }
    return records;
}

void Settings::saveDevices(const QList<DeviceRecord>& devices)
{
    QJsonArray array;
    for (const auto& device : devices) {
        array.append(deviceRecordToJson(device));
    }

    m_settings->setValue(QStringLiteral("devices"),
                         QJsonDocument(array).toJson(QJsonDocument::Compact));
    m_settings->sync();
}

QString Settings::selectedDeviceId() const
{
    return m_settings->value(QStringLiteral("selectedDeviceId")).toString();
}

void Settings::setSelectedDeviceId(const QString& id)
{
    m_settings->setValue(QStringLiteral("selectedDeviceId"), id);
    m_settings->sync();
}

} // namespace Hesh
