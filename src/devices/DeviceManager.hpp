#pragma once

#include <QAbstractListModel>
#include <QList>
#include <QObject>
#include <QVariantList>

#include "Device.hpp"
#include "android/AndroidDevice.hpp"
#include "web/WebDevice.hpp"

namespace Hesh {

class Settings;

class DeviceListModel final : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Role {
        DeviceObjectRole = Qt::UserRole + 1,
        DeviceIdRole,
        DeviceNameRole,
        DeviceTypeRole,
        DeviceTypeLabelRole,
        DeviceStatusRole,
        DeviceProfileRole,
        DeviceUrlRole,
        DevicePresentationRole,
        DeviceRuntimeStateRole,
    };
    Q_ENUM(Role)

    explicit DeviceListModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void insertDevice(int row, Device* device);
    void removeDevice(int row);
    Device* at(int row) const;
    int indexOf(const Device* device) const;

private:
    QList<Device*> m_devices;
};

class DeviceManager final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QAbstractListModel* devices READ devices CONSTANT)
    Q_PROPERTY(Device* selectedDevice READ selectedDevice NOTIFY selectedDeviceChanged)
    Q_PROPERTY(int deviceCount READ deviceCount NOTIFY deviceCountChanged)
    Q_PROPERTY(QVariantList availableProfiles READ availableProfiles CONSTANT)
    Q_PROPERTY(bool androidFeatureEnabled READ androidFeatureEnabled CONSTANT)

public:
    explicit DeviceManager(Settings* settings, QObject* parent = nullptr);

    QAbstractListModel* devices();
    Device* selectedDevice() const;
    int deviceCount() const;
    QVariantList availableProfiles() const;
    bool androidFeatureEnabled() const;

    Q_INVOKABLE WebDevice* createWebDevice(const QString& name,
                                           const QString& profileName,
                                           const QString& url);
    Q_INVOKABLE WebDevice* webDevice(const QString& id) const;
    Q_INVOKABLE Device* deviceById(const QString& id) const;
    Q_INVOKABLE bool renameDevice(const QString& id, const QString& name);
    Q_INVOKABLE bool editWebDevice(const QString& id,
                                   const QString& name,
                                   const QString& profileName,
                                   const QString& url,
                                   const QString& orientation,
                                   const QString& userAgent);
    Q_INVOKABLE WebDevice* duplicateWebDevice(const QString& id, const QString& name);
    Q_INVOKABLE AndroidDevice* createAndroidDevice(const QString& name,
                                                   const QString& profileName,
                                                   const QString& avdName,
                                                   const QString& adbSerial);
    Q_INVOKABLE void removeDevice(const QString& id);
    Q_INVOKABLE void selectDevice(const QString& id);
    Q_INVOKABLE void selectNextDevice();
    Q_INVOKABLE void selectPreviousDevice();
    Q_INVOKABLE void startDevice(const QString& id);
    Q_INVOKABLE void stopDevice(const QString& id);
    Q_INVOKABLE bool reloadDevice(const QString& id, bool hardReload = false);
    Q_INVOKABLE bool reloadSelectedDevice(bool hardReload = false);
    Q_INVOKABLE bool openStandalone(const QString& id);
    Q_INVOKABLE void returnToEmbedded(const QString& id);
    Q_INVOKABLE bool isStandalone(const QString& id) const;

signals:
    void selectedDeviceChanged();
    void deviceCountChanged();
    void standaloneRequested(WebDevice* device);
    void embeddedRequested(WebDevice* device);

private:
    void load();
    void addDevice(Device* device, bool select);
    void persist() const;
    Device* findById(const QString& id) const;
    void setSelectedDevice(Device* device);

    DeviceListModel m_model;
    Settings* m_settings = nullptr;
    Device* m_selectedDevice = nullptr;
};

} // namespace Hesh
