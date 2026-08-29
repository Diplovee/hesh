#include <QGuiApplication>
#include <QDebug>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QUrl>

#include <cstdio>

#include <QtWebEngineQuick/QtWebEngineQuick>

#include "app/Application.hpp"
#include "devices/Device.hpp"
#include "web/WebDevice.hpp"

int main(int argc, char* argv[])
{
    // Do NOT force dark mode on web content.  `--force-dark-mode` makes
    // Chromium recolor light pages and also desaturates already-dark pages
    // (e.g. lime #A3FF12 → muted olive) which breaks color fidelity per
    // profile.  DevTools dark appearance is handled via JS in
    // DeviceFrame.qml:applyDevToolsDarkTheme(), and WebUI dark is opt-in
    // via WebEngineView background.  Preserve any user-supplied
    // QTWEBENGINE_CHROMIUM_FLAGS verbatim.
    auto chromiumFlags = qgetenv("QTWEBENGINE_CHROMIUM_FLAGS");
    // Only ensure WebUI dark is available if user wants it; do not inject
    // --force-dark-mode.  If the host OS is dark, Chromium will still
    // report prefers-color-scheme:dark via the profile without recoloring.
    // Keep flag handling explicit so future maintainers don't re-add it.
    if (!chromiumFlags.isEmpty()) {
        qputenv("QTWEBENGINE_CHROMIUM_FLAGS", chromiumFlags);
    }
    // HiDPI: use PassThrough for fractional scales (e.g. 1.25/1.5 on Hyprland)
    // so WebEngine renders at native physical resolution instead of rounded.
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(
        Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("Hesh"));
    QCoreApplication::setOrganizationName(QStringLiteral("Hesh"));
    QGuiApplication::setApplicationDisplayName(QStringLiteral("Hesh"));
    QGuiApplication::setWindowIcon(QIcon(QStringLiteral(":/qt/qml/Hesh/assets/icons/hesh.png")));

    qmlRegisterUncreatableType<Hesh::Device>("Hesh", 1, 0, "Device",
                                              QStringLiteral("Devices are created by DeviceManager"));
    qmlRegisterUncreatableType<Hesh::WebDevice>("Hesh", 1, 0, "WebDevice",
                                                 QStringLiteral("Web devices are created by DeviceManager"));

    Hesh::Application hesh;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("deviceManager"), hesh.deviceManager());

    QObject::connect(&engine,
                     &QQmlApplicationEngine::warnings,
                     &app,
                     [](const QList<QQmlError>& errors) {
                         for (const auto& error : errors) {
                             qWarning() << error;
                         }
                     });

    QObject::connect(&engine,
                     &QQmlApplicationEngine::objectCreationFailed,
                     &app,
                     [&engine] {
                         std::fprintf(stderr, "Hesh QML object creation failed.\n");
                         std::fflush(stderr);
                         qWarning() << "Hesh QML object creation failed.";
                         QCoreApplication::exit(EXIT_FAILURE);
                     },
                     Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Hesh/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        std::fprintf(stderr, "Hesh could not load its QML module.\n");
        std::fflush(stderr);
        QQmlComponent diagnostic(&engine,
                                 QUrl(QStringLiteral("qrc:/qt/qml/Hesh/qml/Main.qml")),
                                 &app);
        for (const auto& error : diagnostic.errors()) {
            qWarning() << error;
            std::fprintf(stderr, "%s\n", qPrintable(error.toString()));
        }
        qWarning() << "Hesh could not load its QML module.";
        return EXIT_FAILURE;
    }

    return app.exec();
}
