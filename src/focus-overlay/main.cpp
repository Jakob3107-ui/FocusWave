/*
 * focuswave-focus-overlay — the blur layer behind FocusWave Focus Mode.
 *
 * D-Bus service org.focuswave.FocusMode at /FocusMode (started on demand by D-Bus):
 *   Show()  -> string   Opens one transparent overlay per screen. Each overlay asks KWin
 *                        for blur-behind, so KWin's GPU blur blurs everything below it.
 *                        Returns the Focus Mode settings as JSON for the KWin script.
 *   Hide()               Closes the overlays and restores the normal blur strength.
 *   IsActive() -> bool
 *   Wait(ms: string)     Replies after `ms` milliseconds (a timer for the KWin script).
 *   signal ActiveChanged(bool)
 *
 * Settings come from ~/.config/focuswaverc, group [FocusMode] (written by the Customize app):
 *   BlurStrength=1..15  Dim=0..80 (%)  Tint=#000000  KeepDockVisible=true
 *   FollowActivation=true  Fade=true  FadeMs=220
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include <QApplication>
#include <QColor>
#include <QDBusConnection>
#include <QDBusContext>
#include <QDBusMessage>
#include <QJsonDocument>
#include <QJsonObject>
#include <QKeyEvent>
#include <QList>
#include <QMouseEvent>
#include <QPainter>
#include <QPointer>
#include <QScreen>
#include <QTimer>
#include <QWidget>
#include <QWindow>

#include <KConfig>
#include <KConfigGroup>
#include <KSharedConfig>
#include <KWindowEffects>

namespace
{
const QString kService = QStringLiteral("org.focuswave.FocusMode");
const QString kPath = QStringLiteral("/FocusMode");
const QString kShortcutName = QStringLiteral("FocusWave Focus Mode");
constexpr int kIdleQuitMs = 10 * 60 * 1000;

void toggleViaKWin()
{
    // Same entry point as the keyboard shortcut, so the KWin script stays in charge.
    QDBusMessage msg = QDBusMessage::createMethodCall(QStringLiteral("org.kde.kglobalaccel"),
                                                      QStringLiteral("/component/kwin"),
                                                      QStringLiteral("org.kde.kglobalaccel.Component"),
                                                      QStringLiteral("invokeShortcut"));
    msg << kShortcutName;
    QDBusConnection::sessionBus().asyncCall(msg);
}

void reconfigureKWinBlur()
{
    QDBusMessage msg = QDBusMessage::createMethodCall(QStringLiteral("org.kde.KWin"),
                                                      QStringLiteral("/Effects"),
                                                      QStringLiteral("org.kde.kwin.Effects"),
                                                      QStringLiteral("reconfigureEffect"));
    msg << QStringLiteral("blur");
    QDBusConnection::sessionBus().asyncCall(msg);
}
} // namespace

class OverlayWindow : public QWidget
{
public:
    OverlayWindow(QScreen *screen, const QColor &tint)
        : m_tint(tint)
    {
        setAttribute(Qt::WA_TranslucentBackground);
        setAttribute(Qt::WA_NoSystemBackground);
        setAttribute(Qt::WA_DeleteOnClose);
        setWindowFlags(Qt::FramelessWindowHint | Qt::WindowDoesNotAcceptFocus);
        // The KWin script recognises overlays by this title and maps them to a screen by name.
        setWindowTitle(QStringLiteral("FocusWave Overlay %1").arg(screen->name()));
        create();
        if (windowHandle()) {
            windowHandle()->setScreen(screen);
        }
        setGeometry(screen->geometry());
    }

    void enableBlur()
    {
        if (windowHandle()) {
            KWindowEffects::enableBlurBehind(windowHandle(), true);
        }
    }

protected:
    void paintEvent(QPaintEvent *) override
    {
        QPainter p(this);
        p.setCompositionMode(QPainter::CompositionMode_Source);
        p.fillRect(rect(), m_tint);
    }

    void mouseDoubleClickEvent(QMouseEvent *event) override
    {
        // Double-click the blurred background to leave Focus Mode.
        event->accept();
        toggleViaKWin();
    }

    void keyPressEvent(QKeyEvent *event) override
    {
        if (event->key() == Qt::Key_Escape) {
            toggleViaKWin();
        }
        event->accept();
    }

private:
    QColor m_tint;
};

class FocusService : public QObject, protected QDBusContext
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.focuswave.FocusMode")

public:
    FocusService()
    {
        m_idleTimer.setSingleShot(true);
        m_idleTimer.setInterval(kIdleQuitMs);
        connect(&m_idleTimer, &QTimer::timeout, qApp, &QCoreApplication::quit);
        restoreBlurStrength(); // in case we crashed while Focus Mode was on
        m_idleTimer.start();
    }

public Q_SLOTS:
    QString Show()
    {
        m_idleTimer.stop();
        KSharedConfig::Ptr config = KSharedConfig::openConfig(QStringLiteral("focuswaverc"));
        config->reparseConfiguration();
        const KConfigGroup group = config->group(QStringLiteral("FocusMode"));

        const int blurStrength = qBound(1, group.readEntry("BlurStrength", 12), 15);
        const int dim = qBound(0, group.readEntry("Dim", 20), 80);
        QColor tint = QColor::fromString(group.readEntry("Tint", QStringLiteral("#000000")));
        if (!tint.isValid()) {
            tint = QColor(Qt::black);
        }
        tint.setAlphaF(float(dim) / 100.0f);

        applyBlurStrength(blurStrength);
        closeOverlays();
        const auto screens = QGuiApplication::screens();
        for (QScreen *screen : screens) {
            auto *overlay = new OverlayWindow(screen, tint);
            overlay->show();
            overlay->enableBlur();
            m_overlays << overlay;
        }
        if (!m_active) {
            m_active = true;
            Q_EMIT ActiveChanged(true);
        }

        QJsonObject settings;
        settings.insert(QStringLiteral("keepDock"), group.readEntry("KeepDockVisible", true));
        settings.insert(QStringLiteral("follow"), group.readEntry("FollowActivation", true));
        settings.insert(QStringLiteral("fade"), group.readEntry("Fade", true));
        settings.insert(QStringLiteral("fadeMs"), qBound(0, group.readEntry("FadeMs", 220), 1000));
        return QString::fromUtf8(QJsonDocument(settings).toJson(QJsonDocument::Compact));
    }

    void Hide()
    {
        closeOverlays();
        restoreBlurStrength();
        if (m_active) {
            m_active = false;
            Q_EMIT ActiveChanged(false);
        }
        m_idleTimer.start();
    }

    bool IsActive() const
    {
        return m_active;
    }

    void Wait(const QString &milliseconds)
    {
        const int ms = qBound(0, milliseconds.toInt(), 2000);
        setDelayedReply(true);
        const QDBusMessage reply = message().createReply();
        QTimer::singleShot(ms, this, [reply]() {
            QDBusConnection::sessionBus().send(reply);
        });
    }

Q_SIGNALS:
    void ActiveChanged(bool active);

private:
    void closeOverlays()
    {
        for (const QPointer<OverlayWindow> &overlay : std::as_const(m_overlays)) {
            if (overlay) {
                overlay->close();
            }
        }
        m_overlays.clear();
    }

    // KWin's blur strength is one global setting. While Focus Mode is on we use the
    // Focus Mode strength and remember the user's normal value so it can be restored.
    void applyBlurStrength(int strength)
    {
        KConfig kwinrc(QStringLiteral("kwinrc"));
        KConfigGroup blur = kwinrc.group(QStringLiteral("Effect-blur"));
        KSharedConfig::Ptr ours = KSharedConfig::openConfig(QStringLiteral("focuswaverc"));
        KConfigGroup state = ours->group(QStringLiteral("FocusModeState"));

        if (!state.hasKey("SavedBlurStrength")) {
            state.writeEntry("SavedBlurStrength", blur.hasKey("BlurStrength") ? blur.readEntry("BlurStrength", 10) : -1);
            ours->sync();
        }
        if (blur.readEntry("BlurStrength", -1) != strength) {
            blur.writeEntry("BlurStrength", strength);
            kwinrc.sync();
            reconfigureKWinBlur();
        }
    }

    void restoreBlurStrength()
    {
        KSharedConfig::Ptr ours = KSharedConfig::openConfig(QStringLiteral("focuswaverc"));
        ours->reparseConfiguration();
        KConfigGroup state = ours->group(QStringLiteral("FocusModeState"));
        if (!state.hasKey("SavedBlurStrength")) {
            return;
        }
        const int saved = state.readEntry("SavedBlurStrength", -1);
        KConfig kwinrc(QStringLiteral("kwinrc"));
        KConfigGroup blur = kwinrc.group(QStringLiteral("Effect-blur"));
        if (saved < 0) {
            blur.deleteEntry("BlurStrength");
        } else {
            blur.writeEntry("BlurStrength", saved);
        }
        kwinrc.sync();
        state.deleteEntry("SavedBlurStrength");
        ours->sync();
        reconfigureKWinBlur();
    }

    QList<QPointer<OverlayWindow>> m_overlays;
    QTimer m_idleTimer;
    bool m_active = false;
};

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    QApplication::setApplicationName(QStringLiteral("focuswave-focus-overlay"));
    QApplication::setDesktopFileName(QStringLiteral("org.focuswave.FocusOverlay"));
    QApplication::setQuitOnLastWindowClosed(false);

    FocusService service;
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.registerObject(kPath, &service, QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllSignals)) {
        qWarning("focuswave-focus-overlay: could not register D-Bus object");
        return 1;
    }
    if (!bus.registerService(kService)) {
        qWarning("focuswave-focus-overlay: another instance is already running");
        return 0;
    }
    return app.exec();
}

#include "main.moc"
