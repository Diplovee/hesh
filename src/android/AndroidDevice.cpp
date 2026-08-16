#include "AndroidDevice.hpp"

#include <utility>

#include "app/FeatureFlags.hpp"

namespace Hesh {

AndroidDevice::AndroidDevice(QString id,
                             QString name,
                             DeviceProfile profile,
                             QString avdName,
                             QString adbSerial,
                             QObject* parent)
    : Device(std::move(id), std::move(name), DeviceType::Android, std::move(profile), parent)
    , m_avdName(std::move(avdName))
    , m_adbSerial(std::move(adbSerial))
    , m_runtime(new AndroidRuntime(m_avdName, m_adbSerial, this))
{
    connect(m_runtime, &AndroidRuntime::stateChanged, this, &AndroidDevice::syncRuntimeState);
    connect(m_runtime, &AndroidRuntime::errorChanged, this, [this] {
        emit errorMessageChanged();
        emit dataChanged();
    });
    connect(m_runtime, &AndroidRuntime::bootedChanged, this, [this] {
        emit bootedChanged();
        emit dataChanged();
    });
    connect(m_runtime, &AndroidRuntime::displayAvailableChanged, this, [this] {
        emit displayAvailableChanged();
        emit dataChanged();
    });
    connect(m_runtime, &AndroidRuntime::runtimeError, this, &AndroidDevice::syncRuntimeError);
    connect(m_runtime, &AndroidRuntime::processStarted, this, &AndroidDevice::handleProcessStarted);
    connect(m_runtime, &AndroidRuntime::processStopped, this, &AndroidDevice::handleProcessStopped);
}

QString AndroidDevice::avdName() const
{
    return m_avdName;
}

QString AndroidDevice::adbSerial() const
{
    return m_runtime->serial();
}

QString AndroidDevice::runtimeState() const
{
    return m_runtime->state();
}

QString AndroidDevice::errorMessage() const
{
    return m_runtime->errorMessage();
}

bool AndroidDevice::booted() const
{
    return m_runtime->booted();
}

bool AndroidDevice::displayAvailable() const
{
    return m_runtime->displayAvailable();
}

bool AndroidDevice::featureLocked() const
{
    return !androidRuntimeEnabled;
}

AndroidRuntime* AndroidDevice::runtime() const
{
    return m_runtime;
}

bool AndroidDevice::openDisplay()
{
    if (featureLocked()) {
        return false;
    }
    return m_runtime->openDisplay();
}

bool AndroidDevice::sendHome()
{
    if (featureLocked()) {
        return false;
    }
    return m_runtime->sendKeyEvent(3);
}

bool AndroidDevice::sendBack()
{
    if (featureLocked()) {
        return false;
    }
    return m_runtime->sendKeyEvent(4);
}

bool AndroidDevice::sendRecents()
{
    if (featureLocked()) {
        return false;
    }
    return m_runtime->sendKeyEvent(187);
}

bool AndroidDevice::rotateDevice()
{
    if (featureLocked()) {
        return false;
    }
    return m_runtime->rotate();
}

bool AndroidDevice::installApk(const QString& apkPath)
{
    if (featureLocked()) {
        return false;
    }
    return m_runtime->installApk(apkPath);
}

void AndroidDevice::start()
{
    if (featureLocked()) {
        setStatus(Status::Stopped);
        return;
    }
    setStatus(Status::Starting);
    if (!m_runtime->start()) {
        setStatus(Status::Error);
    }
}

void AndroidDevice::stop()
{
    m_runtime->stop();
    setStatus(Status::Stopped);
}

void AndroidDevice::syncRuntimeState()
{
    const auto state = m_runtime->state();
    if (state == QStringLiteral("Starting")) {
        setStatus(Status::Starting);
    } else if (state == QStringLiteral("Running")) {
        setStatus(Status::Running);
    } else if (state == QStringLiteral("Error")) {
        setStatus(Status::Error);
    } else {
        setStatus(Status::Stopped);
    }
    emit runtimeStateChanged();
    emit dataChanged();
}

void AndroidDevice::syncRuntimeError(const QString& message)
{
    Q_UNUSED(message)
    setStatus(Status::Error);
    emit errorMessageChanged();
    emit dataChanged();
}

void AndroidDevice::handleProcessStarted()
{
    setStatus(Status::Starting);
    emit dataChanged();
}

void AndroidDevice::handleProcessStopped()
{
    if (status() != Status::Error) {
        setStatus(Status::Stopped);
    }
    emit dataChanged();
}

} // namespace Hesh
