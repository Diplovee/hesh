#pragma once

#include "android/AndroidRuntime.hpp"
#include "devices/Device.hpp"

namespace Hesh {

class AndroidDevice final : public Device
{
    Q_OBJECT
    Q_PROPERTY(QString avdName READ avdName CONSTANT)
    Q_PROPERTY(QString adbSerial READ adbSerial CONSTANT)
    Q_PROPERTY(QString runtimeState READ runtimeState NOTIFY runtimeStateChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(bool booted READ booted NOTIFY bootedChanged)
    Q_PROPERTY(bool displayAvailable READ displayAvailable NOTIFY displayAvailableChanged)
    Q_PROPERTY(bool featureLocked READ featureLocked CONSTANT)
    Q_PROPERTY(AndroidRuntime* runtime READ runtime CONSTANT)

public:
    AndroidDevice(QString id,
                  QString name,
                  DeviceProfile profile,
                  QString avdName,
                  QString adbSerial,
                  QObject* parent = nullptr);

    QString avdName() const;
    QString adbSerial() const;
    QString runtimeState() const;
    QString errorMessage() const;
    bool booted() const;
    bool displayAvailable() const;
    bool featureLocked() const;
    AndroidRuntime* runtime() const;

    Q_INVOKABLE bool openDisplay();
    Q_INVOKABLE bool reload();
    Q_INVOKABLE bool hardReload();
    Q_INVOKABLE bool sendHome();
    Q_INVOKABLE bool sendBack();
    Q_INVOKABLE bool sendRecents();
    Q_INVOKABLE bool rotateDevice();
    Q_INVOKABLE bool installApk(const QString& apkPath);

    void start() override;
    void stop() override;

signals:
    void runtimeStateChanged();
    void errorMessageChanged();
    void bootedChanged();
    void displayAvailableChanged();

private slots:
    void syncRuntimeState();
    void syncRuntimeError(const QString& message);
    void handleProcessStarted();
    void handleProcessStopped();

private:
    QString m_avdName;
    QString m_adbSerial;
    AndroidRuntime* m_runtime = nullptr;
};

} // namespace Hesh
