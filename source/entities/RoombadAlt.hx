package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class RoombadAlt extends MemoryEntity {
    public static inline var IDLE_SPEED = 1.33;
    public static inline var HIT_KNOCKBACK = 5;
    public static inline var SFX_DISTANCE = 280;
    public static inline var TIME_BETWEEN_BUBBLES = 1;

    private var sprite:Spritemap;
    private var eye:Spritemap;
    private var lightning:Spritemap;
    private var velocity:Vector2;
    private var isChasing:Bool;
    private var idleSfx:Sfx;
    private var soundsStopped:Bool;
    private var bubbleTimer:Alarm;
    private var bubbleSfxs:Array<Sfx>;

    public function new(x:Float, y:Float) {
        super(x, y);
        MemoryEntity.loadSfx([
            "roombadalthit1", "roombadalthit2", "roombadalthit3"
        ]);
        bubbleSfxs = [
            new Sfx("audio/bubblespawn1.wav"),
            new Sfx("audio/bubblespawn2.wav"),
            new Sfx("audio/bubblespawn3.wav")
        ];
        type = "enemy";
        name = "roombadalt";
        sprite = new Spritemap("graphics/roombadalt.png", 24, 10);
        sprite.add("idle", [0, 1], 7);
        sprite.play("idle");
        lightning = new Spritemap("graphics/roombad.png", 24, 10);
        lightning.add("idle", [3, 4], 24);
        lightning.play("idle");
        lightning.visible = false;
        eye = new Spritemap("graphics/roombadalt.png", 24, 10);
        eye.add("idle", [2]);
        eye.play("idle");
        eye.visible = false;
        setGraphic(sprite);
        addGraphic(eye);
        addGraphic(lightning);
        velocity = new Vector2(IDLE_SPEED, 0);
        if(Random.random > 0.5) {
            velocity.x *= -1;
        }
        setHitbox(24, 10);
        health = 6;
        isChasing = false;
        idleSfx = new Sfx("audio/roombadaltidle.wav");
        idleSfx.volume = 0;
        soundsStopped = false;
        bubbleTimer = new Alarm(TIME_BETWEEN_BUBBLES, TweenType.Looping);
        bubbleTimer.onComplete.bind(function() {
            makeBubble();
        });
        addTween(bubbleTimer, true);
    }

    private function makeBubble() {
        scene.add(new Bubble(centerX - 15 / 2, y - 15));
        var player = cast(scene.getInstance("player"), Player);
        var bubbleVolume = (1 - Math.min(
            distanceFrom(player, true), SFX_DISTANCE
        ) / SFX_DISTANCE);
        bubbleSfxs[HXP.choose(0, 1, 2)].play(bubbleVolume);
    }

    override public function update() {
        var player = cast(scene.getInstance("player"), Player);
        if(velocity.x > 0) {
            velocity.x = IDLE_SPEED;
        }
        else {
            velocity.x = -IDLE_SPEED;
        }

        x += velocity.x * Main.getDelta();
        var willGoOffEdge = false;
        if(velocity.x < 0) {
            if(!isBottomLeftCornerOnGround()) {
                willGoOffEdge = true;
            }
        }
        else if(velocity.x > 0) {
            if(!isBottomRightCornerOnGround()) {
                willGoOffEdge = true;
            }
        }
        x -= velocity.x * Main.getDelta();

        if(willGoOffEdge) {
            velocity.x = -velocity.x;
        }

        moveBy(velocity.x * Main.getDelta(), 0, ["walls", "enemy"]);
        animation();

        if(!idleSfx.playing && !soundsStopped) {
            idleSfx.loop();
        }
        idleSfx.volume = (1 - Math.min(
            distanceFrom(player, true), SFX_DISTANCE
        ) / SFX_DISTANCE) / 4;

        super.update();
    }

    override public function stopSound() {
        idleSfx.stop();
        soundsStopped = true;
    }

    private function makeDustOnGround() {
        var dust:Dust;
        dust = new Dust(centerX, bottom, "slide");
        scene.add(dust);
    }

    private function animation() {
        if(velocity.x < 0) {
            sprite.flipX = false;
            lightning.flipX = false;
            eye.flipX = false;
        }
        else if(velocity.x > 0) {
            sprite.flipX = true;
            lightning.flipX = true;
            eye.flipX = true;
        }

        sprite.play("idle");
        eye.visible = isChasing;
        lightning.visible = stopFlasher.active;
    }

    public override function moveCollideX(e:Entity) {
        if(isChasing) {
            velocity.x = 0;
        }
        else {
            velocity.x = -velocity.x;
        }
        return true;
    }

    override public function takeHit(arrow:Arrow) {
        trace('playing a sound effect! really!');
        //MemoryEntity.allSfx['roombadalthit${HXP.choose(1, 2, 3)}'].play();
    }
}
