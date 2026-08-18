#pragma once

#include <QAbstractListModel>
#include <QKeySequence>
#include <QVector>

namespace Hesh {

class Settings;

class ShortcutManager final : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QAbstractListModel* actions READ actions CONSTANT)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    enum Role {
        ActionIdRole = Qt::UserRole + 1,
        LabelRole,
        CategoryRole,
        DefaultSequenceRole,
        SequenceRole,
    };
    Q_ENUM(Role)

    explicit ShortcutManager(Settings* settings, QObject* parent = nullptr);

    QAbstractListModel* actions();
    QString errorMessage() const;

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE bool setShortcut(const QString& actionId, const QString& sequence);
    Q_INVOKABLE bool resetShortcut(const QString& actionId);
    Q_INVOKABLE void resetAllShortcuts();
    Q_INVOKABLE QString shortcutFor(const QString& actionId) const;
    Q_INVOKABLE QString defaultShortcutFor(const QString& actionId) const;
    Q_INVOKABLE bool hasAction(const QString& actionId) const;
    Q_INVOKABLE QString sequenceFromKeyEvent(int key, int modifiers) const;
    Q_INVOKABLE bool trigger(const QString& actionId,
                             const QString& targetDeviceId,
                             const QString& origin);

signals:
    void errorMessageChanged();
    void actionTriggered(const QString& actionId,
                         const QString& targetDeviceId,
                         const QString& origin);

private:
    struct Definition {
        QString id;
        QString label;
        QString category;
        QString defaultSequence;
    };

    static QVector<Definition> definitions();
    int indexOf(const QString& actionId) const;
    QString normalizedSequence(const QString& sequence, bool* valid = nullptr) const;
    bool conflicts(const QString& actionId, const QString& sequence) const;
    void setError(const QString& message);
    void clearError();
    void persist();

    Settings* m_settings = nullptr;
    QVector<Definition> m_definitions;
    QVector<QString> m_sequences;
    QString m_errorMessage;
};

} // namespace Hesh
