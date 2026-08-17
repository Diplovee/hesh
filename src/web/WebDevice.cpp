#include "WebDevice.hpp"

#include <QDir>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QtWebEngineQuick/QQuickWebEngineProfile>

#include <utility>

namespace Hesh {

WebDevice::WebDevice(QString id,
                     QString name,
                     DeviceProfile profile,
                     QString url,
                     QObject* parent)
    : Device(std::move(id), std::move(name), DeviceType::Web, std::move(profile), parent)
    , m_url(normalizeUrl(url))
{
}

QString WebDevice::url() const
{
    return m_url;
}

void WebDevice::setUrl(const QString& url)
{
    const auto normalized = normalizeUrl(url);
    if (normalized == m_url) {
        return;
    }
    m_url = normalized;
    if (!m_errorMessage.isEmpty() || m_runtimeState == QStringLiteral("Error")) {
        m_errorMessage.clear();
        m_runtimeState = QStringLiteral("Idle");
        emit runtimeStateChanged();
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
}

void WebDevice::setRuntimeLoaded()
{
    const bool changed = m_loading || m_runtimeState != QStringLiteral("Loaded") || !m_errorMessage.isEmpty();
    m_loading = false;
    m_runtimeState = QStringLiteral("Loaded");
    m_errorMessage.clear();
    if (changed) {
        emit runtimeStateChanged();
    }
}

void WebDevice::setRuntimeError(const QString& message)
{
    m_loading = false;
    m_runtimeState = QStringLiteral("Error");
    m_errorMessage = message.trimmed();
    emit runtimeStateChanged();
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

} // namespace Hesh
