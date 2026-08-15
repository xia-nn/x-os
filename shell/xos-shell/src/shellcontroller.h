#pragma once
#include <QObject>

class ShellController : public QObject
{
    Q_OBJECT
public:
    explicit ShellController(QObject *parent = nullptr);

public slots:
    // 以命令字符串启动外部程序，例如 "alacritty"、"pcmanfm"、"firefox"
    void launch(const QString &command);
};
