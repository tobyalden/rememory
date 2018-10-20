package entities;

import haxepunk.*;
import haxepunk.input.*;
import haxepunk.graphics.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;

class Arrow extends MemoryEntity {
    public static inline var INITIAL_VELOCITY = 15;
    public static inline var INITIAL_LIFT = 0.1;
    public static inline var GRAVITY = 0.2;

    private var sprite:Image;
    private var velocity:Vector2;
    private var landed:Bool;
    private var isVertical:Bool;

    public function new(x:Float, y:Float, direction:Vector2, isVertical:Bool) {
	    super(x, y);
        this.isVertical = isVertical;
        type = "arrow";
        velocity = direction;
        velocity.normalize(INITIAL_VELOCITY);
        sprite = new Image("graphics/arrow.png");
        sprite.centerOrigin();
        var angle = MathUtil.angle(0, 0, velocity.x, velocity.y);
        sprite.angle = angle;
        setGraphic(sprite);
        if(isVertical) {
            setHitbox(3, 16, 1, 8);
        }
        else {
            setHitbox(16, 3, 8, 1);
        }
        landed = false;
    }

    public override function update() {
        if(!landed) {
            var gravity = GRAVITY * Main.getDelta();
            if(isVertical) {
                gravity *= 3;
            }
            velocity.y += gravity;
            var angle = MathUtil.angle(0, 0, velocity.x, velocity.y);
            sprite.angle = angle;
            moveBy(
                velocity.x * Main.getDelta(), velocity.y * Main.getDelta(),
                "walls", true
            );
        }
        super.update();
    }

    public override function moveCollideX(e:Entity) {
        landed = true;
        return true;
    }

    public override function moveCollideY(e:Entity) {
        landed = true;
        return true;
    }
}