package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import scenes.*;

class BrokenBooster extends MemoryEntity {
    public static inline var DECCEL = 0.03;
    public static inline var BOOST_POWER = 4.5;
    public static inline var MAX_SPEED = 4.7;
    public static inline var HIT_KNOCKBACK = 5;
    public static inline var HUM_DISTANCE = 280;
    public static inline var SPARK_TIME = 0.4;
    public static inline var TIME_BETWEEN_SPARKS = 1;
    public static inline var TIME_BETWEEN_BOOSTS = 2;

    private var sprite:Spritemap;
    private var lightning:Spritemap;
    private var velocity:Vector2;
    private var soundsStopped:Bool;
    private var sparker:Alarm;
    private var stopSparker:Alarm;
    private var isSparking:Bool;
    private var boostSfxs:Array<Sfx>;
    private var bounceSfx:Sfx;
    private var boostTimer:Alarm;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "enemy";
        sprite = new Spritemap("graphics/booster.png", 24, 24);
        sprite.add("hit", [4]);
        sprite.play("hit");
        lightning = new Spritemap("graphics/follower.png", 24, 24);
        lightning.add("idle", [5, 6, 7], 24);
        lightning.play("idle");
        setGraphic(sprite);
        addGraphic(lightning);
        lightning.visible = false;
        velocity = new Vector2(0, 0);
        setHitbox(23, 23, -1, -1);
        soundsStopped = false;
        isSparking = false;
        sparker = new Alarm(Random.random, TweenType.Persist);
        sparker.onComplete.bind(function() {
            isSparking = !isSparking;
            if(isSparking) {
                sparker.reset(SPARK_TIME * Math.random());
                var player = scene.getInstance("player");
                var bounceVolume = 1 - Math.min(
                    distanceFrom(player, true), HUM_DISTANCE
                ) / HUM_DISTANCE;
                MemoryEntity.allSfx['robothit${HXP.choose(1, 2, 3)}'].play(
                    bounceVolume
                );
            }
            else {
                sparker.reset(TIME_BETWEEN_SPARKS * Math.random());
            }
        });
        addTween(sparker, true);
        bounceSfx = new Sfx("audio/bounce.wav");
        boostSfxs = [
            new Sfx("audio/brokenboost1.wav"),
            new Sfx("audio/brokenboost2.wav"),
            new Sfx("audio/brokenboost3.wav")
        ];
        boostTimer = new Alarm(TIME_BETWEEN_BOOSTS, TweenType.Persist);
        boostTimer.onComplete.bind(function() {
            boost();
            boostTimer.reset(
                TIME_BETWEEN_BOOSTS
                + (Math.random() - 0.5) * (TIME_BETWEEN_BOOSTS * 1.25)
            );
        });
        addTween(boostTimer, true);
        health = 1;
    }

    override public function stopSound() {
        soundsStopped = true;
    }

    private function boost() {
        var player = scene.getInstance("player");
        var randomDirection = new Vector2(1, 0);
        randomDirection.normalize(BOOST_POWER);
        randomDirection.rotate(Math.PI * 2 * Math.random());
        var randomPower = HXP.choose(0.5, 0.7, 0.8, 0.9, 1);
        randomDirection.scale(randomPower);
        velocity.add(randomDirection);
        var bounceVolume = 1 - Math.min(
            distanceFrom(player, true), HUM_DISTANCE * 2
        ) / (HUM_DISTANCE * 2);
        bounceVolume *= randomPower;
        boostSfxs[HXP.choose(0, 1, 2)].play(Math.min(bounceVolume * 1.4, 1));
    }

    override public function update() {
        var player = scene.getInstance("player");
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
        moveBy(
            velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
            ["walls", "enemy"]
        );
        animation();
        super.update();
    }

    private function animation() {
        var player = scene.getInstance("player");
        sprite.flipX = velocity.x > 0;
        lightning.visible = stopFlasher.active || isSparking;
    }

    public override function moveCollideX(e:Entity) {
        velocity.x = -velocity.x;
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
        velocity.y = -velocity.y;
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
        var knockback = arrow.velocity.clone();
        knockback.normalize(HIT_KNOCKBACK);
        velocity.add(knockback);
        super.takeHit(arrow);
    }
}


