package graphics;

class Camera {
	public var ox:Float = 0;
	public var oy:Float = 0;
	
	public function new(){
		
	}
	
	public function screenToWorld(x:Float, y:Float) {
		return {
			x: x + ox,
			y: y + oy	
		};
	}
	
	public function moveTowards(x:Float, y:Float) {
		var dx = x - kha.System.windowWidth() * 0.5;
		var dy = y - kha.System.windowHeight() * 0.5;
		dx -= ox;
		dy -= oy;
		dx *= 0.1;
		dy *= 0.1;
		
		ox += dx;
		oy += dy;
		
	}
	
	public function centerOn(x:Float, y:Float) {
		ox = x - kha.System.windowWidth() * 0.5;
		oy = y - kha.System.windowHeight() * 0.5;
	}	
}