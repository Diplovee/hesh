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

QHash<QString, QString> Settings::loadShortcuts() const
{
    const auto json = m_settings->value(QStringLiteral("shortcuts")).toByteArray();
    if (json.isEmpty()) {
        return {};
    }

    const auto document = QJsonDocument::fromJson(json);
    if (!document.isObject()) {
        return {};
    }

    const auto object = document.object();
    QHash<QString, QString> shortcuts;
    for (auto it = object.constBegin(); it != object.constEnd(); ++it) {
        if (it.value().isString()) {
            shortcuts.insert(it.key(), it.value().toString());
        }
    }
    return shortcuts;
}

void Settings::saveShortcuts(const QHash<QString, QString>& shortcuts)
{
    if (shortcuts.isEmpty()) {
        m_settings->remove(QStringLiteral("shortcuts"));
        m_settings->sync();
        return;
    }

    QJsonObject object;
    for (auto it = shortcuts.constBegin(); it != shortcuts.constEnd(); ++it) {
        object.insert(it.key(), it.value());
    }
    m_settings->setValue(QStringLiteral("shortcuts"),
                         QJsonDocument(object).toJson(QJsonDocument::Compact));
    m_settings->sync();
}

} // namespace Hesh
