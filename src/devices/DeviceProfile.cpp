#include "DeviceProfile.hpp"

#include <QJsonArray>
#include <QJsonValue>

namespace Hesh {

QString deviceTypeToString(DeviceType type)
{
    switch (type) {
    case DeviceType::Web:
        return QStringLiteral("web");
    case DeviceType::Android:
        return QStringLiteral("android");
    }
    return QStringLiteral("web");
}

DeviceType deviceTypeFromString(const QString& value)
{
    return value.compare(QStringLiteral("android"), Qt::CaseInsensitive) == 0
        ? DeviceType::Android
        : DeviceType::Web;
}

QList<DeviceProfile> DeviceProfile::catalog()
{
    return {
        {QStringLiteral("Pixel 7"), 412, 915, 2.625,
         QStringLiteral("Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36")},
        {QStringLiteral("Pixel 8"), 412, 915, 2.75,
         QStringLiteral("Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36")},
        {QStringLiteral("iPhone 14"), 390, 844, 3.0,
         QStringLiteral("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 Version/16.0 Mobile/15E148 Safari/604.1")},
        {QStringLiteral("Galaxy S24"), 360, 780, 3.0,
         QStringLiteral("Mozilla/5.0 (Linux; Android 14; SM-S921B) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36")},
        {QStringLiteral("iPad"), 820, 1180, 2.0,
         QStringLiteral("Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Version/17.0 Mobile/15E148 Safari/604.1")},
        {QStringLiteral("Desktop"), 1440, 900, 1.0,
         QStringLiteral("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36")},
        {QStringLiteral("Custom"), 412, 915, 1.0,
         QStringLiteral("Mozilla/5.0 AppleWebKit/537.36 Chrome/120.0 Safari/537.36")},
    };
}

DeviceProfile DeviceProfile::fromName(const QString& profileName)
{
    const auto profiles = catalog();
    for (const auto& profile : profiles) {
        if (profile.name == profileName) {
            return profile;
        }
    }
    return profiles.constFirst();
}

QJsonObject deviceRecordToJson(const DeviceRecord& record)
{
    QJsonArray recentUrls;
    for (const auto& url : record.recentUrls) {
        recentUrls.append(url);
    }

    const QJsonObject viewPreferences {
        {QStringLiteral("orientation"), record.orientation},
        {QStringLiteral("fitMode"), record.fitMode},
        {QStringLiteral("manualScale"), record.manualScale},
        {QStringLiteral("frameChromeVisible"), record.frameChromeVisible},
        {QStringLiteral("devToolsVisible"), record.devToolsVisible},
    };

    return {
        {QStringLiteral("id"), record.id},
        {QStringLiteral("name"), record.name},
        {QStringLiteral("type"), record.type},
        {QStringLiteral("profile"), record.profileName},
        {QStringLiteral("url"), record.url},
        {QStringLiteral("orientation"), record.orientation},
        {QStringLiteral("userAgent"), record.userAgent},
        {QStringLiteral("recentUrls"), recentUrls},
        {QStringLiteral("viewPreferences"), viewPreferences},
        {QStringLiteral("avd"), record.avdName},
        {QStringLiteral("serial"), record.adbSerial},
    };
}

std::optional<DeviceRecord> deviceRecordFromJson(const QJsonObject& object)
{
    const auto id = object.value(QStringLiteral("id")).toString();
    const auto name = object.value(QStringLiteral("name")).toString();
    if (id.isEmpty() || name.isEmpty()) {
        return std::nullopt;
    }

    DeviceRecord record;
    record.id = id;
    record.name = name;
    record.type = object.value(QStringLiteral("type")).toString(QStringLiteral("web"));
    record.profileName = object.value(QStringLiteral("profile")).toString(QStringLiteral("Pixel 7"));
    record.url = object.value(QStringLiteral("url")).toString(QStringLiteral("http://localhost:3000"));
    record.orientation = object.value(QStringLiteral("orientation")).toString(QStringLiteral("portrait"));
    record.userAgent = object.value(QStringLiteral("userAgent")).toString();

    const auto recentUrls = object.value(QStringLiteral("recentUrls"));
    if (recentUrls.isArray()) {
        for (const auto& value : recentUrls.toArray()) {
            if (value.isString()) {
                record.recentUrls.append(value.toString());
            }
        }
    }

    const auto viewPreferences = object.value(QStringLiteral("viewPreferences"));
    if (viewPreferences.isObject()) {
        const auto view = viewPreferences.toObject();
        record.orientation = view.value(QStringLiteral("orientation"))
                                 .toString(record.orientation);
        record.fitMode = view.value(QStringLiteral("fitMode"))
                             .toString(QStringLiteral("Fit"));
        record.manualScale = view.value(QStringLiteral("manualScale"))
                                 .toDouble(1.0);
        record.frameChromeVisible = view.value(QStringLiteral("frameChromeVisible"))
                                        .toBool(true);
        record.devToolsVisible = view.value(QStringLiteral("devToolsVisible"))
                                     .toBool(false);
    }

    if (record.fitMode.compare(QStringLiteral("Manual"), Qt::CaseInsensitive) != 0) {
        record.fitMode = QStringLiteral("Fit");
    } else {
        record.fitMode = QStringLiteral("Manual");
    }
    record.manualScale = qBound(0.1, record.manualScale, 3.0);
    record.avdName = object.value(QStringLiteral("avd")).toString();
    record.adbSerial = object.value(QStringLiteral("serial")).toString();
    return record;
}

QVariantList deviceProfileCatalogForQml()
{
    QVariantList profiles;
    for (const auto& profile : DeviceProfile::catalog()) {
        profiles.append(QVariantMap {
            {QStringLiteral("name"), profile.name},
            {QStringLiteral("width"), profile.width},
            {QStringLiteral("height"), profile.height},
            {QStringLiteral("devicePixelRatio"), profile.devicePixelRatio},
            {QStringLiteral("userAgent"), profile.userAgent},
        });
    }
    return profiles;
}

} // namespace Hesh
