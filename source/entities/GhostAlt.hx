package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;

class GhostAlt extends MemoryEntity {
    public static inline var ACCEL = 0.03;
    //public static inline var MAX_SPEED = 1.8;
    //public static inline var MAX_SPEED_PHASED = 0.9;
    public static inline var MAX_SPEED = 2.2;
    public static inline var MAX_SPEED_PHASED = 1.3;
    public static inline var HIT_KNOCKBACK = 5;
    public static inline var ACTIVATE_DISTANCE = 200;
    public static inline var HUM_DISTANCE = 200;
    public static inline var BOB_AMOUNT = 2.8;
    public static inline var BOB_SPEED = 1.5;

    private var sprite:Spritemap;
    private var velocity:Vector2;
    private var isActive:Bool;
    private var hum:Sfx;
    private var hitSfx:Sfx;
    private var bob:NumTween;

    public function new(x:Float, y:Float) {
        super(x, y);
        MemoryEntity.loadSfx(["ghosthit1", "ghosthit2", "ghosthit3"]);
        type = "ghost";
        sprite = new Spritemap("graphics/ghostalt.png", 30, 30);
        sprite.add("idle", [0, 1], 6);
        sprite.add("phasing", [2, 3], 6);
        sprite.play("idle");
        setGraphic(sprite);
        velocity = new Vector2(0, 0);
        setHitbox(30, 30);
        isActive = false;
        hum = new Sfx("audio/ghostalt.wav");
        hum.volume = 0;
        health = 1;
        bob = new NumTween(TweenType.PingPong);
        if(Math.random() > 0.5) {
            bob.tween(BOB_AMOUNT, -BOB_AMOUNT, BOB_SPEED, Ease.sineInOut);
        }
        else {
            bob.tween(-BOB_AMOUNT, BOB_AMOUNT, BOB_SPEED, Ease.sineInOut);
        }
        addTween(bob, true);
    }

    override public function stopSound() {
        hum.stop();
    }

    override public function update() {
        var player = scene.getInstance("player");
        var wasActive = isActive;
        if(distanceFrom(player, true) < ACTIVATE_DISTANCE) {
            isActive = true;
        }
        if(isActive && !wasActive) {
            hum.loop();
        }
        var towardsPlayer = new Vector2(
            player.centerX - centerX, player.centerY - centerY
        );
        var accel = ACCEL;
        if(distanceFrom(player, true) < 50) {
            accel *= 2;
        }
        towardsPlayer.normalize(accel * Main.getDelta());
        velocity.add(towardsPlayer);

        collidable = true;
        if(collide("walls", x, y) != null) {
            collidable = false;
        }

        var maxSpeed = collidable ? MAX_SPEED : MAX_SPEED_PHASED;
        if(velocity.length > maxSpeed) {
            velocity.normalize(maxSpeed);
        }
        if(isActive) {
            moveBy(velocity.x * Main.getDelta(), velocity.y * Main.getDelta());
            moveBy(0, bob.value);
        }
        animation();


        if(isActive) {
            hum.volume = 1 - Math.min(
                distanceFrom(player, true), HUM_DISTANCE
            ) / HUM_DISTANCE;
        }
        else {
            hum.volume = 0;
        }

        super.update();
    }

    private function animation() {
        var player = scene.getInstance("player");
        sprite.flipX = centerX > player.centerX;
        if(collidable) {
            sprite.play("idle");
        }
        else {
            sprite.play("phasing");
        }
    }

    override public function takeHit(arrow:Arrow) {
        if(arrow.isScattered) {
            detachArrows();
            return;
        }
        scene.remove(this);
        var arrows = detachArrows();
        explode();
        MemoryEntity.allSfx['ghosthit${HXP.choose(1, 2, 3)}'].play();
#if desktop
        Sys.sleep(0.02);
#end
        stopSound();
    }
}


