#include <QtTest>

#include <QSignalSpy>
#include <QTemporaryDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>

#include "app/Settings.hpp"
#include "app/ShortcutManager.hpp"
#include "android/AndroidDevice.hpp"
#include "devices/DeviceManager.hpp"
#include "devices/DeviceProfile.hpp"
#include "web/WebDevice.hpp"

using namespace Hesh;

class DeviceTests final : public QObject
{
    Q_OBJECT

private slots:
    void createWebDevice();
    void removeDevice();
    void selectDevice();
    void profileAssignment();
    void persistenceRoundTrip();
    void urlNormalization();
    void orientationChangesLogicalViewport();
    void presentationLifecycle();
    void standaloneDeviceDimensions();
    void multipleStandaloneDevices();
    void profileIdentityIsPerDevice();
    void deletionWhileDetached();
    void androidDeviceConfiguration();
    void androidFeatureLock();
    void androidRecordRoundTrip();
    void shortcutDefaults();
    void shortcutPersistence();
    void shortcutConflictsAndReset();
    void webReloadRequests();
    void editAndPersistWebDevice();
    void duplicateWebDeviceIsIsolated();
    void viewPreferencesRoundTrip();
    void legacySettingsUseSafeViewDefaults();
    void invalidUrlsAreRejected();
    void failedNavigationKeepsLastValidUrl();
};

void DeviceTests::createWebDevice()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("Create"),
                      directory.filePath(QStringLiteral("settings.ini")));
    DeviceManager manager(&settings);
    auto* device = manager.createWebDevice(QStringLiteral("Preview"),
                                           QStringLiteral("Pixel 7"),
                                           QStringLiteral("http://localhost:3000"));

    QVERIFY(device != nullptr);
    QCOMPARE(manager.deviceCount(), 1);
    QCOMPARE(device->name(), QStringLiteral("Preview"));
    QCOMPARE(device->typeName(), QStringLiteral("web"));
    QCOMPARE(device->statusName(), QStringLiteral("Running"));
    QCOMPARE(manager.selectedDevice(), static_cast<Device*>(device));
}

void DeviceTests::removeDevice()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("Remove"),
                      directory.filePath(QStringLiteral("settings.ini")));
    DeviceManager manager(&settings);
    auto* first = manager.createWebDevice(QStringLiteral("First"), QStringLiteral("Pixel 7"), {});
    auto* second = manager.createWebDevice(QStringLiteral("Second"), QStringLiteral("Pixel 8"), {});
    QVERIFY(first != nullptr);
    QVERIFY(second != nullptr);

    manager.removeDevice(second->id());
    QCOMPARE(manager.deviceCount(), 1);
    QCOMPARE(manager.selectedDevice(), static_cast<Device*>(first));
}

void DeviceTests::selectDevice()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("Select"),
                      directory.filePath(QStringLiteral("settings.ini")));
    DeviceManager manager(&settings);
    auto* first = manager.createWebDevice(QStringLiteral("First"), QStringLiteral("Pixel 7"), {});
    auto* second = manager.createWebDevice(QStringLiteral("Second"), QStringLiteral("iPhone 14"), {});

    manager.selectDevice(first->id());
    QCOMPARE(manager.selectedDevice(), static_cast<Device*>(first));
    manager.selectDevice(second->id());
    QCOMPARE(manager.selectedDevice(), static_cast<Device*>(second));
}

void DeviceTests::profileAssignment()
{
    const auto profile = DeviceProfile::fromName(QStringLiteral("Pixel 8"));
    QCOMPARE(profile.name, QStringLiteral("Pixel 8"));
    QCOMPARE(profile.width, 412);
    QCOMPARE(profile.height, 915);
    QCOMPARE(profile.devicePixelRatio, 2.75);

    WebDevice device(QStringLiteral("profile-test"),
                     QStringLiteral("Profile test"),
                     profile,
                     QStringLiteral("http://localhost:3000"));
    QCOMPARE(device.profileName(), QStringLiteral("Pixel 8"));
    QCOMPARE(device.viewportWidth(), 412);
    QCOMPARE(device.viewportHeight(), 915);
    QCOMPARE(device.devicePixelRatio(), 2.75);
}

