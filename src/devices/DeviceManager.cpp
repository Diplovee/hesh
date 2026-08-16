#include "DeviceManager.hpp"

#include <QDebug>
#include <QUuid>

#include "app/Settings.hpp"
#include "app/FeatureFlags.hpp"
#include "web/WebDevice.hpp"

namespace Hesh {

DeviceListModel::DeviceListModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int DeviceListModel::rowCount(const QModelIndex& parent) const
{
    return parent.isValid() ? 0 : m_devices.size();
}

QVariant DeviceListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_devices.size()) {
        return {};
    }

    const auto* device = m_devices.at(index.row());
    switch (role) {
    case DeviceObjectRole:
        return QVariant::fromValue(device);
    case DeviceIdRole:
        return device->id();
    case DeviceNameRole:
        return device->name();
    case DeviceTypeRole:
        return device->typeName();
    case DeviceTypeLabelRole:
        return device->typeLabel();
    case DeviceStatusRole:
        return device->statusName();
    case DeviceProfileRole:
        return device->profileName();
    case DeviceUrlRole: {
        const auto* webDevice = qobject_cast<const WebDevice*>(device);
        return webDevice ? webDevice->url() : QString {};
    }
    case DevicePresentationRole: {
        const auto* webDevice = qobject_cast<const WebDevice*>(device);
        return webDevice ? webDevice->presentationState() : QStringLiteral("Embedded");
    }
    case Qt::DisplayRole:
        return device->name();
    default:
        return {};
    }
}

QHash<int, QByteArray> DeviceListModel::roleNames() const
{
    return {
        {DeviceObjectRole, "deviceObject"},
        {DeviceIdRole, "deviceId"},
        {DeviceNameRole, "deviceName"},
        {DeviceTypeRole, "deviceType"},
        {DeviceTypeLabelRole, "deviceTypeLabel"},
        {DeviceStatusRole, "deviceStatus"},
        {DeviceProfileRole, "deviceProfile"},
        {DeviceUrlRole, "deviceUrl"},
        {DevicePresentationRole, "devicePresentationState"},
    };
}

void DeviceListModel::insertDevice(int row, Device* device)
{
    beginInsertRows({}, row, row);
    m_devices.insert(row, device);
    endInsertRows();
}

void DeviceListModel::removeDevice(int row)
{
    if (row < 0 || row >= m_devices.size()) {
        return;
    }
    beginRemoveRows({}, row, row);
    m_devices.removeAt(row);
    endRemoveRows();
}

Device* DeviceListModel::at(int row) const
{
    return row >= 0 && row < m_devices.size() ? m_devices.at(row) : nullptr;
}

int DeviceListModel::indexOf(const Device* device) const
{
    return m_devices.indexOf(const_cast<Device*>(device));
}

DeviceManager::DeviceManager(Settings* settings, QObject* parent)
    : QObject(parent)
    , m_model(this)
    , m_settings(settings)
{
    load();
}

QAbstractListModel* DeviceManager::devices()
{
    return &m_model;
}

Device* DeviceManager::selectedDevice() const
{
    return m_selectedDevice;
}

int DeviceManager::deviceCount() const
{
    return m_model.rowCount();
}

QVariantList DeviceManager::availableProfiles() const
{
    return deviceProfileCatalogForQml();
}

bool DeviceManager::androidFeatureEnabled() const
{
    return androidRuntimeEnabled;
}

WebDevice* DeviceManager::createWebDevice(const QString& requestedName,
                                          const QString& profileName,
                                          const QString& requestedUrl)
{
    const auto name = requestedName.trimmed().isEmpty()
        ? QStringLiteral("Web Device")
        : requestedName.trimmed();
    const auto url = requestedUrl.trimmed().isEmpty()
        ? QStringLiteral("http://localhost:3000")
        : WebDevice::normalizeUrl(requestedUrl);
    const auto profile = DeviceProfile::fromName(profileName);
    auto* device = new WebDevice(
        QUuid::createUuid().toString(QUuid::WithoutBraces), name, profile, url, this);
    addDevice(device, true);
    device->start();
    persist();
    return device;
}

AndroidDevice* DeviceManager::createAndroidDevice(const QString& requestedName,
                                                  const QString& profileName,
                                                  const QString& requestedAvdName,
                                                  const QString& requestedSerial)
{
    if (!androidFeatureEnabled()) {
        qWarning() << "Android runtime is locked because it is disabled by the build configuration";
        return nullptr;
    }

    const auto name = requestedName.trimmed().isEmpty()
        ? QStringLiteral("Android Device")
        : requestedName.trimmed();
    const auto avdName = requestedAvdName.trimmed();
    const auto serial = requestedSerial.trimmed();
    const auto profile = DeviceProfile::fromName(profileName);
    auto* device = new AndroidDevice(
        QUuid::createUuid().toString(QUuid::WithoutBraces), name, profile, avdName, serial, this);
    addDevice(device, true);
    device->start();
    persist();
    return device;
}

