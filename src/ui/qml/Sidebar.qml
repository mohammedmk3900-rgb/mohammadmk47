import QtQuick
import QtQuick.Controls

Rectangle {

    color: "#11151b"

    Column {

        spacing: 25

        anchors.centerIn: parent

        Repeater {

            model: [
                "Library",
                "Marketplace",
                "Mods",
                "Downloads",
                "Friends",
                "AI",
                "Settings"
            ]

            delegate: Button {

                text: modelData

                width: 180
                height: 52

                background: Rectangle {
                    color: "#00ffee"
                    opacity: 0.1
                    radius: 12
                }
            }
        }
    }
}
