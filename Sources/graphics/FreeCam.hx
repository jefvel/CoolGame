package graphics;

import kha.math.FastVector3;
import kha.math.FastMatrix4;

class FreeCam {
    
    var speed:Float = 0.1;
    var mouseSensitivity:Float = Math.PI / 2160.0;
    
    public var pos:FastVector3;
    public var dir:FastVector3;
    public var up:FastVector3;
    
    var pitch:Float = 0.0;
    var yaw:Float = 0.0;
    
    var moveForward = false;
    var moveBackward = false;
    var strafeLeft = false;
    var strafeRight = false;
    
    var moveUp = false;
    var moveDown = false;
    
    var multiplier = 1.0;
    var multiplierFast = 10.0;
    public var matrix(get, null):FastMatrix4;
    var mDown = false;
    
    public function new() {
        up = new FastVector3(0.0, 1.0, 0.0);
        pos = new FastVector3(0.0, 0.1, 0.0);
        dir = new FastVector3(0, 0, 1.0);
        
        yaw = Math.PI * 0.25;
    
        updateDir();
        
        //kha.SystemImpl.lockMouse();
        
        kha.input.Mouse.get().notify(
        function(button, x, y) {
            mDown = true;
            kha.SystemImpl.lockMouse();
        }, function(button, x, y) {
            mDown = false;
            kha.SystemImpl.unlockMouse();
        }, 
        function(x, y, dx, dy) {
            if(mDown) {
                yaw += -dx * mouseSensitivity;
                yaw = yaw % (Math.PI * 2.0);
                
                pitch += -dy * mouseSensitivity;
                pitch = clamp(pitch, -Math.PI * 0.5 + 0.001, Math.PI * 0.5- 0.001);
            
                updateDir();  
            }  
         }, null);
        
        kha.input.Keyboard.get().notify(function(key:kha.Key, v:String) {
            if(key == kha.Key.SHIFT) {
                multiplier = multiplierFast;
            }
           
            if(key == kha.Key.CTRL) {
                moveDown = true;
            }
            
            switch(v.toLowerCase()) {
                case "w": moveForward = true;
                case "s": moveBackward = true;
                case "a": strafeLeft = true;
                case "d": strafeRight = true;
                case " ": moveUp = true;
            }
        },
        function(key:kha.Key, v:String) {
            if(key == kha.Key.SHIFT) {
                multiplier = 1.0;
            }
            
            if(key == kha.Key.CTRL) {
                moveDown = false;
            }
            
            switch(v.toLowerCase()) {
                case "w": moveForward = false;
                case "s": moveBackward = false;
                case "a": strafeLeft = false;
                case "d": strafeRight = false;
                case " ": moveUp = false;
            }
        });
    }
    
    function updateDir() {
        var ratio = Math.abs(Math.cos(pitch));
        
        dir.z = -Math.cos(yaw) * ratio;
        dir.x = -Math.sin(yaw) * ratio;
        
        dir.y = Math.sin(pitch);
    
        dir.normalize();
    }
    
    function clamp(f:Float, min:Float, max:Float):Float {
        return Math.max(min, Math.min(max, f));
    }
    
    public function update() {
        var speed = this.speed * multiplier;
        if(moveForward) {
            pos = pos.add(dir.mult(speed));
        }
        if(moveBackward){
            pos = pos.add(dir.mult(-speed));    
        }
            
        if(moveUp) {
            pos.y += speed;
        }
        
        if(moveDown) {
            pos.y -= speed;
        }
        
        if(strafeLeft) {
            pos.x += Math.sin(yaw - Math.PI * 0.5) * speed;
            pos.z += Math.cos(yaw - Math.PI * 0.5) * speed;
        }
        
        if(strafeRight) {
            pos.x -= Math.sin(yaw - Math.PI * 0.5) * speed;
            pos.z -= Math.cos(yaw - Math.PI * 0.5) * speed;
        }
    }
    
    public function get_matrix():FastMatrix4 {
        var m:FastMatrix4 = 
        FastMatrix4.rotationX(-pitch).multmat(FastMatrix4.rotationY(-yaw));
        m = m.multmat(FastMatrix4.translation(-pos.x, -pos.y, -pos.z));
        return m;
    }
}