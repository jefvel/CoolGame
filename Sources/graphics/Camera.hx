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
	
	public function centerOn(x:Float, y:Float) {
		ox = x - kha.System.windowWidth() * 0.5;
		oy = y - kha.System.windowHeight() * 0.5;
	}	
}