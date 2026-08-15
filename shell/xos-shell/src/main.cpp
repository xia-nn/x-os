#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>
#include <QCoreApplication>
#include "shellcontroller.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("X OS Shell"));
    app.setDesktopFileName(QStringLiteral("xos-shell"));

    QQmlApplicationEngine engine;

    // 暴露 Shell.launch(cmd) 给 QML，用于启动外部应用
    ShellController controller;
    engine.rootContext()->setContextProperty(QStringLiteral("Shell"), &controller);

    // QML 资源安装到 /usr/share/xos-shell/
    const QUrl url(QStringLiteral("file:///usr/share/xos-shell/main.qml"));
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
