#include "ShortcutManager.hpp"

#include <QKeyCombination>

#include "Settings.hpp"

namespace Hesh {

QVector<ShortcutManager::Definition> ShortcutManager::definitions()
{
    return {
        {QStringLiteral("window.hide"), QStringLiteral("Hide Hesh to tray"), QStringLiteral("Window"), QStringLiteral("Ctrl+Shift+H")},
        {QStringLiteral("window.show"), QStringLiteral("Show Hesh"), QStringLiteral("Window"), {}},
        {QStringLiteral("window.minimize"), QStringLiteral("Minimize window"), QStringLiteral("Window"), QStringLiteral("Ctrl+M")},
        {QStringLiteral("window.maximize"), QStringLiteral("Maximize / restore window"), QStringLiteral("Window"), QStringLiteral("Ctrl+Shift+M")},
        {QStringLiteral("window.close"), QStringLiteral("Close window"), QStringLiteral("Window"), QStringLiteral("Ctrl+W")},
        {QStringLiteral("app.quit"), QStringLiteral("Quit Hesh"), QStringLiteral("Window"), QStringLiteral("Ctrl+Q")},
        {QStringLiteral("device.new"), QStringLiteral("New device"), QStringLiteral("Navigation"), QStringLiteral("Ctrl+N")},
        {QStringLiteral("device.settings"), QStringLiteral("Open shortcut settings"), QStringLiteral("Navigation"), QStringLiteral("Ctrl+,")},
        {QStringLiteral("device.selectNext"), QStringLiteral("Select next device"), QStringLiteral("Navigation"), QStringLiteral("Ctrl+Alt+Down")},
        {QStringLiteral("device.selectPrevious"), QStringLiteral("Select previous device"), QStringLiteral("Navigation"), QStringLiteral("Ctrl+Alt+Up")},
        {QStringLiteral("device.start"), QStringLiteral("Start selected device"), QStringLiteral("Device lifecycle"), QStringLiteral("Ctrl+Enter")},
        {QStringLiteral("device.stop"), QStringLiteral("Stop selected device"), QStringLiteral("Device lifecycle"), QStringLiteral("Ctrl+Shift+Enter")},
        {QStringLiteral("device.reload"), QStringLiteral("Reload focused device"), QStringLiteral("Device lifecycle"), QStringLiteral("Ctrl+R")},
        {QStringLiteral("device.hardReload"), QStringLiteral("Hard reload focused device"), QStringLiteral("Device lifecycle"), QStringLiteral("Ctrl+Shift+R")},
        {QStringLiteral("device.rotate"), QStringLiteral("Rotate device"), QStringLiteral("Device controls"), QStringLiteral("Ctrl+Shift+O")},
        {QStringLiteral("device.openStandalone"), QStringLiteral("Open / return standalone window"), QStringLiteral("Device controls"), QStringLiteral("Ctrl+Shift+W")},
        {QStringLiteral("web.back"), QStringLiteral("Go back"), QStringLiteral("Web controls"), QStringLiteral("Alt+Left")},
        {QStringLiteral("web.forward"), QStringLiteral("Go forward"), QStringLiteral("Web controls"), QStringLiteral("Alt+Right")},
        {QStringLiteral("web.focusUrl"), QStringLiteral("Focus URL field"), QStringLiteral("Web controls"), QStringLiteral("Ctrl+L")},
        {QStringLiteral("web.devTools"), QStringLiteral("Toggle DevTools"), QStringLiteral("Web controls"), QStringLiteral("F12")},
        {QStringLiteral("view.fit"), QStringLiteral("Fit device to workspace"), QStringLiteral("View"), QStringLiteral("Ctrl+0")},
        {QStringLiteral("view.scale25"), QStringLiteral("Set device scale to 25%"), QStringLiteral("View"), QStringLiteral("Ctrl+1")},
        {QStringLiteral("view.scale50"), QStringLiteral("Set device scale to 50%"), QStringLiteral("View"), QStringLiteral("Ctrl+2")},
        {QStringLiteral("view.scale75"), QStringLiteral("Set device scale to 75%"), QStringLiteral("View"), QStringLiteral("Ctrl+3")},
        {QStringLiteral("view.scale100"), QStringLiteral("Set device scale to 100%"), QStringLiteral("View"), QStringLiteral("Ctrl+4")},
        {QStringLiteral("view.scale125"), QStringLiteral("Set device scale to 125%"), QStringLiteral("View"), QStringLiteral("Ctrl+5")},
        {QStringLiteral("android.home"), QStringLiteral("Android Home"), QStringLiteral("Android controls"), QStringLiteral("Ctrl+Alt+H")},
        {QStringLiteral("android.back"), QStringLiteral("Android Back"), QStringLiteral("Android controls"), QStringLiteral("Ctrl+Alt+Left")},
        {QStringLiteral("android.recents"), QStringLiteral("Android Recents"), QStringLiteral("Android controls"), QStringLiteral("Ctrl+Alt+Right")},
    };
}

ShortcutManager::ShortcutManager(Settings* settings, QObject* parent)
    : QAbstractListModel(parent)
    , m_settings(settings)
    , m_definitions(definitions())
{
    m_sequences.reserve(m_definitions.size());
    for (const auto& definition : m_definitions) {
        m_sequences.append(normalizedSequence(definition.defaultSequence));
    }

    if (!m_settings) {
        return;
    }

    const auto saved = m_settings->loadShortcuts();
    for (const auto& definition : m_definitions) {
        if (!saved.contains(definition.id)) {
            continue;
        }
        bool valid = false;
        const auto sequence = normalizedSequence(saved.value(definition.id), &valid);
        if ((!saved.value(definition.id).trimmed().isEmpty() && !valid)
            || conflicts(definition.id, sequence)) {
            setError(QStringLiteral("Ignored conflicting shortcut for %1").arg(definition.label));
            continue;
        }
        m_sequences[indexOf(definition.id)] = sequence;
    }
}

QAbstractListModel* ShortcutManager::actions()
{
    return this;
}

QString ShortcutManager::errorMessage() const
{
    return m_errorMessage;
}

int ShortcutManager::rowCount(const QModelIndex& parent) const
{
    return parent.isValid() ? 0 : m_definitions.size();
}

QVariant ShortcutManager::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_definitions.size()) {
        return {};
    }
    const auto& definition = m_definitions.at(index.row());
    switch (role) {
    case ActionIdRole:
        return definition.id;
    case LabelRole:
        return definition.label;
    case CategoryRole:
        return definition.category;
    case DefaultSequenceRole:
        return definition.defaultSequence;
    case SequenceRole:
        return m_sequences.at(index.row());
    case Qt::DisplayRole:
        return definition.label;
    default:
        return {};
    }
}

