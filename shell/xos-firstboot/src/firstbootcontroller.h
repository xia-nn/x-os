#pragma once
#include <QObject>

class FirstBootController : public QObject
{
    Q_OBJECT
public:
    explicit FirstBootController(QObject *parent = nullptr);

public slots:
    // 应用所选地区：写入 /etc/localtime 软链、/etc/locale.conf，并标记首次设置完成
    void apply(const QString &timezone, const QString &locale);
    // 退出向导（之后 autostart 会拉起 xos-shell）
    void finish();
};
