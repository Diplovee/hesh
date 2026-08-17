#pragma once

#include <QObject>
#include <memory>

#include "Settings.hpp"
#include "ShortcutManager.hpp"
#include "devices/DeviceManager.hpp"

class QMenu;
class QSystemTrayIcon;

namespace Hesh {

class Application final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(DeviceManager* deviceManager READ deviceManager CONSTANT)
    Q_PROPERTY(ShortcutManager* shortcutManager READ shortcutManager CONSTANT)

public:
    explicit Application(QObject* parent = nullptr);
    ~Application() override;

    DeviceManager* deviceManager();
    ShortcutManager* shortcutManager();

    Q_INVOKABLE void hideToTray();
    Q_INVOKABLE void requestShow();
    Q_INVOKABLE void requestShortcutSettings();
    Q_INVOKABLE void requestNewDevice();

signals:
    void hideRequested();
    void showRequested();
    void shortcutSettingsRequested();
    void newDeviceRequested();
    void quitRequested();

private:
    void setupTray();

    Settings m_settings;
    ShortcutManager m_shortcutManager;
    DeviceManager m_deviceManager;
    std::unique_ptr<QSystemTrayIcon> m_trayIcon;
    std::unique_ptr<QMenu> m_trayMenu;
};

} // namespace Hesh
