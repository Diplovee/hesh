#include "AndroidRuntime.hpp"

#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTimer>

#include <utility>

namespace Hesh {

AndroidRuntime::AndroidRuntime(QString avdName, QString serial, QObject* parent)
    : QObject(parent)
    , m_avdName(std::move(avdName))
    , m_serial(serial.trimmed().isEmpty() ? QStringLiteral("emulator-5554")
                                          : serial.trimmed())
    , m_emulatorProcess(new QProcess(this))
    , m_displayProcess(new QProcess(this))
    , m_bootTimer(new QTimer(this))
{
    m_bootTimer->setInterval(2000);
    connect(m_bootTimer, &QTimer::timeout, this, &AndroidRuntime::pollBootState);
    connect(m_emulatorProcess,
            &QProcess::started,
            this,
            &AndroidRuntime::handleEmulatorStarted);
    connect(m_emulatorProcess,
            &QProcess::errorOccurred,
            this,
            &AndroidRuntime::handleEmulatorError);
    connect(m_emulatorProcess,
            qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this,
            &AndroidRuntime::handleEmulatorFinished);
    connect(m_displayProcess,
            qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this,
            &AndroidRuntime::handleDisplayFinished);
}

AndroidRuntime::~AndroidRuntime()
{
    stop();
}

QString AndroidRuntime::avdName() const
{
    return m_avdName;
}

QString AndroidRuntime::serial() const
{
    return m_serial;
}

QString AndroidRuntime::state() const
{
    return m_state;
}

QString AndroidRuntime::errorMessage() const
{
    return m_errorMessage;
}

bool AndroidRuntime::booted() const
{
    return m_booted;
}

bool AndroidRuntime::displayAvailable() const
{
    return m_displayAvailable;
}

bool AndroidRuntime::scrcpyAvailable() const
{
    return !findScrcpy().isEmpty();
}

QString AndroidRuntime::findSdkTool(const QString& relativePath, const QString& executableName)
{
    const auto fromPath = QStandardPaths::findExecutable(executableName);
    if (!fromPath.isEmpty()) {
        return fromPath;
    }

    QStringList roots;
    const auto androidHome = qEnvironmentVariable("ANDROID_HOME").trimmed();
    const auto androidSdkRoot = qEnvironmentVariable("ANDROID_SDK_ROOT").trimmed();
    if (!androidHome.isEmpty()) {
        roots.append(androidHome);
    }
    if (!androidSdkRoot.isEmpty() && androidSdkRoot != androidHome) {
        roots.append(androidSdkRoot);
    }
    roots.append(QDir::home().filePath(QStringLiteral("Android/Sdk")));
    roots.append(QDir::home().filePath(QStringLiteral(".android/sdk")));

    for (const auto& root : roots) {
        const QFileInfo candidate(QDir(root).filePath(relativePath));
        if (candidate.isFile() && candidate.isExecutable()) {
            return candidate.absoluteFilePath();
        }
    }
    return {};
}

QString AndroidRuntime::findAdb()
{
    return findSdkTool(QStringLiteral("platform-tools/adb"), QStringLiteral("adb"));
}

QString AndroidRuntime::findEmulator()
{
    return findSdkTool(QStringLiteral("emulator/emulator"), QStringLiteral("emulator"));
}

QString AndroidRuntime::findScrcpy()
{
    return QStandardPaths::findExecutable(QStringLiteral("scrcpy"));
}

QString AndroidRuntime::runCommand(const QString& program,
                                   const QStringList& arguments,
                                   int timeoutMs,
                                   int* exitCode)
{
    if (exitCode) {
        *exitCode = -1;
    }
    if (program.isEmpty()) {
        return {};
    }

    QProcess process;
    process.start(program, arguments);
    if (!process.waitForStarted(1500)) {
        return {};
    }
    if (!process.waitForFinished(timeoutMs)) {
        process.kill();
        process.waitForFinished(1000);
        return {};
    }
    if (exitCode) {
        *exitCode = process.exitCode();
    }
    return QString::fromLocal8Bit(process.readAllStandardOutput()).trimmed();
}

QStringList AndroidRuntime::availableAvds()
{
    int exitCode = -1;
    const auto output = runCommand(findEmulator(), {QStringLiteral("-list-avds")}, 5000, &exitCode);
    if (exitCode != 0 || output.isEmpty()) {
        return {};
    }
    return output.split(QRegularExpression(QStringLiteral("[\\r\\n]+")), Qt::SkipEmptyParts);
}

bool AndroidRuntime::runAdb(const QStringList& arguments, QString* output) const
{
    const auto adb = findAdb();
    if (adb.isEmpty()) {
        return false;
    }

    int exitCode = -1;
    const auto timeoutMs = arguments.contains(QStringLiteral("install")) ? 120000 : 3000;
    const auto result = runCommand(adb, arguments, timeoutMs, &exitCode);
    if (output) {
        *output = result;
    }
    return exitCode == 0;
}

bool AndroidRuntime::start()
{
    if (m_state == QStringLiteral("Starting") || m_state == QStringLiteral("Running")) {
        return true;
    }

    if (m_emulatorProcess->state() != QProcess::NotRunning) {
        clearError();
        m_stopping = false;
        setState(QStringLiteral("Starting"));
        m_bootTimer->start();
        pollBootState();
        return true;
    }

    clearError();
    setBooted(false);
    setDisplayAvailable(false);

    const auto adb = findAdb();
    if (adb.isEmpty()) {
        setError(QStringLiteral("ADB was not found. Install Android SDK platform-tools or set ANDROID_HOME."));
        return false;
    }

    if (m_avdName.trimmed().isEmpty()) {
        setError(QStringLiteral("No AVD name is configured for this Android device."));
        return false;
    }

    const auto emulator = findEmulator();
    if (emulator.isEmpty()) {
        setError(QStringLiteral("The Android emulator was not found. Install the SDK emulator package or set ANDROID_HOME."));
        return false;
    }

    m_stopping = false;
    QStringList arguments {
        QStringLiteral("-avd"),
        m_avdName,
        QStringLiteral("-no-boot-anim"),
        QStringLiteral("-no-snapshot-load"),
    };
    const QRegularExpression serialPattern(QStringLiteral("^emulator-(\\d+)$"));
    const auto serialMatch = serialPattern.match(m_serial);
    if (serialMatch.hasMatch()) {
        arguments.append(QStringLiteral("-port"));
        arguments.append(serialMatch.captured(1));
    }
    if (scrcpyAvailable()) {
        arguments.append(QStringLiteral("-no-window"));
    }

    setState(QStringLiteral("Starting"));
    m_emulatorProcess->start(emulator, arguments);
    if (!m_emulatorProcess->waitForStarted(1500)) {
        setError(QStringLiteral("Could not start the Android emulator: %1")
                     .arg(m_emulatorProcess->errorString()));
        return false;
    }

    return true;
}

void AndroidRuntime::stop()
{
    m_stopping = true;
    m_bootTimer->stop();

    if (m_displayProcess->state() != QProcess::NotRunning) {
        m_displayProcess->terminate();
        if (!m_displayProcess->waitForFinished(1500)) {
            m_displayProcess->kill();
            m_displayProcess->waitForFinished(1000);
        }
    }
    setDisplayAvailable(false);

    if (m_emulatorProcess->state() != QProcess::NotRunning) {
        m_emulatorProcess->terminate();
        if (!m_emulatorProcess->waitForFinished(2500)) {
            m_emulatorProcess->kill();
            m_emulatorProcess->waitForFinished(1000);
        }
    }

    setBooted(false);
    setState(QStringLiteral("Stopped"));
    m_stopping = false;
}

bool AndroidRuntime::openDisplay()
{
    if (!m_booted) {
        setError(QStringLiteral("The Android emulator is not booted yet."));
        return false;
    }
    if (!scrcpyAvailable()) {
        setDisplayAvailable(true);
        return true;
    }
    if (m_displayProcess->state() != QProcess::NotRunning) {
        return true;
    }

    const auto scrcpy = findScrcpy();
    const QStringList arguments {
        QStringLiteral("--serial"),
        m_serial,
        QStringLiteral("--window-title"),
        QStringLiteral("Hesh Android %1").arg(m_avdName),
        QStringLiteral("--no-audio"),
    };
    m_displayProcess->start(scrcpy, arguments);
    if (!m_displayProcess->waitForStarted(1500)) {
        setError(QStringLiteral("Could not start scrcpy: %1")
                     .arg(m_displayProcess->errorString()));
        return false;
    }
    setDisplayAvailable(true);
    return true;
}

bool AndroidRuntime::sendKeyEvent(int keyCode)
{
    if (!m_booted) {
        return false;
    }
    QString ignored;
    return runAdb({QStringLiteral("-s"), m_serial, QStringLiteral("shell"),
                   QStringLiteral("input"), QStringLiteral("keyevent"), QString::number(keyCode)},
                  &ignored);
}

bool AndroidRuntime::rotate()
{
    if (!m_booted) {
        return false;
    }
    QString ignored;
    if (!runAdb({QStringLiteral("-s"), m_serial, QStringLiteral("shell"), QStringLiteral("settings"),
                 QStringLiteral("put"), QStringLiteral("system"), QStringLiteral("accelerometer_rotation"),
                 QStringLiteral("0")}, &ignored)) {
        return false;
    }
    return runAdb({QStringLiteral("-s"), m_serial, QStringLiteral("shell"), QStringLiteral("settings"),
                   QStringLiteral("put"), QStringLiteral("system"), QStringLiteral("user_rotation"),
                   QStringLiteral("1")}, &ignored);
}

bool AndroidRuntime::installApk(const QString& apkPath)
{
    if (!m_booted || apkPath.trimmed().isEmpty()) {
        return false;
    }
    QString ignored;
    return runAdb({QStringLiteral("-s"), m_serial, QStringLiteral("install"), QStringLiteral("-r"), apkPath},
                  &ignored);
}

void AndroidRuntime::pollBootState()
{
    if (m_emulatorProcess->state() == QProcess::NotRunning) {
        m_bootTimer->stop();
        return;
    }

    QString state;
    if (!runAdb({QStringLiteral("-s"), m_serial, QStringLiteral("get-state")}, &state)
        || state != QStringLiteral("device")) {
        return;
    }

    QString bootProperty;
    if (!runAdb({QStringLiteral("-s"), m_serial, QStringLiteral("shell"), QStringLiteral("getprop"),
                 QStringLiteral("sys.boot_completed")}, &bootProperty)
        || bootProperty != QStringLiteral("1")) {
        return;
    }

    m_bootTimer->stop();
    setBooted(true);
    setState(QStringLiteral("Running"));
    setDisplayAvailable(!scrcpyAvailable());
    openDisplay();
}

void AndroidRuntime::handleEmulatorStarted()
{
    setState(QStringLiteral("Starting"));
    emit processStarted();
    m_bootTimer->start();
    pollBootState();
}

void AndroidRuntime::handleEmulatorError(QProcess::ProcessError error)
{
    if (m_stopping) {
        return;
    }
    const auto details = m_emulatorProcess->errorString();
    setError(QStringLiteral("Android emulator error (%1): %2")
                 .arg(static_cast<int>(error))
                 .arg(details));
}

void AndroidRuntime::handleEmulatorFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    m_bootTimer->stop();
    setBooted(false);
    setDisplayAvailable(false);
    if (!m_stopping && (exitStatus == QProcess::CrashExit || exitCode != 0)) {
        setError(QStringLiteral("Android emulator exited with code %1.").arg(exitCode));
    } else if (!m_stopping) {
        setState(QStringLiteral("Stopped"));
    }
    emit processStopped();
}

void AndroidRuntime::handleDisplayFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    setDisplayAvailable(false);
    if (exitStatus == QProcess::CrashExit || exitCode != 0) {
        setError(QStringLiteral("Android display closed unexpectedly (exit code %1).")
                     .arg(exitCode));
    }
}

void AndroidRuntime::setState(const QString& stateValue)
{
    if (m_state == stateValue) {
        return;
    }
    m_state = stateValue;
    emit stateChanged();
}

void AndroidRuntime::setError(const QString& message)
{
    m_errorMessage = message.trimmed();
    setState(QStringLiteral("Error"));
    emit errorChanged();
    emit runtimeError(m_errorMessage);
}

void AndroidRuntime::setBooted(bool bootedValue)
{
    if (m_booted == bootedValue) {
        return;
    }
    m_booted = bootedValue;
    emit bootedChanged();
}

void AndroidRuntime::setDisplayAvailable(bool available)
{
    if (m_displayAvailable == available) {
        return;
    }
    m_displayAvailable = available;
    emit displayAvailableChanged();
}

void AndroidRuntime::clearError()
{
    if (m_errorMessage.isEmpty()) {
        return;
    }
    m_errorMessage.clear();
    emit errorChanged();
}

} // namespace Hesh
