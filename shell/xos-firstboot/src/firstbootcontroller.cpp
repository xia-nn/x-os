#include "firstbootcontroller.h"
#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QCoreApplication>

FirstBootController::FirstBootController(QObject *parent)
    : QObject(parent)
{
}

void FirstBootController::apply(const QString &timezone, const QString &locale)
{
    // 时区：软链到对应的 zoneinfo
    QFile::remove(QStringLiteral("/etc/localtime"));
    QFile::link(QStringLiteral("/usr/share/zoneinfo/") + timezone,
                QStringLiteral("/etc/localtime"));

    // 语言/区域：写入 locale.conf
    QFile lc(QStringLiteral("/etc/locale.conf"));
    if (lc.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        QTextStream ts(&lc);
        ts << "LANG=" << locale << "\n";
        lc.close();
    }

    // 标记首次设置已完成（Live overlay 重启会重置，安装到硬盘后由 Calamares 接管）
    QDir().mkpath(QStringLiteral("/var/lib/xos"));
    QFile done(QStringLiteral("/var/lib/xos/firstboot-done"));
    if (done.open(QIODevice::WriteOnly)) {
        done.write("1");
        done.close();
    }
}

void FirstBootController::finish()
{
    QCoreApplication::quit();
}
