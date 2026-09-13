import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services as Services

Scope {
    WlSessionLock {
        id: sessionLock
        locked: Services.Lock.locked

        WlSessionLockSurface {
            color: "black"

            LockSurface {
                anchors.fill: parent
            }
        }
    }

    Variants {
        model: Services.Lock.unlocking ? Quickshell.screens : []

        PanelWindow {
            id: overlay

            required property var modelData

            screen: modelData
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-unlock"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            LockSurface {
                id: surface
                anchors.fill: parent
                animateIn: false

                onReadyChanged: if (ready) releaseTimer.restart()
                Component.onCompleted: {
                    if (!Services.Lock.locked)
                        playExit();
                    else if (ready)
                        releaseTimer.restart();
                }
                onExitFinished: Services.Lock.finishUnlock()
            }

            Timer {
                id: releaseTimer
                interval: 80
                onTriggered: Services.Lock.releaseLock()
            }

            Connections {
                target: Services.Lock
                function onLockedChanged() {
                    if (!Services.Lock.locked)
                        surface.playExit();
                }
            }
        }
    }
}