void DeviceTests::persistenceRoundTrip()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const auto settingsPath = directory.filePath(QStringLiteral("settings.ini"));

    {
        Settings settings(QStringLiteral("HeshTests"), QStringLiteral("Persistence"), settingsPath);
        DeviceManager manager(&settings);
        auto* persisted = manager.createWebDevice(QStringLiteral("Persisted"),
                                                  QStringLiteral("Galaxy S24"),
                                                  QStringLiteral("http://localhost:4173"));
        persisted->setOrientation(QStringLiteral("Landscape"));
    }

    Settings reloadedSettings(QStringLiteral("HeshTests"), QStringLiteral("Persistence"), settingsPath);
    DeviceManager reloaded(&reloadedSettings);
    QCOMPARE(reloaded.deviceCount(), 1);
    QVERIFY(reloaded.selectedDevice() != nullptr);
    QCOMPARE(reloaded.selectedDevice()->name(), QStringLiteral("Persisted"));
    QCOMPARE(reloaded.selectedDevice()->profileName(), QStringLiteral("Galaxy S24"));
    const auto* webDevice = qobject_cast<const WebDevice*>(reloaded.selectedDevice());
    QVERIFY(webDevice != nullptr);
    QCOMPARE(webDevice->url(), QStringLiteral("http://localhost:4173"));
    QCOMPARE(webDevice->orientation(), QStringLiteral("Landscape"));
    QCOMPARE(webDevice->logicalViewportWidth(), 780);
    QCOMPARE(webDevice->logicalViewportHeight(), 360);
}

void DeviceTests::urlNormalization()
{
    QCOMPARE(WebDevice::normalizeUrl(QStringLiteral("localhost:3000")),
             QStringLiteral("http://localhost:3000"));
    QCOMPARE(WebDevice::normalizeUrl(QStringLiteral("localhost:5173/app?tab=preview#mobile")),
             QStringLiteral("http://localhost:5173/app?tab=preview#mobile"));
    QCOMPARE(WebDevice::normalizeUrl(QStringLiteral("127.0.0.1:3000")),
             QStringLiteral("http://127.0.0.1:3000"));
    QCOMPARE(WebDevice::normalizeUrl(QStringLiteral("http://localhost:3000/?x=1#preview")),
             QStringLiteral("http://localhost:3000/?x=1#preview"));
    QCOMPARE(WebDevice::normalizeUrl(QStringLiteral("https://example.com/path?q=1#section")),
             QStringLiteral("https://example.com/path?q=1#section"));
}

void DeviceTests::orientationChangesLogicalViewport()
{
    WebDevice device(QStringLiteral("orientation-test"),
                     QStringLiteral("Orientation test"),
                     DeviceProfile::fromName(QStringLiteral("Pixel 7")),
                     {});

    QCOMPARE(device.orientation(), QStringLiteral("Portrait"));
    QCOMPARE(device.logicalViewportWidth(), 412);
    QCOMPARE(device.logicalViewportHeight(), 915);

    device.setOrientation(QStringLiteral("Landscape"));
    QCOMPARE(device.orientation(), QStringLiteral("Landscape"));
    QCOMPARE(device.logicalViewportWidth(), 915);
    QCOMPARE(device.logicalViewportHeight(), 412);

    device.setOrientation(QStringLiteral("Portrait"));
    QCOMPARE(device.logicalViewportWidth(), 412);
    QCOMPARE(device.logicalViewportHeight(), 915);
}

void DeviceTests::presentationLifecycle()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("Presentation"),
                      directory.filePath(QStringLiteral("settings.ini")));
    DeviceManager manager(&settings);
    auto* device = manager.createWebDevice(QStringLiteral("Detached"),
                                           QStringLiteral("Pixel 7"),
                                           {});
    QVERIFY(device != nullptr);
    QCOMPARE(device->presentationState(), QStringLiteral("Embedded"));

    QVERIFY(manager.openStandalone(device->id()));
    QCOMPARE(device->presentationState(), QStringLiteral("Standalone"));
    QVERIFY(!manager.openStandalone(device->id()));

    manager.returnToEmbedded(device->id());
    QCOMPARE(device->presentationState(), QStringLiteral("Embedded"));
    manager.returnToEmbedded(device->id());
    QCOMPARE(device->presentationState(), QStringLiteral("Embedded"));
}