QHash<int, QByteArray> ShortcutManager::roleNames() const
{
    return {
        {ActionIdRole, "actionId"},
        {LabelRole, "label"},
        {CategoryRole, "category"},
        {DefaultSequenceRole, "defaultSequence"},
        {SequenceRole, "sequence"},
    };
}

bool ShortcutManager::setShortcut(const QString& actionId, const QString& sequence)
{
    const auto row = indexOf(actionId);
    if (row < 0) {
        setError(QStringLiteral("Unknown shortcut action: %1").arg(actionId));
        return false;
    }

    bool valid = false;
    const auto normalized = normalizedSequence(sequence, &valid);
    if ((!sequence.trimmed().isEmpty() && !valid)) {
        setError(QStringLiteral("Invalid shortcut: %1").arg(sequence));
        return false;
    }
    if (conflicts(actionId, normalized)) {
        setError(QStringLiteral("Shortcut %1 is already assigned to another action")
                     .arg(normalized));
        return false;
    }

    if (m_sequences.at(row) == normalized) {
        clearError();
        return true;
    }
    m_sequences[row] = normalized;
    emit dataChanged(index(row), index(row), {SequenceRole});
    persist();
    clearError();
    return true;
}

bool ShortcutManager::resetShortcut(const QString& actionId)
{
    const auto row = indexOf(actionId);
    if (row < 0) {
        setError(QStringLiteral("Unknown shortcut action: %1").arg(actionId));
        return false;
    }
    return setShortcut(actionId, m_definitions.at(row).defaultSequence);
}

