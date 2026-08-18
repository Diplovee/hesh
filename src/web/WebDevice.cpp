#include "WebDevice.hpp"

#include <QDir>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QUrl>
#include <QtWebEngineQuick/QQuickWebEngineProfile>

#include <utility>

namespace Hesh {

WebDevice::WebDevice(QString id,
                     QString name,
                     DeviceProfile profile,
                     QString url,
                     QObject* parent)
    : Device(std::move(id), std::move(name), DeviceType::Web, std::move(profile), parent)
    , m_url(isValidUrl(url) ? normalizeUrl(url) : QString {})
{
    if (!m_url.isEmpty()) {
        m_recentUrls.append(m_url);
    }
}

QString WebDevice::url() const
{
    return m_url;
}

void WebDevice::setUrl(const QString& url)
{
    const auto normalized = normalizeUrl(url);
    if (!isValidUrl(normalized) || normalized == m_url) {
        m_pendingNavigationUrl.clear();
        return;
    }
    m_url = normalized;
    m_pendingNavigationUrl.clear();
    rememberUrl(m_url);
    if (!m_errorMessage.isEmpty() || m_runtimeState == QStringLiteral("Error")) {
        m_errorMessage.clear();
        m_runtimeState = QStringLiteral("Idle");
        emit runtimeStateChanged();
        if (status() == Status::Error) {
            setStatus(Status::Running);
        }
    }
    emit urlChanged();
    emit dataChanged();
}

QString WebDevice::normalizeUrl(const QString& input)
{
    const auto trimmed = input.trimmed();
    if (trimmed.isEmpty()) {
        return {};
    }

    const auto lower = trimmed.toLower();
    if (lower.startsWith(QStringLiteral("http://"))
        || lower.startsWith(QStringLiteral("https://"))
        || lower.startsWith(QStringLiteral("about:"))
        || lower.startsWith(QStringLiteral("file:"))
        || lower.startsWith(QStringLiteral("data:"))) {
        return trimmed;
    }
    if (trimmed.startsWith(QStringLiteral("//"))) {
        return QStringLiteral("http:") + trimmed;
    }

    // QUrl treats "localhost:3000" as a scheme. Prefixing only inputs that
    // lack a known browser scheme keeps ports, queries, and hashes intact.
    return QStringLiteral("http://") + trimmed;
}

bool WebDevice::isValidUrl(const QString& input)
{
    const auto normalized = normalizeUrl(input);
    if (normalized.isEmpty()) {
        return false;
    }

    const QUrl url(normalized);
    const auto scheme = url.scheme().toLower();
    if (scheme == QStringLiteral("http") || scheme == QStringLiteral("https")) {
        return url.isValid() && !url.host().isEmpty();
    }
    if (scheme == QStringLiteral("about")) {
        return url.isValid();
    }
    if (scheme == QStringLiteral("file") || scheme == QStringLiteral("data")) {
        return url.isValid();
    }
    return false;
}

QString WebDevice::orientation() const
{
    return m_orientation == Orientation::Landscape ? QStringLiteral("Landscape")
                                                   : QStringLiteral("Portrait");
}

void WebDevice::setOrientation(const QString& requestedOrientation)
{
    const auto next = requestedOrientation.compare(QStringLiteral("landscape"), Qt::CaseInsensitive) == 0
        ? Orientation::Landscape
        : Orientation::Portrait;
    if (next == m_orientation) {
        return;
    }
    m_orientation = next;
    emit orientationChanged();
    emit viewportChanged();
    emit dataChanged();
}

int WebDevice::logicalViewportWidth() const
{
    return m_orientation == Orientation::Landscape ? profile().height : profile().width;
}

int WebDevice::logicalViewportHeight() const
{
    return m_orientation == Orientation::Landscape ? profile().width : profile().height;
}

QString WebDevice::presentationState() const
{
    return m_presentationState == PresentationState::Standalone ? QStringLiteral("Standalone")
                                                                 : QStringLiteral("Embedded");
}

bool WebDevice::isStandalone() const
{
    return m_presentationState == PresentationState::Standalone;
}

void WebDevice::setPresentationState(PresentationState state)
{
    if (state == m_presentationState) {
        return;
    }
    m_presentationState = state;
    emit presentationStateChanged();
    emit dataChanged();
}

bool WebDevice::loading() const
{
    return m_loading;
}

QString WebDevice::runtimeState() const
{
    return m_runtimeState;
}

QString WebDevice::errorMessage() const
{
    return m_errorMessage;
}

bool WebDevice::canGoBack() const
{
    return m_canGoBack;
}

bool WebDevice::canGoForward() const
{
    return m_canGoForward;
}

QStringList WebDevice::recentUrls() const
{
    return m_recentUrls;
}

QString WebDevice::fitMode() const
{
    return m_fitMode;
}

double WebDevice::manualScale() const
{
    return m_manualScale;
}

bool WebDevice::frameChromeVisible() const
{
    return m_frameChromeVisible;
}

bool WebDevice::devToolsVisible() const
{
    return m_devToolsVisible;
}

bool WebDevice::navigateTo(const QString& requestedUrl)
{
    const auto normalized = normalizeUrl(requestedUrl);
    if (!isValidUrl(normalized)) {
        return false;
    }
    m_pendingNavigationUrl = normalized;
    emit navigationRequested(normalized);
    return true;
}

void WebDevice::setPendingNavigationUrl(const QString& url)
{
    const auto normalized = normalizeUrl(url);
    if (isValidUrl(normalized) && normalized != m_url) {
        m_pendingNavigationUrl = normalized;
    }
}

void WebDevice::commitPendingNavigation()
{
    if (m_pendingNavigationUrl.isEmpty()) {
        return;
    }
    const auto pending = m_pendingNavigationUrl;
    m_pendingNavigationUrl.clear();
    setUrl(pending);
}

void WebDevice::discardPendingNavigation()
{
    m_pendingNavigationUrl.clear();
}

void WebDevice::setRecentUrls(const QStringList& urls)
{
    QStringList normalizedUrls;
    for (const auto& url : urls) {
        const auto normalized = normalizeUrl(url);
        if (!isValidUrl(normalized) || normalizedUrls.contains(normalized)) {
            continue;
        }
        normalizedUrls.append(normalized);
        if (normalizedUrls.size() >= 10) {
            break;
        }
    }
    if (!m_url.isEmpty()) {
        normalizedUrls.removeAll(m_url);
        normalizedUrls.prepend(m_url);
    }
    if (normalizedUrls == m_recentUrls) {
        return;
    }
    m_recentUrls = normalizedUrls;
    emit recentUrlsChanged();
    emit dataChanged();
}

void WebDevice::setFitMode(const QString& mode)
{
    const auto normalized = mode.compare(QStringLiteral("Manual"), Qt::CaseInsensitive) == 0
        ? QStringLiteral("Manual")
        : QStringLiteral("Fit");
    if (normalized == m_fitMode) {
        return;
    }
    m_fitMode = normalized;
    emitViewPreferencesChanged();
}

void WebDevice::setManualScale(double scale)
{
    const auto normalized = qBound(0.1, scale, 3.0);
    if (qFuzzyCompare(normalized, m_manualScale)) {
        return;
    }
    m_manualScale = normalized;
    emitViewPreferencesChanged();
}

void WebDevice::setFrameChromeVisible(bool visible)
{
    if (visible == m_frameChromeVisible) {
        return;
    }
    m_frameChromeVisible = visible;
    emitViewPreferencesChanged();
}

void WebDevice::setDevToolsVisible(bool visible)
{
    if (visible == m_devToolsVisible) {
        return;
    }
    m_devToolsVisible = visible;
    emitViewPreferencesChanged();
}

void WebDevice::setLoading(bool loadingState)
{
    if (m_loading == loadingState
        && (loadingState || m_runtimeState != QStringLiteral("Loading"))) {
        return;
    }
    m_loading = loadingState;
    if (m_loading) {
        m_runtimeState = QStringLiteral("Loading");
    } else if (m_runtimeState == QStringLiteral("Loading")) {
        m_runtimeState = QStringLiteral("Idle");
    }
    emit runtimeStateChanged();
    emit dataChanged();
}

void WebDevice::setRuntimeLoaded()
{
    commitPendingNavigation();
    const bool changed = m_loading || m_runtimeState != QStringLiteral("Loaded") || !m_errorMessage.isEmpty();
    m_loading = false;
    m_runtimeState = QStringLiteral("Loaded");
    m_errorMessage.clear();
    if (status() == Status::Error) {
        setStatus(Status::Running);
    }
    if (changed) {
        emit runtimeStateChanged();
        emit dataChanged();
    }
}

void WebDevice::setRuntimeError(const QString& message)
{
    discardPendingNavigation();
    m_loading = false;
    m_runtimeState = QStringLiteral("Error");
    m_errorMessage = message.trimmed().isEmpty() ? QStringLiteral("Navigation failed") : message.trimmed();
    emit runtimeStateChanged();
    setStatus(Status::Error);
    emit dataChanged();
}

void WebDevice::setNavigationState(bool back, bool forward)
{
    if (m_canGoBack == back && m_canGoForward == forward) {
        return;
    }
    m_canGoBack = back;
    m_canGoForward = forward;
    emit navigationStateChanged();
}

void WebDevice::reload()
{
    emit reloadRequested(false);
}

void WebDevice::hardReload()
{
    emit reloadRequested(true);
}

QString WebDevice::profileStoragePath() const
{
    return QDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation))
        .filePath(QStringLiteral("profile/%1").arg(id()));
}