void DeviceTests::standaloneDeviceDimensions()
{
    WebDevice pixel(QStringLiteral("pixel-window"),
                    QStringLiteral("Pixel window"),
                    DeviceProfile::fromName(QStringLiteral("Pixel 7")),
                    {});

    // Standalone windows expose only the logical viewport; the embedded host
    // may add presentation chrome around the same device.
    QCOMPARE(pixel.logicalViewportWidth(), 412);
    QCOMPARE(pixel.logicalViewportHeight(), 915);

    pixel.setOrientation(QStringLiteral("Landscape"));
    QCOMPARE(pixel.logicalViewportWidth(), 915);
    QCOMPARE(pixel.logicalViewportHeight(), 412);
}

void DeviceTests::multipleStandaloneDevices()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("MultiplePresentation"),
                      directory.filePath(QStringLiteral("settings.ini")));
    DeviceManager manager(&settings);
    auto* pixel = manager.createWebDevice(QStringLiteral("Pixel"), QStringLiteral("Pixel 7"), {});
    auto* iphone = manager.createWebDevice(QStringLiteral("iPhone"), QStringLiteral("iPhone 14"), {});
    QVERIFY(pixel != nullptr);
    QVERIFY(iphone != nullptr);

    QVERIFY(manager.openStandalone(pixel->id()));
    QVERIFY(manager.openStandalone(iphone->id()));
    QVERIFY(manager.isStandalone(pixel->id()));
    QVERIFY(manager.isStandalone(iphone->id()));
    QVERIFY(!manager.openStandalone(pixel->id()));

    manager.returnToEmbedded(pixel->id());
    QVERIFY(!manager.isStandalone(pixel->id()));
    QVERIFY(manager.isStandalone(iphone->id()));
    manager.returnToEmbedded(iphone->id());
}

void DeviceTests::profileIdentityIsPerDevice()
{
    WebDevice first(QStringLiteral("profile-a"),
                    QStringLiteral("First"),
                    DeviceProfile::fromName(QStringLiteral("Pixel 7")),
                    {});
    WebDevice second(QStringLiteral("profile-b"),
                     QStringLiteral("Second"),
                     DeviceProfile::fromName(QStringLiteral("Pixel 7")),
                     {});

    QVERIFY(first.profileStoragePath().contains(QStringLiteral("profile-a")));
    QVERIFY(second.profileStoragePath().contains(QStringLiteral("profile-b")));
    QVERIFY(first.profileStoragePath() != second.profileStoragePath());
}

void DeviceTests::deletionWhileDetached()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("DetachedRemoval"),
                      directory.filePath(QStringLiteral("settings.ini")));
    DeviceManager manager(&settings);
    auto* device = manager.createWebDevice(QStringLiteral("Remove me"),
                                           QStringLiteral("Pixel 7"),
                                           {});
    QVERIFY(device != nullptr);
    QVERIFY(manager.openStandalone(device->id()));
    const auto id = device->id();

    manager.removeDevice(id);
    QCOMPARE(manager.deviceCount(), 0);
    QVERIFY(!manager.isStandalone(id));
}

void DeviceTests::androidDeviceConfiguration()
{
    AndroidDevice device(QStringLiteral("android-test"),
                         QStringLiteral("Android test"),
                         DeviceProfile::fromName(QStringLiteral("Pixel 7")),
                         QStringLiteral("Pixel_7_API_35"),
                         QStringLiteral("emulator-5556"));

    QCOMPARE(device.typeName(), QStringLiteral("android"));
    QCOMPARE(device.typeLabel(), QStringLiteral("ANDROID"));
    QCOMPARE(device.avdName(), QStringLiteral("Pixel_7_API_35"));
    QCOMPARE(device.adbSerial(), QStringLiteral("emulator-5556"));
    QCOMPARE(device.runtimeState(), QStringLiteral("Stopped"));
    QVERIFY(!device.booted());
    QVERIFY(!device.displayAvailable());
}

void DeviceTests::androidFeatureLock()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("AndroidLock"),
                      directory.filePath(QStringLiteral("settings.ini")));
    DeviceManager manager(&settings);
    QVERIFY(!manager.androidFeatureEnabled());
    QVERIFY(manager.createAndroidDevice(QStringLiteral("Locked Android"),
                                        QStringLiteral("Pixel 7"),
                                        QStringLiteral("Pixel_7_API_35"),
                                        QStringLiteral("emulator-5554"))
            == nullptr);

    AndroidDevice device(QStringLiteral("android-lock-test"),
                         QStringLiteral("Locked Android"),
                         DeviceProfile::fromName(QStringLiteral("Pixel 7")),
                         QStringLiteral("Pixel_7_API_35"),
                         QStringLiteral("emulator-5554"));
    QVERIFY(device.featureLocked());
    device.start();
    QCOMPARE(device.statusName(), QStringLiteral("Stopped"));
    QVERIFY(!device.openDisplay());
    QVERIFY(!device.sendHome());
    QVERIFY(!device.installApk(QStringLiteral("/tmp/example.apk")));
}

