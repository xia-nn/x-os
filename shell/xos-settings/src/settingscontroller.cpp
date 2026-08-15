#include "settingscontroller.h"
#include <QProcess>

SettingsController::SettingsController(QObject *parent)
    : QObject(parent)
{
}

void SettingsController::launch(const QString &command)
{
    if (command.isEmpty())
        return;

    QStringList parts = QProcess::splitCommand(command);
    if (parts.isEmpty())
        return;

    const QString program = parts.takeFirst();
    QProcess::startDetached(program, parts);
}
