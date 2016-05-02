package graphics;
import kha.Image;
import kha.FastFloat;

class Sprite {
    public var graphics:Image;
    public var x:FastFloat;
    public var y:FastFloat;
    public var anchorX:FastFloat;
    public var anchorY:FastFloat;
    
    public var scale = 2.0;
    
    public var width:Int;
    public var height:Int;
    
    public function new(graphics:Image = null) {
        if(graphics != null){
            loadGraphics(graphics);
        }
        
        anchorX = anchorY = 0.5;
    }
    
    public function loadGraphics(graphics:Image, width:Int = 0, height:Int = 0) {
        this.graphics = graphics;
        
        if(width != 0){
            this.width = width;
        }else{
            this.width = graphics.width;
        }
        
        if(height != 0){
            this.height = height;
        }else{
            this.height = graphics.height;
        }
    }
    
    public function draw(b:kha.graphics2.Graphics) {
		var tx = x - G.camera.ox;
		var ty = y - G.camera.oy;
		
		b.drawScaledSubImage(graphics,  0, 0, width, height,
		Std.int((tx - scale * width * anchorX) / scale) * scale, 
		Std.int((ty - scale * height * anchorY) / scale) * scale, 
		width * scale, 
		height * scale);
    }
}