void DeviceTests::androidRecordRoundTrip()
{
    DeviceRecord original;
    original.id = QStringLiteral("android-record");
    original.name = QStringLiteral("Persisted Android");
    original.type = QStringLiteral("android");
    original.profileName = QStringLiteral("Pixel 8");
    original.avdName = QStringLiteral("Pixel_8_API_35");
    original.adbSerial = QStringLiteral("emulator-5558");

    const auto parsed = deviceRecordFromJson(deviceRecordToJson(original));
    QVERIFY(parsed.has_value());
    QCOMPARE(parsed->type, original.type);
    QCOMPARE(parsed->profileName, original.profileName);
    QCOMPARE(parsed->avdName, original.avdName);
    QCOMPARE(parsed->adbSerial, original.adbSerial);
}

void DeviceTests::shortcutDefaults()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("ShortcutDefaults"),
                      directory.filePath(QStringLiteral("settings.ini")));
    ShortcutManager shortcuts(&settings);

    QCOMPARE(shortcuts.shortcutFor(QStringLiteral("device.reload")), QStringLiteral("Ctrl+R"));
    QCOMPARE(shortcuts.shortcutFor(QStringLiteral("device.hardReload")),
             QStringLiteral("Ctrl+Shift+R"));
    QCOMPARE(shortcuts.shortcutFor(QStringLiteral("window.hide")), QStringLiteral("Ctrl+Shift+H"));
    QCOMPARE(shortcuts.shortcutFor(QStringLiteral("window.show")), QString {});
    QVERIFY(shortcuts.hasAction(QStringLiteral("web.devTools")));
    QVERIFY(shortcuts.rowCount() >= 20);
}

void DeviceTests::shortcutPersistence()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const auto settingsPath = directory.filePath(QStringLiteral("settings.ini"));

    {
        Settings settings(QStringLiteral("HeshTests"), QStringLiteral("ShortcutPersistence"),
                          settingsPath);
        ShortcutManager shortcuts(&settings);
        QVERIFY(shortcuts.setShortcut(QStringLiteral("device.reload"), QStringLiteral("Alt+R")));
        QCOMPARE(shortcuts.shortcutFor(QStringLiteral("device.reload")), QStringLiteral("Alt+R"));
    }

    Settings reloadedSettings(QStringLiteral("HeshTests"), QStringLiteral("ShortcutPersistence"),
                               settingsPath);
    ShortcutManager reloaded(&reloadedSettings);
    QCOMPARE(reloaded.shortcutFor(QStringLiteral("device.reload")), QStringLiteral("Alt+R"));
    QCOMPARE(reloaded.shortcutFor(QStringLiteral("device.hardReload")),
             QStringLiteral("Ctrl+Shift+R"));
}

void DeviceTests::shortcutConflictsAndReset()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("ShortcutConflicts"),
                      directory.filePath(QStringLiteral("settings.ini")));
    ShortcutManager shortcuts(&settings);
    QVERIFY(!shortcuts.setShortcut(QStringLiteral("device.reload"), QStringLiteral("Ctrl+Shift+R")));
    QVERIFY(!shortcuts.errorMessage().isEmpty());
    QCOMPARE(shortcuts.shortcutFor(QStringLiteral("device.reload")), QStringLiteral("Ctrl+R"));

    QVERIFY(shortcuts.setShortcut(QStringLiteral("device.reload"), QStringLiteral("Alt+R")));
    QVERIFY(shortcuts.resetShortcut(QStringLiteral("device.reload")));
    QCOMPARE(shortcuts.shortcutFor(QStringLiteral("device.reload")), QStringLiteral("Ctrl+R"));

    QVERIFY(shortcuts.setShortcut(QStringLiteral("device.reload"), QStringLiteral("Alt+R")));
    shortcuts.resetAllShortcuts();
    QCOMPARE(shortcuts.shortcutFor(QStringLiteral("device.reload")), QStringLiteral("Ctrl+R"));
    QVERIFY(shortcuts.errorMessage().isEmpty());
}

