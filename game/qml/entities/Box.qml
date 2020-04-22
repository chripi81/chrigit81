//![0]
import QtQuick 2.0
import Felgo 3.0

EntityBase {
  id: box
  entityType: "box"

  // the origin (the 0/0 position of the entity) of this entity is the center, thus we cannot use an anchors.fill: parent in Image and BoxCollider, otherwise it would use the top left corner as origin
  width: 32
  height: 32

  // the 0/0 of the entity should be the center of the collider and image
  // this is required when a width & height are set to the entity! in that case, the rotation should be applied around the center (which is top-left, not the width/2,height/2 Item.Center which is the default value)
  transformOrigin: Item.TopLeft

  Image {
    id: boxImage
    source: "../../assets/img/box.png"

    // set the size of the image to the one of the collider and not vice versa, because the physics properties depend on the collider size
    anchors.fill: boxCollider
  }

  BoxCollider {
    id: boxCollider

    // the size effects the physics settings (the bigger the heavier)
    // this is set automatically in any collider - the default size is the one of parent!
    //width: parent.width
    //height: parent.height
    // the collider should have its origin at the x/y of the entity (so the center is in the TopLeft)
    x: -width/2
    y: -height/2


    friction: 1.6
    restitution: 0 // restitution is bounciness - a wooden box doesn't bounce
    density: 0.1 // this makes the box more heavy

    fixture.onBeginContact: {
      // when colliding with another entity, play the sound and start particleEffect
      collisionSound.play();
      collisionParticleEffect.start();
    }
  }

  // the soundEffect is played at a collision
  SoundEffect {
    id: collisionSound
    source: "../../assets/snd/boxCollision.wav"
  }

  // the ParticleEffect is started at a collision
  Particle {
    id: collisionParticleEffect
    // make the particles float independent from the entity position - this would be the default setting, but for making it clear it is added explicitly here as well
    positionType: 0
    fileName: "SmokeParticle.json"
  }
}
//![0]