QQuickWebEngineProfile* WebDevice::browserProfile() const
{
    initializeBrowserProfile();
    return m_browserProfile;
}

void WebDevice::initializeBrowserProfile() const
{
    if (m_browserProfile) {
        return;
    }

    const auto storagePath = profileStoragePath();
    const auto cachePath = QDir(storagePath).filePath(QStringLiteral("cache"));
    QDir().mkpath(storagePath);
    QDir().mkpath(cachePath);

    auto* self = const_cast<WebDevice*>(this);
    self->m_browserProfile = new QQuickWebEngineProfile(
        QStringLiteral("hesh-%1").arg(id()), self);
    self->m_browserProfile->setPersistentStoragePath(storagePath);
    self->m_browserProfile->setCachePath(cachePath);
    self->m_browserProfile->setHttpUserAgent(userAgent());
    self->m_browserProfile->setPersistentCookiesPolicy(
        QQuickWebEngineProfile::ForcePersistentCookies);
    self->m_browserProfile->setHttpCacheType(QQuickWebEngineProfile::DiskHttpCache);
}

void WebDevice::start()
{
    setStatus(Status::Starting);
    setStatus(Status::Running);
}

void WebDevice::stop()
{
    setStatus(Status::Stopped);
}

void WebDevice::setProfile(const DeviceProfile& profileValue)
{
    Device::setProfile(profileValue);
    if (m_browserProfile) {
        m_browserProfile->setHttpUserAgent(userAgent());
    }
}

void WebDevice::setUserAgent(const QString& userAgentValue)
{
    Device::setUserAgent(userAgentValue);
    if (m_browserProfile) {
        m_browserProfile->setHttpUserAgent(userAgent());
    }
}

void WebDevice::rememberUrl(const QString& url)
{
    if (!isValidUrl(url)) {
        return;
    }
    m_recentUrls.removeAll(url);
    m_recentUrls.prepend(url);
    while (m_recentUrls.size() > 10) {
        m_recentUrls.removeLast();
    }
    emit recentUrlsChanged();
}

void WebDevice::emitViewPreferencesChanged()
{
    emit viewPreferencesChanged();
    emit dataChanged();
}

} // namespace Hesh
