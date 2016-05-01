package graphics;
import kha.Image;
import kha.FastFloat;

class Sprite {
    public var graphics:Image;
    public var x:FastFloat;
    public var y:FastFloat;
    public var anchorX:FastFloat;
    public var anchorY:FastFloat;
    
    public var scale = 5.0;
    
    public function new(graphics:Image = null) {
        this.graphics = graphics;
        anchorX = anchorY = 0.5;
    }
    
    public function draw(b:kha.graphics2.Graphics) {
		var tx = x - G.camera.ox;
		var ty = y - G.camera.oy;
		
		b.drawScaledSubImage(graphics,  0, 0, 32, 32, 
		Std.int((tx - scale * 32 * anchorX) / scale) * scale, 
		Std.int((ty - scale * 32 * anchorY) / scale) * scale, 
		32 * scale, 
		32 * scale);
    }
}