// Quickshell entry point: a bar on every monitor + the notification daemon.
// Reloads automatically when any file in this directory is saved.
import Quickshell
import QtQuick

ShellRoot {
    Bar {}
    Notifications {}
    Dock {}
}