void DeviceManager::removeDevice(const QString& id)
{
    auto* device = findById(id);
    if (!device) {
        return;
    }

    const auto row = m_model.indexOf(device);
    if (auto* webDevice = qobject_cast<WebDevice*>(device); webDevice && webDevice->isStandalone()) {
        returnToEmbedded(id);
    }
    if (auto* androidDevice = qobject_cast<AndroidDevice*>(device)) {
        androidDevice->stop();
    }
    const bool wasSelected = device == m_selectedDevice;
    if (wasSelected) {
        Device* replacement = nullptr;
        if (row + 1 < m_model.rowCount()) {
            replacement = m_model.at(row + 1);
        } else if (row > 0) {
            replacement = m_model.at(row - 1);
        }
        setSelectedDevice(replacement);
    }

    m_model.removeDevice(row);
    device->deleteLater();
    emit deviceCountChanged();
    persist();
}

void DeviceManager::selectDevice(const QString& id)
{
    setSelectedDevice(findById(id));
}

void DeviceManager::startDevice(const QString& id)
{
    if (auto* device = findById(id)) {
        if (qobject_cast<AndroidDevice*>(device) && !androidFeatureEnabled()) {
            qWarning() << "Android runtime is locked; refusing to start";
            return;
        }
        device->start();
        persist();
    }
}

void DeviceManager::stopDevice(const QString& id)
{
    if (auto* device = findById(id)) {
        device->stop();
        persist();
    }
}

bool DeviceManager::openStandalone(const QString& id)
{
    auto* device = qobject_cast<WebDevice*>(findById(id));
    if (!device || device->isStandalone()) {
        return false;
    }
    device->setPresentationState(WebDevice::PresentationState::Standalone);
    emit standaloneRequested(device);
    return true;
}

void DeviceManager::returnToEmbedded(const QString& id)
{
    auto* device = qobject_cast<WebDevice*>(findById(id));
    if (!device || !device->isStandalone()) {
        return;
    }
    device->setPresentationState(WebDevice::PresentationState::Embedded);
    emit embeddedRequested(device);
}

bool DeviceManager::isStandalone(const QString& id) const
{
    const auto* device = qobject_cast<const WebDevice*>(findById(id));
    return device && device->isStandalone();
}

void DeviceManager::load()
{
    if (!m_settings) {
        return;
    }

    for (const auto& record : m_settings->loadDevices()) {
        Device* device = nullptr;
        if (deviceTypeFromString(record.type) == DeviceType::Android) {
            auto* androidDevice = new AndroidDevice(record.id,
                                                    record.name,
                                                    DeviceProfile::fromName(record.profileName),
                                                    record.avdName,
                                                    record.adbSerial,
                                                    this);
            device = androidDevice;
        } else {
            auto* webDevice = new WebDevice(record.id,
                                            record.name,
                                            DeviceProfile::fromName(record.profileName),
                                            record.url,
                                            this);
            webDevice->setOrientation(record.orientation);
            device = webDevice;
        }
        addDevice(device, false);
        if (!qobject_cast<AndroidDevice*>(device) || androidFeatureEnabled()) {
            device->start();
        }
    }

    if (auto* saved = findById(m_settings->selectedDeviceId())) {
        setSelectedDevice(saved);
    } else if (m_model.rowCount() > 0) {
        setSelectedDevice(m_model.at(0));
    }
}

void DeviceManager::addDevice(Device* device, bool select)
{
    if (!device) {
        return;
    }

    const auto row = m_model.rowCount();
    m_model.insertDevice(row, device);
    connect(device, &Device::dataChanged, this, [this, device] {
        const auto row = m_model.indexOf(device);
        if (row >= 0) {
            const auto modelIndex = m_model.index(row);
            emit m_model.dataChanged(modelIndex, modelIndex, {});
        }
        persist();
    });
    if (select) {
        setSelectedDevice(device);
    }
    emit deviceCountChanged();
}

void DeviceManager::persist() const
{
    if (!m_settings) {
        return;
    }

    QList<DeviceRecord> records;
    for (int row = 0; row < m_model.rowCount(); ++row) {
        const auto* device = m_model.at(row);
        DeviceRecord record;
        record.id = device->id();
        record.name = device->name();
        record.type = device->typeName();
        record.profileName = device->profileName();
        if (const auto* webDevice = qobject_cast<const WebDevice*>(device)) {
            record.url = webDevice->url();
            record.orientation = webDevice->orientation().toLower();
        }
        if (const auto* androidDevice = qobject_cast<const AndroidDevice*>(device)) {
            record.avdName = androidDevice->avdName();
            record.adbSerial = androidDevice->adbSerial();
        }
        records.append(record);
    }

    m_settings->saveDevices(records);
    m_settings->setSelectedDeviceId(m_selectedDevice ? m_selectedDevice->id() : QString {});
}

Device* DeviceManager::findById(const QString& id) const
{
    if (id.isEmpty()) {
        return nullptr;
    }
    for (int row = 0; row < m_model.rowCount(); ++row) {
        if (m_model.at(row)->id() == id) {
            return m_model.at(row);
        }
    }
    return nullptr;
}

void DeviceManager::setSelectedDevice(Device* device)
{
    if (device == m_selectedDevice) {
        return;
    }
    m_selectedDevice = device;
    emit selectedDeviceChanged();
    if (m_settings) {
        m_settings->setSelectedDeviceId(m_selectedDevice ? m_selectedDevice->id() : QString {});
    }
}

} // namespace Hesh
