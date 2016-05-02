package entity;

import kha.graphics2.Graphics;
import kha.System;
import kek.graphics.Sprite;

class Entity {
    public var tx:Float;
	public var ty:Float;
	
	public var x:Float;
    public var y:Float;
	public var id:Int;
	
	public static var sprite:Sprite;
	var local = false;
	
    public function new(id:Int, local:Bool = false){
		this.id = id;
		this.local = local;
    }

    public function update(){
    	if(!local) {
			x += (tx - x) * 0.2;
			y += (ty - y) * 0.2;
		}
	}

    public function render(g:Graphics){
		if(sprite == null){
			return;
		}
		g.color = 0xffffffff;
		
		sprite.x = x;
		sprite.y = y;
		
		sprite.draw(g);
	}
}