void DeviceTests::webReloadRequests()
{
    WebDevice device(QStringLiteral("reload-test"),
                     QStringLiteral("Reload test"),
                     DeviceProfile::fromName(QStringLiteral("Pixel 7")),
                     QStringLiteral("http://localhost:3000"));
    QSignalSpy spy(&device, &WebDevice::reloadRequested);

    device.reload();
    QCOMPARE(spy.count(), 1);
    QCOMPARE(spy.at(0).at(0).toBool(), false);

    device.hardReload();
    QCOMPARE(spy.count(), 2);
    QCOMPARE(spy.at(1).at(0).toBool(), true);
}

void DeviceTests::editAndPersistWebDevice()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const auto settingsPath = directory.filePath(QStringLiteral("settings.ini"));

    {
        Settings settings(QStringLiteral("HeshTests"), QStringLiteral("Edit"), settingsPath);
        DeviceManager manager(&settings);
        auto* device = manager.createWebDevice(QStringLiteral("Before"), QStringLiteral("Pixel 7"),
                                               QStringLiteral("http://localhost:3000"));
        QVERIFY(manager.editWebDevice(device->id(),
                                      QStringLiteral("After"),
                                      QStringLiteral("Galaxy S24"),
                                      QStringLiteral("localhost:4173/app"),
                                      QStringLiteral("Landscape"),
                                      QStringLiteral("HeshTest/1.0")));
        QCOMPARE(device->name(), QStringLiteral("After"));
        QCOMPARE(device->profileName(), QStringLiteral("Galaxy S24"));
        QCOMPARE(device->url(), QStringLiteral("http://localhost:4173/app"));
        QCOMPARE(device->orientation(), QStringLiteral("Landscape"));
        QCOMPARE(device->userAgent(), QStringLiteral("HeshTest/1.0"));
    }

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("Edit"), settingsPath);
    DeviceManager reloaded(&settings);
    const auto* device = qobject_cast<const WebDevice*>(reloaded.selectedDevice());
    QVERIFY(device != nullptr);
    QCOMPARE(device->name(), QStringLiteral("After"));
    QCOMPARE(device->profileName(), QStringLiteral("Galaxy S24"));
    QCOMPARE(device->url(), QStringLiteral("http://localhost:4173/app"));
    QCOMPARE(device->orientation(), QStringLiteral("Landscape"));
    QCOMPARE(device->userAgent(), QStringLiteral("HeshTest/1.0"));
}

void DeviceTests::duplicateWebDeviceIsIsolated()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("Duplicate"),
                      directory.filePath(QStringLiteral("settings.ini")));
    DeviceManager manager(&settings);
    auto* source = manager.createWebDevice(QStringLiteral("Source"), QStringLiteral("Pixel 8"),
                                           QStringLiteral("http://localhost:3000"));
    source->setUserAgent(QStringLiteral("HeshSource/1.0"));
    source->setOrientation(QStringLiteral("Landscape"));
    source->setFitMode(QStringLiteral("Manual"));
    source->setManualScale(0.75);

    auto* duplicate = manager.duplicateWebDevice(source->id(), QStringLiteral("Copy"));
    QVERIFY(duplicate != nullptr);
    QVERIFY(duplicate->id() != source->id());
    QCOMPARE(duplicate->name(), QStringLiteral("Copy"));
    QCOMPARE(duplicate->profileName(), source->profileName());
    QCOMPARE(duplicate->url(), source->url());
    QCOMPARE(duplicate->orientation(), source->orientation());
    QCOMPARE(duplicate->userAgent(), source->userAgent());
    QCOMPARE(duplicate->fitMode(), source->fitMode());
    QCOMPARE(duplicate->manualScale(), source->manualScale());
    QVERIFY(duplicate->profileStoragePath() != source->profileStoragePath());
}

