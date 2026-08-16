#pragma once

#include <QtWebEngineQuick/QQuickWebEngineProfile>

#include "devices/Device.hpp"

namespace Hesh {

class WebDevice final : public Device
{
    Q_OBJECT
    Q_PROPERTY(QString url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(QString orientation READ orientation WRITE setOrientation NOTIFY orientationChanged)
    Q_PROPERTY(int logicalViewportWidth READ logicalViewportWidth NOTIFY viewportChanged)
    Q_PROPERTY(int logicalViewportHeight READ logicalViewportHeight NOTIFY viewportChanged)
    Q_PROPERTY(QString presentationState READ presentationState NOTIFY presentationStateChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY runtimeStateChanged)
    Q_PROPERTY(QString runtimeState READ runtimeState NOTIFY runtimeStateChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY runtimeStateChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY navigationStateChanged)
    Q_PROPERTY(bool canGoForward READ canGoForward NOTIFY navigationStateChanged)
    Q_PROPERTY(QQuickWebEngineProfile* browserProfile READ browserProfile CONSTANT)
    Q_PROPERTY(QString profileStoragePath READ profileStoragePath CONSTANT)

public:
    enum class Orientation {
        Portrait,
        Landscape,
    };
    Q_ENUM(Orientation)

    enum class PresentationState {
        Embedded,
        Standalone,
    };
    Q_ENUM(PresentationState)

    WebDevice(QString id,
              QString name,
              DeviceProfile profile,
              QString url,
              QObject* parent = nullptr);

    QString url() const;
    void setUrl(const QString& url);

    QString orientation() const;
    void setOrientation(const QString& orientation);
    int logicalViewportWidth() const;
    int logicalViewportHeight() const;

    QString presentationState() const;
    bool isStandalone() const;
    void setPresentationState(PresentationState state);

    bool loading() const;
    QString runtimeState() const;
    QString errorMessage() const;
    bool canGoBack() const;
    bool canGoForward() const;
    Q_INVOKABLE void setLoading(bool loading);
    Q_INVOKABLE void setRuntimeLoaded();
    Q_INVOKABLE void setRuntimeError(const QString& message);
    Q_INVOKABLE void setNavigationState(bool canGoBack, bool canGoForward);

    QQuickWebEngineProfile* browserProfile() const;
    QString profileStoragePath() const;

    static QString normalizeUrl(const QString& input);

    void start() override;
    void stop() override;
    void setProfile(const DeviceProfile& profile) override;

signals:
    void urlChanged();
    void orientationChanged();
    void viewportChanged();
    void presentationStateChanged();
    void runtimeStateChanged();
    void navigationStateChanged();

private:
    void initializeBrowserProfile() const;

    QString m_url;
    Orientation m_orientation = Orientation::Portrait;
    PresentationState m_presentationState = PresentationState::Embedded;
    bool m_loading = false;
    QString m_runtimeState = QStringLiteral("Idle");
    QString m_errorMessage;
    bool m_canGoBack = false;
    bool m_canGoForward = false;
    mutable QQuickWebEngineProfile* m_browserProfile = nullptr;
};

} // namespace Hesh
