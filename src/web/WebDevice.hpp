#pragma once

#include "devices/Device.hpp"

namespace Hesh {

class WebDevice final : public Device
{
    Q_OBJECT
    Q_PROPERTY(QString url READ url WRITE setUrl NOTIFY urlChanged)

public:
    WebDevice(QString id,
              QString name,
              DeviceProfile profile,
              QString url,
              QObject* parent = nullptr);

    QString url() const;
    void setUrl(const QString& url);

    void start() override;
    void stop() override;

signals:
    void urlChanged();

private:
    QString m_url;
};

} // namespace Hesh
