#pragma once

#include <QObject>
#include <QProcess>
#include <QString>

class QTimer;

namespace Hesh {

class AndroidRuntime final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString avdName READ avdName CONSTANT)
    Q_PROPERTY(QString serial READ serial CONSTANT)
    Q_PROPERTY(QString state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorChanged)
    Q_PROPERTY(bool booted READ booted NOTIFY bootedChanged)
    Q_PROPERTY(bool displayAvailable READ displayAvailable NOTIFY displayAvailableChanged)
    Q_PROPERTY(bool scrcpyAvailable READ scrcpyAvailable CONSTANT)

public:
    explicit AndroidRuntime(QString avdName,
                            QString serial,
                            QObject* parent = nullptr);
    ~AndroidRuntime() override;

    QString avdName() const;
    QString serial() const;
    QString state() const;
    QString errorMessage() const;
    bool booted() const;
    bool displayAvailable() const;
    bool scrcpyAvailable() const;

    Q_INVOKABLE bool start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE bool openDisplay();
    Q_INVOKABLE bool sendKeyEvent(int keyCode);
    Q_INVOKABLE bool rotate();
    Q_INVOKABLE bool installApk(const QString& apkPath);

    static QString findAdb();
    static QString findEmulator();
    static QString findScrcpy();
    static QStringList availableAvds();

signals:
    void stateChanged();
    void errorChanged();
    void bootedChanged();
    void displayAvailableChanged();
    void processStarted();
    void processStopped();
    void runtimeError(const QString& message);

private slots:
    void pollBootState();
    void handleEmulatorStarted();
    void handleEmulatorError(QProcess::ProcessError error);
    void handleEmulatorFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void handleDisplayFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
    static QString findSdkTool(const QString& relativePath, const QString& executableName);
    static QString runCommand(const QString& program,
                              const QStringList& arguments,
                              int timeoutMs,
                              int* exitCode = nullptr);

    bool runAdb(const QStringList& arguments, QString* output = nullptr) const;
    void setState(const QString& state);
    void setError(const QString& message);
    void setBooted(bool booted);
    void setDisplayAvailable(bool available);
    void clearError();

    QString m_avdName;
    QString m_serial;
    QString m_state = QStringLiteral("Stopped");
    QString m_errorMessage;
    bool m_booted = false;
    bool m_displayAvailable = false;
    bool m_stopping = false;
    QProcess* m_emulatorProcess = nullptr;
    QProcess* m_displayProcess = nullptr;
    QTimer* m_bootTimer = nullptr;
};

} // namespace Hesh
