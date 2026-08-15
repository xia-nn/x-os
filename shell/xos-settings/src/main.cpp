#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>
#include <QCoreApplication>
#include "settingscontroller.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("X OS Settings"));
    app.setDesktopFileName(QStringLiteral("xos-settings"));

    QQmlApplicationEngine engine;

    // 暴露 Settings.launch(cmd) 给 QML，用于跳转/启动外部配置工具
    SettingsController controller;
    engine.rootContext()->setContextProperty(QStringLiteral("Settings"), &controller);

    // QML 资源安装到 /usr/share/xos-settings/
    const QUrl url(QStringLiteral("file:///usr/share/xos-settings/Settings.qml"));
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
