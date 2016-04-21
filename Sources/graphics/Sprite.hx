package graphics;
import kha.Image;
import kha.FastFloat;

class Sprite {
    public var graphics:Image;
    public var x:FastFloat;
    public var y:FastFloat;
    
    public function new(graphics:Image = null) {
        this.graphics = graphics;
    }
    
    public function draw(b:kha.Framebuffer) {
        if(graphics != null){
            b.g2.drawScaledSubImage(graphics,  0, 0, 32, 32, x, y, 64, 64);
        }
    }
}