#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>
#include <QCoreApplication>
#include "firstbootcontroller.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("X OS First Boot"));
    app.setDesktopFileName(QStringLiteral("xos-firstboot"));

    QQmlApplicationEngine engine;

    // 暴露 FirstBoot.apply(tz, locale) / FirstBoot.finish() 给 QML
    FirstBootController controller;
    engine.rootContext()->setContextProperty(QStringLiteral("FirstBoot"), &controller);

    // QML 资源安装到 /usr/share/xos-firstboot/
    const QUrl url(QStringLiteral("file:///usr/share/xos-firstboot/firstboot.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &loaded) {
                         if (!obj && loaded == url)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    engine.load(url);
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
