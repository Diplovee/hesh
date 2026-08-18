#pragma once

#include <QObject>
#include <QString>

#include "DeviceProfile.hpp"

namespace Hesh {

class Device : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString type READ typeName CONSTANT)
    Q_PROPERTY(QString typeLabel READ typeLabel CONSTANT)
    Q_PROPERTY(QString status READ statusName NOTIFY statusChanged)
    Q_PROPERTY(QString profileName READ profileName NOTIFY profileChanged)
    Q_PROPERTY(int viewportWidth READ viewportWidth NOTIFY profileChanged)
    Q_PROPERTY(int viewportHeight READ viewportHeight NOTIFY profileChanged)
    Q_PROPERTY(double devicePixelRatio READ devicePixelRatio NOTIFY profileChanged)
    Q_PROPERTY(QString userAgent READ userAgent WRITE setUserAgent NOTIFY profileChanged)

public:
    enum class Status {
        Stopped,
        Starting,
        Running,
        Paused,
        Error,
    };
    Q_ENUM(Status)

    Device(QString id,
           QString name,
           DeviceType type,
           DeviceProfile profile,
           QObject* parent = nullptr);
    ~Device() override;

    QString id() const;
    QString name() const;
    void setName(const QString& name);

    DeviceType deviceType() const;
    QString typeName() const;
    QString typeLabel() const;

    Status status() const;
    QString statusName() const;
    void setStatus(Status status);

    const DeviceProfile& profile() const;
    QString profileName() const;
    int viewportWidth() const;
    int viewportHeight() const;
    double devicePixelRatio() const;
    virtual QString userAgent() const;
    virtual void setUserAgent(const QString& userAgent);
    virtual void setProfile(const DeviceProfile& profile);

    virtual void start();
    virtual void stop();

signals:
    void nameChanged();
    void statusChanged();
    void profileChanged();
    void dataChanged();

private:
    QString m_id;
    QString m_name;
    DeviceType m_type;
    DeviceProfile m_profile;
    Status m_status = Status::Stopped;
};

} // namespace Hesh
