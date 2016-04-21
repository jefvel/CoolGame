package entity;

import kha.graphics2.Graphics;
import kha.System;

class Line {
    public var x1:Float;
    public var x2:Float;
    public var y1:Float;
    public var y2:Float;

    public var x1Sin:Float;

    public function new(){

    }

    public function update(){
        x1 *= Math.sin(System.time * x1Sin);
    }

    public function render(graphics:Graphics){
        graphics.drawLine(x1, y1, x2, y2, 10);
    }
}