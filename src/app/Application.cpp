#include "Application.hpp"

#include <QAction>
#include <QIcon>
#include <QMenu>
#include <QSystemTrayIcon>

namespace Hesh {

Application::Application(QObject* parent)
    : QObject(parent)
    , m_settings(QStringLiteral("Hesh"), QStringLiteral("Hesh"))
    , m_shortcutManager(&m_settings, this)
    , m_deviceManager(&m_settings, this)
{
    setupTray();
}

Application::~Application()
{
    if (m_trayIcon) {
        m_trayIcon->setContextMenu(nullptr);
        m_trayIcon->hide();
    }
}

DeviceManager* Application::deviceManager()
{
    return &m_deviceManager;
}

ShortcutManager* Application::shortcutManager()
{
    return &m_shortcutManager;
}

void Application::hideToTray()
{
    if (m_trayIcon) {
        m_trayIcon->show();
    }
    emit hideRequested();
}

void Application::requestShortcutSettings()
{
    emit shortcutSettingsRequested();
}

void Application::requestShow()
{
    emit showRequested();
}

void Application::requestNewDevice()
{
    emit newDeviceRequested();
}

void Application::setupTray()
{
    if (!QSystemTrayIcon::isSystemTrayAvailable()) {
        return;
    }

    m_trayIcon = std::make_unique<QSystemTrayIcon>(
        QIcon(QStringLiteral(":/qt/qml/Hesh/assets/icons/hesh.png")), this);
    m_trayIcon->setToolTip(QStringLiteral("Hesh"));

    m_trayMenu = std::make_unique<QMenu>();
    auto* showAction = m_trayMenu->addAction(QStringLiteral("Show Hesh"));
    connect(showAction, &QAction::triggered, this, &Application::showRequested);

    auto* settingsAction = m_trayMenu->addAction(QStringLiteral("Shortcut settings"));
    connect(settingsAction,
            &QAction::triggered,
            this,
            &Application::shortcutSettingsRequested);

    auto* reloadAction = m_trayMenu->addAction(QStringLiteral("Reload selected device"));
    connect(reloadAction, &QAction::triggered, this, [this] {
        m_deviceManager.reloadSelectedDevice(false);
    });

    m_trayMenu->addSeparator();
    auto* quitAction = m_trayMenu->addAction(QStringLiteral("Quit Hesh"));
    connect(quitAction, &QAction::triggered, this, &Application::quitRequested);
    m_trayIcon->setContextMenu(m_trayMenu.get());

    connect(m_trayIcon.get(),
            &QSystemTrayIcon::activated,
            this,
            [this](QSystemTrayIcon::ActivationReason reason) {
                if (reason == QSystemTrayIcon::Trigger
                    || reason == QSystemTrayIcon::DoubleClick) {
                    emit showRequested();
                }
            });
    m_trayIcon->show();
}

} // namespace Hesh
