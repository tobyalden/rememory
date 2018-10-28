package entities;

import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.math.*;
import scenes.*;

class RoboPlant extends MemoryEntity {
    public static inline var ACCEL = 0.055;
    public static inline var MAX_SPEED = 2.9;
    public static inline var ARROW_DEFLECT_FACTOR = 1.5;
    public static inline var THEME_SONG_DISTANCE = 310;

    private var themeSong:Sfx;
    private var face:Spritemap;
    private var tentacles:Spritemap;
    private var velocity:Vector2;

    public function new(x:Float, y:Float) {
        super(x, y);
        type = "roboplant";
        face = new Spritemap("graphics/roboplantface.png", 48, 46);
        face.add("evil", [0]);
        face.add("mad", [1]);
        face.add("robot", [2]);
        var faceNames = ["evil", "mad", "robot"];
        face.play(faceNames[Random.randInt(faceNames.length)]);
        tentacles = new Spritemap("graphics/roboplanttentacles.png", 48, 46);
        tentacles.add("idle", [0, 1], 12);
        tentacles.play("idle");
        setGraphic(face);
        addGraphic(tentacles);
        velocity = new Vector2(0, 0);
        setHitbox(48, 46);
        themeSong = new Sfx("audio/roboplanttheme.wav");
        themeSong.volume = 0;
        themeSong.loop();
    }

    public function stopThemeSong() {
        themeSong.stop();
    }

    override public function update() {
        var player = scene.getInstance("player");
        var towardsPlayer = new Vector2(
            player.centerX - centerX, player.centerY - centerY
        );
        var accel = ACCEL;
        if(distanceFrom(player, true) < 100) {
            accel *= 2.5;
        }
        towardsPlayer.normalize(accel * Main.getDelta());
        velocity.add(towardsPlayer);
        if(velocity.length > MAX_SPEED) {
            velocity.normalize(MAX_SPEED);
        }

        themeSong.volume = 1 - Math.min(
            distanceFrom(player, true), THEME_SONG_DISTANCE
        ) / THEME_SONG_DISTANCE;
        cast(scene, GameScene).music.volume = 1 - themeSong.volume;

        moveBy(velocity.x * Main.getDelta(), velocity.y * Main.getDelta());

        var _arrow = collide("arrow", x, y);
        if(_arrow != null && !cast(_arrow, Arrow).landed) {
            var arrow = cast(_arrow, Arrow);
            arrow.velocity.inverse();
            arrow.velocity.scale(ARROW_DEFLECT_FACTOR);
            MemoryEntity.allSfx['arrowhit${HXP.choose(1, 2, 3)}'].play(1);
        }
        super.update();
    }
}