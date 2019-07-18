package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;

class Bubble extends MemoryEntity {
    public static inline var SPEED = 1;
    public static inline var SFX_DISTANCE = 280;

    private var sprite:Spritemap;
    private var velocity:Vector2;
    private var bubbleSfxs:Array<Sfx>;

    public function new(x:Float, y:Float) {
        super(x, y);
        bubbleSfxs = [
            new Sfx("audio/bubblepop1.wav"),
            new Sfx("audio/bubblepop2.wav"),
            new Sfx("audio/bubblepop3.wav")
        ];
        velocity = new Vector2(0, -SPEED);
        type = "bubble";
        sprite = new Spritemap("graphics/bubble.png", 15, 15);
        setHitbox(15, 15);
        sprite.add("idle", [0]);
        sprite.play("idle");
        setGraphic(sprite);
    }

    override public function update() {
        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
            ["walls", "arrow"]
        );
        super.update();
    }

    public function pop() {
        var player = cast(scene.getInstance("player"), Player);
        var bubbleVolume = (1 - Math.min(
            distanceFrom(player, true), SFX_DISTANCE
        ) / SFX_DISTANCE);
        bubbleSfxs[HXP.choose(0, 1, 2)].play(bubbleVolume * 2);
        scene.remove(this);
    }

    public override function moveCollideY(e:Entity) {
        pop();
        return true;
    }

    override public function takeHit(arrow:Arrow) {
        if(arrow.isScattered) {
            detachArrows();
            return;
        }
        pop();
        var arrows = detachArrows();
    }
}

