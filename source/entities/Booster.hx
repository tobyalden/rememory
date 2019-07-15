package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class Booster extends MemoryEntity {
    public static inline var DECCEL = 0.03;
    public static inline var BOOST_POWER = 4.5;
    public static inline var MAX_SPEED = 4.7;
    public static inline var BOUNCE_FACTOR = 0.85;
    public static inline var HIT_KNOCKBACK = 3;
    //public static inline var ACTIVATE_DISTANCE = 150;
    public static inline var ACTIVATE_DISTANCE = 2;
    public static inline var HUM_DISTANCE = 280;
    public static inline var TIME_BETWEEN_BOOSTS = 2;

    private var sprite:Spritemap;
    private var lightning:Spritemap;
    private var velocity:Vector2;
    private var isActive:Bool;
    private var boostSfxs:Array<Sfx>;
    private var bounceSfx:Sfx;
    private var boostTimer:Alarm;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        sprite = new Spritemap("graphics/booster.png", 24, 24);
        sprite.add("idle", [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ], 24);
        sprite.add("chasing", [3]);
        sprite.add("hit", [4]);
        sprite.play("idle");
        lightning = new Spritemap("graphics/follower.png", 24, 24);
        lightning.add("idle", [5, 6, 7], 24);
        lightning.play("idle");
        setGraphic(sprite);
        addGraphic(lightning);
        lightning.visible = false;
        velocity = new Vector2(0, 0);
        setHitbox(23, 23, -1, -1);
        isActive = false;
        bounceSfx = new Sfx("audio/bounce.wav");
        boostSfxs = [
            new Sfx("audio/boost1.wav"),
            new Sfx("audio/boost2.wav"),
            new Sfx("audio/boost3.wav")
        ];
        boostTimer = new Alarm(TIME_BETWEEN_BOOSTS, TweenType.Looping);
        boostTimer.onComplete.bind(function() {
            boost();
        });
        addTween(boostTimer);
        health = 2;
    }

    override public function stopSound() {
    }

    private function boost() {
        var player = scene.getInstance("player");
        var towardsPlayer = new Vector2(
            player.centerX - centerX, player.centerY - centerY
        );
        towardsPlayer.normalize(BOOST_POWER);
        velocity.add(towardsPlayer);
        var bounceVolume = 1 - Math.min(
            distanceFrom(player, true), HUM_DISTANCE * 2
        ) / (HUM_DISTANCE * 2);
        boostSfxs[HXP.choose(0, 1, 2)].play(Math.min(bounceVolume * 1.4, 1));
    }

    override public function update() {
        var player = scene.getInstance("player");
        var wasActive = isActive;
        if(distanceFrom(player, true) < ACTIVATE_DISTANCE) {
            isActive = true;
        }
        if(isActive && !wasActive) {
            boost();
            boostTimer.start();
        }

        if(velocity.length > MAX_SPEED) {
            velocity.normalize(MAX_SPEED);
        }
        var deccelAmount = DECCEL * Main.getDelta();
        if(velocity.length > deccelAmount) {
            velocity.normalize(velocity.length - deccelAmount);
        } 
        else {
            velocity.normalize(0);
        }

        if(isActive) {
            moveBy(
                velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
                ["walls", "enemy"]
            );
        }
        animation();
        super.update();
    }

    private function animation() {
        var player = scene.getInstance("player");
        sprite.flipX = centerX < player.centerX;
        if(stopFlasher.active) {
            sprite.play("hit");
        }
        else if(isActive) {
            sprite.play("chasing");
        }
        else {
            sprite.play("idle");
        }
        lightning.visible = stopFlasher.active;
    }

    public override function moveCollideX(e:Entity) {
        velocity.x = -velocity.x * BOUNCE_FACTOR;
        var player = scene.getInstance("player");
        var bounceVolume = 1 - Math.min(
            distanceFrom(player, true), HUM_DISTANCE
        ) / HUM_DISTANCE;
        if(isOnScreen()) {
            bounceSfx.play(Math.min(bounceVolume * 2, 1));
        }
        return true;
    }

    public override function moveCollideY(e:Entity) {
        velocity.y = -velocity.y * BOUNCE_FACTOR;
        var player = scene.getInstance("player");
        var bounceVolume = 1 - Math.min(
            distanceFrom(player, true), HUM_DISTANCE
        ) / HUM_DISTANCE;
        if(isOnScreen()) {
            bounceSfx.play(Math.min(bounceVolume * 2, 1));
        }
        return true;
    }

    override public function takeHit(arrow:Arrow) {
        if(!arrow.isScattered) {
            isActive = true;
            if(!boostTimer.active) {
                boostTimer.start();
            }
            var knockback = arrow.velocity.clone();
            knockback.normalize(HIT_KNOCKBACK);
            velocity.add(knockback);
        }
        super.takeHit(arrow);
    }
}

