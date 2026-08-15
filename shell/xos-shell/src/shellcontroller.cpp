#include "shellcontroller.h"
#include <QProcess>

ShellController::ShellController(QObject *parent)
    : QObject(parent)
{
}

void ShellController::launch(const QString &command)
{
    if (command.isEmpty())
        return;

    QStringList parts = QProcess::splitCommand(command);
    if (parts.isEmpty())
        return;

    const QString program = parts.takeFirst();
    QProcess::startDetached(program, parts);
}