void ShortcutManager::resetAllShortcuts()
{
    for (int row = 0; row < m_definitions.size(); ++row) {
        m_sequences[row] = normalizedSequence(m_definitions.at(row).defaultSequence);
    }
    if (!m_definitions.isEmpty()) {
        emit dataChanged(index(0), index(m_definitions.size() - 1), {SequenceRole});
    }
    persist();
    clearError();
}

QString ShortcutManager::shortcutFor(const QString& actionId) const
{
    const auto row = indexOf(actionId);
    return row >= 0 ? m_sequences.at(row) : QString {};
}

QString ShortcutManager::defaultShortcutFor(const QString& actionId) const
{
    const auto row = indexOf(actionId);
    return row >= 0 ? m_definitions.at(row).defaultSequence : QString {};
}

bool ShortcutManager::hasAction(const QString& actionId) const
{
    return indexOf(actionId) >= 0;
}

QString ShortcutManager::sequenceFromKeyEvent(int key, int modifiers) const
{
    const auto qtKey = static_cast<Qt::Key>(key);
    if (qtKey == Qt::Key_unknown || qtKey == Qt::Key_Control || qtKey == Qt::Key_Shift
        || qtKey == Qt::Key_Alt || qtKey == Qt::Key_Meta) {
        return {};
    }
    const auto sequence = QKeySequence(QKeyCombination(
        static_cast<Qt::KeyboardModifiers>(modifiers), qtKey));
    return sequence.toString(QKeySequence::PortableText);
}

bool ShortcutManager::trigger(const QString& actionId,
                              const QString& targetDeviceId,
                              const QString& origin)
{
    if (indexOf(actionId) < 0 || shortcutFor(actionId).isEmpty()) {
        return false;
    }
    emit actionTriggered(actionId, targetDeviceId, origin);
    return true;
}

int ShortcutManager::indexOf(const QString& actionId) const
{
    for (int row = 0; row < m_definitions.size(); ++row) {
        if (m_definitions.at(row).id == actionId) {
            return row;
        }
    }
    return -1;
}

QString ShortcutManager::normalizedSequence(const QString& sequence, bool* valid) const
{
    const auto trimmed = sequence.trimmed();
    if (trimmed.isEmpty()) {
        if (valid) {
            *valid = true;
        }
        return {};
    }
    const auto parsed = QKeySequence::fromString(trimmed, QKeySequence::PortableText);
    const bool isValid = !parsed.isEmpty();
    if (valid) {
        *valid = isValid;
    }
    return isValid ? parsed.toString(QKeySequence::PortableText) : QString {};
}

bool ShortcutManager::conflicts(const QString& actionId, const QString& sequence) const
{
    if (sequence.isEmpty()) {
        return false;
    }
    for (int row = 0; row < m_definitions.size(); ++row) {
        if (m_definitions.at(row).id != actionId && m_sequences.at(row) == sequence) {
            return true;
        }
    }
    return false;
}

void ShortcutManager::setError(const QString& message)
{
    if (m_errorMessage == message) {
        return;
    }
    m_errorMessage = message;
    emit errorMessageChanged();
}

void ShortcutManager::clearError()
{
    setError({});
}

void ShortcutManager::persist()
{
    if (!m_settings) {
        return;
    }
    QHash<QString, QString> overrides;
    for (int row = 0; row < m_definitions.size(); ++row) {
        const auto& definition = m_definitions.at(row);
        const auto defaultSequence = normalizedSequence(definition.defaultSequence);
        if (m_sequences.at(row) != defaultSequence) {
            overrides.insert(definition.id, m_sequences.at(row));
        }
    }
    m_settings->saveShortcuts(overrides);
}

} // namespace Hesh
