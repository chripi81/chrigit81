import Felgo 3.0 // for the gaming components
import QtQuick 2.0 // for the Image element
import "entities"

GameWindow {
  id: gameWindow

  // You get free licenseKeys from https://felgo.com/licenseKey
  // With a licenseKey you can:
  //  * Publish your games & apps for the app stores
  //  * Remove the Felgo Splash Screen or set a custom one (available with the Pro Licenses)
  //  * Add plugins to monetize, analyze & improve your apps (available with the Pro Licenses)
  //licenseKey: "<generate one from https://felgo.com/licenseKey>"

  activeScene: scene

  EntityManager {
    id: entityManager
    entityContainer: scene
  }

  Rectangle {
    anchors.fill: parent
    color: "black"
  }

  Scene {
    id: scene
    width: 480
    height: 320

    // gets increased when a new box is created, and reset to 0 when a new game is started
    // start with 1, because initially 1 Box is created
    property int createdBoxes: 1

    // this is the required minimum distance from the left and from the right (the scene.width)
    // when the box is rotated at 90°, its distance from the center is box1.width*Sqrt2, because width and height are the same
    // the hint about this issue was kindly provided by Martin Eigel
    property real safetyDistance: -1

    // display the amount of stacked boxes
    Text {
      text: "Boxes: " + scene.createdBoxes
      color: "white"
      z: 1 // put on top of everything else in the Scene
    }

    PhysicsWorld {
      id: physicsWorld
      gravity.y: 9.81 // make the objects fall faster
      debugDrawVisible: true

      // these are performance settings to avoid boxes colliding too far together
      // set them as low as possible so it still looks good
      updatesPerSecondForPhysics: 60
      velocityIterations: 5
      positionIterations: 5
    }

    Component {
      id: mouseJoint
      Item {
        id: jointItem

        // make important joint properties accessible
        property alias bodyB: joint.bodyB
        property alias target: joint.target

        // set up the mouse joint
        MouseJoint {
          id: joint
          // make this high enough so the box with its density is moved quickly
          maxForce: 30000 * physicsWorld.pixelsPerMeter
          // The damping ratio. 0 = no damping, 1 = critical damping. Default is 0.7
          dampingRatio: 1
          // The response speed, default is 5
          frequencyHz: 2
        }

        // also destroy joint if a box is destroyed
        Connections {
          // joint.bodyB.target is the box entity connected with the joint
          target: joint.bodyB !== null ? joint.bodyB.target : null
          onEntityDestroyed: { joint.bodyB = null; jointItem.destroy() }
        }
      }
    }

    // when the user presses a box, move it towards the touch position
    MouseArea {
      anchors.fill: parent

      property Body selectedBody: null
      property Item mouseJointWhileDragging: null

      onPressed: {

        selectedBody = physicsWorld.bodyAt(Qt.point(mouseX, mouseY));
        console.debug("selected body at position", mouseX, mouseY, ":", selectedBody);
        // if the user selected a body, this if-check is true
        if(selectedBody) {
          // create a new mouseJoint
          var properties = {
            // set the target position to the current touch position (initial position)
            target: Qt.point(mouseX, mouseY),

            // body B is the one that actually moves -> connect the joint with the body
            bodyB: selectedBody
          }

          mouseJointWhileDragging = mouseJoint.createObject(physicsWorld, properties)
        }
      }

      onPositionChanged: {
        // this check is necessary, because the user might also drag when no initial body was selected
        if (mouseJointWhileDragging)
          mouseJointWhileDragging.target = Qt.point(mouseX, mouseY)
      }
      onReleased: {
        // if the user pressed a body initially, remove the created MouseJoint
        if(selectedBody) {
          selectedBody = null
          if (mouseJointWhileDragging)
            mouseJointWhileDragging.destroy()
        }
      }
    }

    Box {
      id: box1
      entityId: "box1"
      x: scene.width/2
      y: 50 // position a bit to the bottom so it doesn't collide with the top wall

      Component.onCompleted: {

        // initialize the safetyZoneHoriztonal after the box is known
        if(scene.safetyDistance === -1) {
          // add a little addtional offset, to avoid generation at the very border
          scene.safetyDistance = box1.width*Math.SQRT2/2 + leftWall.width + 5
          console.debug("init safetyZoneHorizontal with", scene.safetyDistance)
        }

      }

    }

    Wall {
      // bottom wall
      height: 20
      anchors {
        bottom: scene.bottom
        left: scene.left
        right: scene.right
      }
    }

    Wall {
      // left wall
      id: leftWall
      width: 20
      height: scene.height
      anchors {
        left: scene.left
      }
    }

    Wall {
      // right wall
      width: 20
      height: scene.height
      anchors {
        right: scene.right
      }
    }
    Wall {
      // top wall
      id: topWall
      height: 20
      width: scene.width
      anchors {
        top: scene.top
      }
      color: "red" // make the top wall red
      onCollidedWithBox: {
        // gets called when the wall collides with a box, and the game should restart

        // remove all entities of type "box", but not the walls
        entityManager.removeEntitiesByFilter(["box"]);
        // reset the createdBoxes amount
        scene.createdBoxes = 0;
      }
    }

    // for toggling audio and particles
    Column {
      anchors.right: parent.right

      spacing: 5
      SimpleButton {
        text: "Toggle Audio"
        onClicked: settings.soundEnabled = !settings.soundEnabled
        anchors.right: parent.right
      }
      SimpleButton {
        text: "Toggle Particles"
        onClicked: settings.particlesEnabled = !settings.particlesEnabled
      }
    }


    Timer {
      id: timer
      interval: generateRandomInterval()
      running: true // start running from the beginning, when the scene is loaded
      repeat: true // otherwise restart wont work


      onTriggered: {

        var newEntityProperties = {
          // vary x between [ safetyZoneHoriztonal ... width-safetyZoneHoriztonal]
          x: utils.generateRandomValueBetween(scene.safetyDistance, scene.width-scene.safetyDistance),
          y: scene.safetyDistance, // position on top of the scene, at least below the top wall
          rotation: Math.random()*360
        }

        entityManager.createEntityFromUrlWithProperties(
              Qt.resolvedUrl("entities/Box.qml"),
              newEntityProperties);

        // increase the createdBoxes number
        scene.createdBoxes++

        timer.interval = generateRandomInterval()

        // restart the timer
        timer.restart()
      }

      function generateRandomInterval() {
        // recalculate new interval between 1000 and 3000
        return utils.generateRandomValueBetween(1000, 3000);
      }
    }

  }
}