void DeviceTests::viewPreferencesRoundTrip()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const auto settingsPath = directory.filePath(QStringLiteral("settings.ini"));

    {
        Settings settings(QStringLiteral("HeshTests"), QStringLiteral("ViewPreferences"), settingsPath);
        DeviceManager manager(&settings);
        auto* device = manager.createWebDevice(QStringLiteral("Preview"), QStringLiteral("Pixel 7"),
                                               QStringLiteral("http://localhost:3000"));
        device->setFitMode(QStringLiteral("Manual"));
        device->setManualScale(1.25);
        device->setFrameChromeVisible(false);
        device->setDevToolsVisible(true);
        device->setRecentUrls({QStringLiteral("https://example.com"),
                               QStringLiteral("http://localhost:3000")});
    }

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("ViewPreferences"), settingsPath);
    DeviceManager reloaded(&settings);
    const auto* device = qobject_cast<const WebDevice*>(reloaded.selectedDevice());
    QVERIFY(device != nullptr);
    QCOMPARE(device->fitMode(), QStringLiteral("Manual"));
    QCOMPARE(device->manualScale(), 1.25);
    QVERIFY(!device->frameChromeVisible());
    QVERIFY(device->devToolsVisible());
    QCOMPARE(device->recentUrls().first(), QStringLiteral("http://localhost:3000"));
    QVERIFY(device->recentUrls().contains(QStringLiteral("https://example.com")));
}

void DeviceTests::legacySettingsUseSafeViewDefaults()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const auto settingsPath = directory.filePath(QStringLiteral("settings.ini"));

    QJsonObject legacy {
        {QStringLiteral("id"), QStringLiteral("legacy")},
        {QStringLiteral("name"), QStringLiteral("Legacy")},
        {QStringLiteral("type"), QStringLiteral("web")},
        {QStringLiteral("profile"), QStringLiteral("Pixel 7")},
        {QStringLiteral("url"), QStringLiteral("http://localhost:3000")},
    };
    QSettings raw(settingsPath, QSettings::IniFormat);
    raw.setValue(QStringLiteral("devices"),
                 QJsonDocument(QJsonArray {legacy}).toJson(QJsonDocument::Compact));
    raw.sync();

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("Legacy"), settingsPath);
    DeviceManager manager(&settings);
    const auto* device = qobject_cast<const WebDevice*>(manager.selectedDevice());
    QVERIFY(device != nullptr);
    QCOMPARE(device->fitMode(), QStringLiteral("Fit"));
    QCOMPARE(device->manualScale(), 1.0);
    QVERIFY(device->frameChromeVisible());
    QVERIFY(!device->devToolsVisible());
}

void DeviceTests::invalidUrlsAreRejected()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("InvalidUrls"),
                      directory.filePath(QStringLiteral("settings.ini")));
    DeviceManager manager(&settings);
    QVERIFY(manager.createWebDevice(QStringLiteral("Invalid"), QStringLiteral("Pixel 7"),
                                    QStringLiteral("not a url"))
            == nullptr);
    auto* device = manager.createWebDevice(QStringLiteral("Valid"), QStringLiteral("Pixel 7"), {});
    QVERIFY(device != nullptr);
    QVERIFY(!manager.editWebDevice(device->id(), QStringLiteral("Valid"), QStringLiteral("Pixel 7"),
                                   QStringLiteral(" "), QStringLiteral("Portrait"), {}));
    QVERIFY(!WebDevice::isValidUrl(QString {}));
    QVERIFY(!WebDevice::isValidUrl(QStringLiteral("http://")));
}

void DeviceTests::failedNavigationKeepsLastValidUrl()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const auto settingsPath = directory.filePath(QStringLiteral("settings.ini"));

    {
        Settings settings(QStringLiteral("HeshTests"), QStringLiteral("Navigation"), settingsPath);
        DeviceManager manager(&settings);
        auto* device = manager.createWebDevice(QStringLiteral("Navigation"), QStringLiteral("Pixel 7"),
                                               QStringLiteral("http://localhost:3000"));
        QVERIFY(device->navigateTo(QStringLiteral("https://example.com/next")));
        device->discardPendingNavigation();
        QCOMPARE(device->url(), QStringLiteral("http://localhost:3000"));
        QVERIFY(device->navigateTo(QStringLiteral("https://example.com/next")));
        device->commitPendingNavigation();
        QCOMPARE(device->url(), QStringLiteral("https://example.com/next"));
        device->setRuntimeError(QStringLiteral("Connection refused"));
        QCOMPARE(device->statusName(), QStringLiteral("Error"));
        QCOMPARE(device->url(), QStringLiteral("https://example.com/next"));
    }

    Settings settings(QStringLiteral("HeshTests"), QStringLiteral("Navigation"), settingsPath);
    DeviceManager reloaded(&settings);
    QVERIFY(reloaded.selectedDevice() != nullptr);
    QCOMPARE(qobject_cast<const WebDevice*>(reloaded.selectedDevice())->url(),
             QStringLiteral("https://example.com/next"));
}

QTEST_MAIN(DeviceTests)

#include "device_tests.moc"
