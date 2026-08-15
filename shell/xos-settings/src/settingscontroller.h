#pragma once
#include <QObject>

class SettingsController : public QObject
{
    Q_OBJECT
public:
    explicit SettingsController(QObject *parent = nullptr);

public slots:
    // 以命令字符串启动外部程序，例如 "nm-connection-editor"、"xos-update"
    void launch(const QString &command);
};
