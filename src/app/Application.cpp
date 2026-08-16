#include "Application.hpp"

namespace Hesh {

Application::Application(QObject* parent)
    : QObject(parent)
    , m_settings(QStringLiteral("Hesh"), QStringLiteral("Hesh"))
    , m_deviceManager(&m_settings, this)
{
}

DeviceManager* Application::deviceManager()
{
    return &m_deviceManager;
}

} // namespace Hesh
