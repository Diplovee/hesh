#pragma once

#include <QObject>

#include "Settings.hpp"
#include "devices/DeviceManager.hpp"

namespace Hesh {

class Application final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(DeviceManager* deviceManager READ deviceManager CONSTANT)

public:
    explicit Application(QObject* parent = nullptr);

    DeviceManager* deviceManager();

private:
    Settings m_settings;
    DeviceManager m_deviceManager;
};

} // namespace Hesh
