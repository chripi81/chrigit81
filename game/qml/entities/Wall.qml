//![0]
import QtQuick 2.0
import Felgo 3.0
 // for accessing the Body.Static type

EntityBase {    
  entityType: "wall"

  // this gets used by the top wall to detect when the game is over
  signal collidedWithBox

  // this allows setting the color property or the Rectangle from outside, to use another color for the top wall
  property alias color: rectangle.color

  property alias collider: collider

  Rectangle {
    id: rectangle
    color: "blue"
    anchors.fill: parent
  }
  BoxCollider {
    id: collider
    anchors.fill: parent
    bodyType: Body.Static // the body shouldnt move

    fixture.onBeginContact: collidedWithBox()
  }
}
//![0]
