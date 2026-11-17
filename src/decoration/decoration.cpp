/*
 * FocusWave window decoration — macOS-style "traffic light" buttons.
 *
 *  - Title bar uses the color scheme's title bar colors, so it follows light/dark/accent.
 *  - Rounded top corners, soft drop shadow with a hairline outline (no thick borders).
 *  - Red / yellow / green buttons; hovering any of them shows ×  −  + glyphs.
 *  - Buttons are grey in inactive windows, like macOS.
 *
 * Built for KDecoration3 (Plasma 6.3+). CMake detects whether this KDecoration3 uses
 * QRectF in paint() and defines FW_KDECO_FLOAT accordingly.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include <KDecoration3/DecoratedWindow>
#include <KDecoration3/Decoration>
#include <KDecoration3/DecorationButton>
#include <KDecoration3/DecorationButtonGroup>
#include <KDecoration3/DecorationSettings>
#include <KDecoration3/DecorationShadow>

#include <KPluginFactory>

#include <QFontMetricsF>
#include <QImage>
#include <QPainter>
#include <QPainterPath>
#include <QPointer>

#include <algorithm>
#include <cmath>
#include <functional>
#include <memory>
#include <vector>

namespace FocusWave
{
#ifdef FW_KDECO_FLOAT
using PaintRect = QRectF;
#else
using PaintRect = QRect;
#endif

using KDecoration3::ColorGroup;
using KDecoration3::ColorRole;
using KDecoration3::DecorationButtonType;

constexpr int kCornerRadius = 10;
constexpr qreal kDot = 13.0;      // traffic light diameter
constexpr qreal kDotGap = 8.0;    // space between lights
constexpr qreal kSidePadding = 12.0;

static KDecoration3::DecorationButton *rawButton(KDecoration3::DecorationButton *b)
{
    return b;
}
static KDecoration3::DecorationButton *rawButton(const QPointer<KDecoration3::DecorationButton> &b)
{
    return b.data();
}

static qreal luminance(const QColor &c)
{
    return 0.2126 * c.redF() + 0.7152 * c.greenF() + 0.0722 * c.blueF();
}

// ---------------------------------------------------------------- shadow

static void boxBlurAlpha(std::vector<int> &a, int w, int h, int r)
{
    if (r < 1) {
        return;
    }
    std::vector<int> tmp(a.size());
    const int div = 2 * r + 1;
    // horizontal
    for (int y = 0; y < h; ++y) {
        int sum = 0;
        const int row = y * w;
        for (int i = -r; i <= r; ++i) {
            sum += (i >= 0 && i < w) ? a[row + i] : 0;
        }
        for (int x = 0; x < w; ++x) {
            tmp[row + x] = sum / div;
            const int out = x - r;
            const int in = x + r + 1;
            sum -= (out >= 0) ? a[row + out] : 0;
            sum += (in < w) ? a[row + in] : 0;
        }
    }
    // vertical
    for (int x = 0; x < w; ++x) {
        int sum = 0;
        for (int i = -r; i <= r; ++i) {
            sum += (i >= 0 && i < h) ? tmp[i * w + x] : 0;
        }
        for (int y = 0; y < h; ++y) {
            a[y * w + x] = sum / div;
            const int out = y - r;
            const int in = y + r + 1;
            sum -= (out >= 0) ? tmp[out * w + x] : 0;
            sum += (in < h) ? tmp[in * w + x] : 0;
        }
    }
}

static std::shared_ptr<KDecoration3::DecorationShadow> makeShadow(bool active, bool dark)
{
    const int blur = active ? 26 : 16;
    const int offsetY = active ? 9 : 5;
    const qreal strength = dark ? (active ? 0.62 : 0.45) : (active ? 0.30 : 0.18);
    const int pad = blur * 2;
    const int box = 2 * pad + 2 * kCornerRadius;
    const int size = box + 2 * pad;

    // 1. window shape, shifted down, as an alpha mask
    QImage mask(size, size, QImage::Format_ARGB32_Premultiplied);
    mask.fill(Qt::transparent);
    {
        QPainter p(&mask);
        p.setRenderHint(QPainter::Antialiasing);
        p.setPen(Qt::NoPen);
        p.setBrush(QColor(0, 0, 0, int(255 * strength)));
        p.drawRoundedRect(QRectF(pad, pad + offsetY, box, box), kCornerRadius, kCornerRadius);
    }
    // 2. blur it (three box blurs ≈ gaussian)
    std::vector<int> alpha(size_t(size) * size);
    for (int y = 0; y < size; ++y) {
        const QRgb *line = reinterpret_cast<const QRgb *>(mask.constScanLine(y));
        for (int x = 0; x < size; ++x) {
            alpha[size_t(y) * size + x] = qAlpha(line[x]);
        }
    }
    const int r = std::max(1, blur / 3);
    for (int i = 0; i < 3; ++i) {
        boxBlurAlpha(alpha, size, size, r);
    }
    QImage shadow(size, size, QImage::Format_ARGB32_Premultiplied);
    for (int y = 0; y < size; ++y) {
        QRgb *line = reinterpret_cast<QRgb *>(shadow.scanLine(y));
        for (int x = 0; x < size; ++x) {
            line[x] = qRgba(0, 0, 0, std::clamp(alpha[size_t(y) * size + x], 0, 255));
        }
    }
    // 3. cut out the window itself and draw a hairline outline around it
    const QRect windowRect(pad, pad, box, box);
    {
        QPainter p(&shadow);
        p.setRenderHint(QPainter::Antialiasing);
        p.setPen(Qt::NoPen);
        p.setBrush(Qt::black);
        p.setCompositionMode(QPainter::CompositionMode_DestinationOut);
        p.drawRoundedRect(QRectF(windowRect), kCornerRadius, kCornerRadius);
        p.setCompositionMode(QPainter::CompositionMode_SourceOver);
        p.setBrush(Qt::NoBrush);
        p.setPen(QPen(dark ? QColor(255, 255, 255, active ? 40 : 28) : QColor(0, 0, 0, active ? 46 : 30), 1.0));
        p.drawRoundedRect(QRectF(windowRect).adjusted(-0.5, -0.5, 0.5, 0.5), kCornerRadius + 0.5, kCornerRadius + 0.5);
    }

    auto result = std::make_shared<KDecoration3::DecorationShadow>();
    result->setPadding(QMargins(pad, pad, pad, pad));
    result->setInnerShadowRect(QRect(QRect(0, 0, size, size).center(), QSize(1, 1)));
    result->setShadow(shadow);
    return result;
}

// ---------------------------------------------------------------- decoration

class Decoration : public KDecoration3::Decoration
{
    Q_OBJECT
public:
    explicit Decoration(QObject *parent = nullptr, const QVariantList &args = QVariantList())
        : KDecoration3::Decoration(parent, args)
    {
    }

    bool init() override;
    void paint(QPainter *painter, const PaintRect &repaintArea) override;

    bool buttonsHovered() const
    {
        return m_buttonsHovered;
    }
    bool darkTitleBar() const
    {
        return luminance(titleBarColor()) < 0.5;
    }
    QColor titleBarColor() const
    {
        return window()->color(window()->isActive() ? ColorGroup::Active : ColorGroup::Inactive, ColorRole::TitleBar);
    }
    QColor titleTextColor() const
    {
        QColor c = window()->color(window()->isActive() ? ColorGroup::Active : ColorGroup::Inactive, ColorRole::Foreground);
        if (!window()->isActive()) {
            c.setAlphaF(0.65f);
        }
        return c;
    }
    int titleHeight() const
    {
        const QFontMetricsF fm(settings()->font());
        return std::max(30, int(std::ceil(fm.height())) + 14);
    }

private:
    void createButtons();
    void updateBorders();
    void updateLayout();
    void updateShadow();
    void updateHover();
    void forEachButton(const std::function<void(KDecoration3::DecorationButton *)> &fn) const;

    KDecoration3::DecorationButtonGroup *m_left = nullptr;
    KDecoration3::DecorationButtonGroup *m_right = nullptr;
    bool m_buttonsHovered = false;
};

class Button : public KDecoration3::DecorationButton
{
    Q_OBJECT
public:
    Button(DecorationButtonType type, Decoration *decoration, QObject *parent = nullptr)
        : KDecoration3::DecorationButton(type, decoration, parent)
    {
        setGeometry(QRectF(0, 0, kDot + kDotGap, decoration->titleHeight()));
    }

    static KDecoration3::DecorationButton *create(DecorationButtonType type, KDecoration3::Decoration *decoration, QObject *parent)
    {
        auto *deco = qobject_cast<Decoration *>(decoration);
        if (!deco) {
            return nullptr;
        }
        switch (type) {
        case DecorationButtonType::Close:
        case DecorationButtonType::Minimize:
        case DecorationButtonType::Maximize:
            return new Button(type, deco, parent);
        default:
            return nullptr; // other button types are not part of this style
        }
    }

    void paint(QPainter *painter, const PaintRect &repaintArea) override;
};

void Decoration::forEachButton(const std::function<void(KDecoration3::DecorationButton *)> &fn) const
{
    for (auto *group : {m_left, m_right}) {
        if (!group) {
            continue;
        }
        for (const auto &b : group->buttons()) {
            if (auto *button = rawButton(b)) {
                fn(button);
            }
        }
    }
}

bool Decoration::init()
{
    auto *w = window();
    connect(w, &KDecoration3::DecoratedWindow::activeChanged, this, [this]() {
        updateShadow();
        update();
    });
    connect(w, &KDecoration3::DecoratedWindow::captionChanged, this, [this]() {
        update();
    });
    connect(w, &KDecoration3::DecoratedWindow::widthChanged, this, &Decoration::updateLayout);
    connect(w, &KDecoration3::DecoratedWindow::maximizedChanged, this, [this]() {
        updateBorders();
        updateLayout();
        update();
    });
    connect(w, &KDecoration3::DecoratedWindow::paletteChanged, this, [this]() {
        updateShadow();
        update();
    });

    auto s = settings();
    connect(s.get(), &KDecoration3::DecorationSettings::reconfigured, this, [this]() {
        createButtons();
        updateBorders();
        updateLayout();
        updateShadow();
        update();
    });
    connect(s.get(), &KDecoration3::DecorationSettings::fontChanged, this, [this]() {
        updateBorders();
        updateLayout();
    });
    connect(s.get(), &KDecoration3::DecorationSettings::decorationButtonsLeftChanged, this, [this]() {
        createButtons();
        updateLayout();
    });
    connect(s.get(), &KDecoration3::DecorationSettings::decorationButtonsRightChanged, this, [this]() {
        createButtons();
        updateLayout();
    });

    createButtons();
    updateBorders();
    updateLayout();
    updateShadow();
    return true;
}

void Decoration::createButtons()
{
    delete m_left;
    delete m_right;
    m_left = new KDecoration3::DecorationButtonGroup(KDecoration3::DecorationButtonGroup::Position::Left, this, &Button::create);
    m_right = new KDecoration3::DecorationButtonGroup(KDecoration3::DecorationButtonGroup::Position::Right, this, &Button::create);
    m_buttonsHovered = false;
    forEachButton([this](KDecoration3::DecorationButton *b) {
        connect(b, &KDecoration3::DecorationButton::hoveredChanged, this, &Decoration::updateHover);
    });
}

void Decoration::updateHover()
{
    bool any = false;
    forEachButton([&any](KDecoration3::DecorationButton *b) {
        any = any || b->isHovered();
    });
    if (any != m_buttonsHovered) {
        m_buttonsHovered = any;
        update();
    }
}

void Decoration::updateBorders()
{
    const bool maximized = window()->isMaximized();
    setBorders(QMargins(0, titleHeight(), 0, 0));
    setResizeOnlyBorders(maximized ? QMargins() : QMargins(6, 4, 6, 6));
    setOpaque(maximized);
}

void Decoration::updateLayout()
{
    const int th = titleHeight();
    const int width = int(std::ceil(window()->width()));
    setTitleBar(QRect(0, 0, width, th));
    forEachButton([th](KDecoration3::DecorationButton *b) {
        b->setGeometry(QRectF(0, 0, kDot + kDotGap, th));
    });
    if (m_left) {
        m_left->setSpacing(0);
        m_left->setPos(QPointF(kSidePadding - kDotGap / 2.0, 0));
    }
    if (m_right) {
        m_right->setSpacing(0);
        m_right->setPos(QPointF(width - kSidePadding + kDotGap / 2.0 - m_right->geometry().width(), 0));
    }
    update();
}

void Decoration::updateShadow()
{
    static std::shared_ptr<KDecoration3::DecorationShadow> cache[2][2];
    const bool active = window()->isActive();
    const bool dark = darkTitleBar();
    auto &slot = cache[active ? 1 : 0][dark ? 1 : 0];
    if (!slot) {
        slot = makeShadow(active, dark);
    }
    setShadow(slot);
}

void Decoration::paint(QPainter *painter, const PaintRect &repaintArea)
{
    const int th = titleHeight();
    const qreal width = window()->width();
    const QRectF bar(0, 0, width, th);
    const bool maximized = window()->isMaximized();

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);
    painter->setPen(Qt::NoPen);
    painter->setBrush(titleBarColor());
    if (maximized) {
        painter->drawRect(bar);
    } else {
        painter->setClipRect(bar);
        painter->drawRoundedRect(QRectF(0, 0, width, th + kCornerRadius * 2), kCornerRadius, kCornerRadius);
        painter->setClipping(false);
    }

    // hairline between title bar and content
    QColor line = titleTextColor();
    line.setAlphaF(darkTitleBar() ? 0.10f : 0.08f);
    painter->setPen(QPen(line, 1.0));
    painter->drawLine(QPointF(0, th - 0.5), QPointF(width, th - 0.5));

    // title, centered like macOS, never overlapping the buttons
    const qreal leftEdge = m_left ? m_left->geometry().right() + 8 : kSidePadding;
    const qreal rightEdge = (m_right && m_right->geometry().width() > 0) ? m_right->geometry().left() - 8 : width - kSidePadding;
    const qreal reserve = std::max(leftEdge, width - rightEdge);
    QRectF textRect(reserve, 0, std::max<qreal>(0, width - 2 * reserve), th);
    painter->setFont(settings()->font());
    painter->setPen(titleTextColor());
    const QString caption = QFontMetricsF(settings()->font()).elidedText(window()->caption(), Qt::ElideRight, textRect.width());
    painter->drawText(textRect, Qt::AlignCenter | Qt::TextSingleLine, caption);
    painter->restore();

    forEachButton([painter, &repaintArea](KDecoration3::DecorationButton *b) {
        static_cast<Button *>(b)->paint(painter, repaintArea);
    });
}

// ---------------------------------------------------------------- buttons

void Button::paint(QPainter *painter, const PaintRect &repaintArea)
{
    Q_UNUSED(repaintArea)
    if (!isVisible()) {
        return;
    }
    KDecoration3::Decoration *base = decoration();
    auto *deco = qobject_cast<Decoration *>(base);
    if (!deco) {
        return;
    }

    const QRectF g = geometry();
    const QRectF dot(g.center().x() - kDot / 2.0, g.center().y() - kDot / 2.0, kDot, kDot);
    const bool activeWindow = deco->window()->isActive();
    const bool showGlyphs = deco->buttonsHovered() && isEnabled();

    QColor fill;
    switch (type()) {
    case DecorationButtonType::Close:
        fill = QColor(0xFF, 0x5F, 0x57);
        break;
    case DecorationButtonType::Minimize:
        fill = QColor(0xFE, 0xBC, 0x2E);
        break;
    default:
        fill = QColor(0x28, 0xC8, 0x40);
        break;
    }
    if (!isEnabled() || (!activeWindow && !deco->buttonsHovered())) {
        fill = deco->darkTitleBar() ? QColor(255, 255, 255, 56) : QColor(0, 0, 0, 40);
    }
    if (isPressed()) {
        fill = fill.darker(130);
    }

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);
    painter->setPen(QPen(QColor(0, 0, 0, fill.alpha() > 200 ? 30 : 0), 0.8));
    painter->setBrush(fill);
    painter->drawEllipse(dot);

    if (showGlyphs) {
        QPen pen(QColor(0, 0, 0, 150), 1.3);
        pen.setCapStyle(Qt::RoundCap);
        painter->setPen(pen);
        const QPointF c = dot.center();
        const qreal k = kDot * 0.22;
        switch (type()) {
        case DecorationButtonType::Close:
            painter->drawLine(c + QPointF(-k, -k), c + QPointF(k, k));
            painter->drawLine(c + QPointF(-k, k), c + QPointF(k, -k));
            break;
        case DecorationButtonType::Minimize:
            painter->drawLine(c + QPointF(-k * 1.2, 0), c + QPointF(k * 1.2, 0));
            break;
        default: {
            // two small triangles: outward = maximize, inward = restore
            painter->setPen(Qt::NoPen);
            painter->setBrush(QColor(0, 0, 0, 150));
            const qreal t = kDot * 0.30;
            const bool restore = isChecked();
            QPainterPath path;
            if (!restore) {
                path.moveTo(c + QPointF(-t, -t));
                path.lineTo(c + QPointF(t * 0.35, -t));
                path.lineTo(c + QPointF(-t, t * 0.35));
                path.closeSubpath();
                path.moveTo(c + QPointF(t, t));
                path.lineTo(c + QPointF(-t * 0.35, t));
                path.lineTo(c + QPointF(t, -t * 0.35));
                path.closeSubpath();
            } else {
                path.moveTo(c + QPointF(-0.6, -0.6));
                path.lineTo(c + QPointF(-0.6 - t * 1.0, -0.6));
                path.lineTo(c + QPointF(-0.6, -0.6 - t * 1.0));
                path.closeSubpath();
                path.moveTo(c + QPointF(0.6, 0.6));
                path.lineTo(c + QPointF(0.6 + t * 1.0, 0.6));
                path.lineTo(c + QPointF(0.6, 0.6 + t * 1.0));
                path.closeSubpath();
            }
            painter->drawPath(path);
            break;
        }
        }
    }
    painter->restore();
}

} // namespace FocusWave

K_PLUGIN_FACTORY_WITH_JSON(FocusWaveDecorationFactory, "focuswave-decoration.json", registerPlugin<FocusWave::Decoration>();)

#include "decoration.moc"
