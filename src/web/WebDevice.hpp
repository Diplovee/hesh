#pragma once

#include <QStringList>
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
    Q_PROPERTY(QStringList recentUrls READ recentUrls NOTIFY recentUrlsChanged)
    Q_PROPERTY(QString fitMode READ fitMode WRITE setFitMode NOTIFY viewPreferencesChanged)
    Q_PROPERTY(double manualScale READ manualScale WRITE setManualScale NOTIFY viewPreferencesChanged)
    Q_PROPERTY(bool frameChromeVisible READ frameChromeVisible WRITE setFrameChromeVisible
               NOTIFY viewPreferencesChanged)
    Q_PROPERTY(bool devToolsVisible READ devToolsVisible WRITE setDevToolsVisible
               NOTIFY viewPreferencesChanged)
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
    QStringList recentUrls() const;
    QString fitMode() const;
    double manualScale() const;
    bool frameChromeVisible() const;
    bool devToolsVisible() const;

    Q_INVOKABLE bool navigateTo(const QString& requestedUrl);
    Q_INVOKABLE void setPendingNavigationUrl(const QString& url);
    Q_INVOKABLE void commitPendingNavigation();
    Q_INVOKABLE void discardPendingNavigation();
    Q_INVOKABLE void setRecentUrls(const QStringList& urls);
    void setFitMode(const QString& mode);
    void setManualScale(double scale);
    void setFrameChromeVisible(bool visible);
    void setDevToolsVisible(bool visible);
    Q_INVOKABLE void setLoading(bool loading);
    Q_INVOKABLE void setRuntimeLoaded();
    Q_INVOKABLE void setRuntimeError(const QString& message);
    Q_INVOKABLE void setNavigationState(bool canGoBack, bool canGoForward);
    Q_INVOKABLE void reload();
    Q_INVOKABLE void hardReload();

    QQuickWebEngineProfile* browserProfile() const;
    QString profileStoragePath() const;

    static QString normalizeUrl(const QString& input);
    static bool isValidUrl(const QString& input);

    void start() override;
    void stop() override;
    void setProfile(const DeviceProfile& profile) override;
    void setUserAgent(const QString& userAgent) override;

signals:
    void urlChanged();
    void orientationChanged();
    void viewportChanged();
    void presentationStateChanged();
    void runtimeStateChanged();
    void navigationStateChanged();
    void recentUrlsChanged();
    void viewPreferencesChanged();
    void navigationRequested(const QString& url);
    void reloadRequested(bool bypassCache);

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
    QStringList m_recentUrls;
    QString m_pendingNavigationUrl;
    QString m_fitMode = QStringLiteral("Fit");
    double m_manualScale = 1.0;
    bool m_frameChromeVisible = true;
    bool m_devToolsVisible = false;
    mutable QQuickWebEngineProfile* m_browserProfile = nullptr;

    void rememberUrl(const QString& url);
    void emitViewPreferencesChanged();
};

} // namespace Hesh
