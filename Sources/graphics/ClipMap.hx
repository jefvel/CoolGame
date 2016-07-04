package graphics;

import PerlinNoise;
import graphics.FreeCam;

import haxe.ds.Vector;

import kha.graphics4.VertexStructure;
import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexData;
import kha.graphics4.Usage;
import kha.Shaders;
import kha.Image;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFormat;
import kha.graphics4.TextureFilter;
import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;

import kha.math.FastMatrix4;
import kha.math.FastVector3;

typedef BufferIndexPair = {
    verts:VertexBuffer,
    indices:IndexBuffer
};

typedef ClipMapLevelParams = {
    worldOriginX:Int,
    worldOriginY:Int
};

class ClipMap {
    var noise:PerlinNoise;
    var pipeline:PipelineState;
    var structure:VertexStructure;
    
    var levelColors = [
        kha.Color.fromFloats(0.34, 0.34, 0.34),
        kha.Color.Green, 
        kha.Color.Red, 
        kha.Color.Blue,
        kha.Color.Orange];
        
    var levels:Int = 4;
    var m:Int = 32;
    var n:Int;
    
    var finestDetailSize:Float = 0.1;
    
    //Vertex and index buffers for parts of clipmap
    var lVerts:VertexBuffer;
    var lIndices:IndexBuffer;
    
    var invLVerts:VertexBuffer;
    var invLIndices:IndexBuffer;
    
    var squareVerts:VertexBuffer;
    var squareIndices:IndexBuffer;
    
    var horizontalFixupVerts:VertexBuffer;
    var horizontalFixupIndices:IndexBuffer;
    
    var verticalFixupVerts:VertexBuffer;
    var verticalFixupIndices:IndexBuffer;
    
    var centerVerts:VertexBuffer;
    var centerIndices:IndexBuffer;

    var outerRing:VertexBuffer;
    var outerRingIndices:IndexBuffer;
    
    var nLocation:ConstantLocation;
    var colorLocation:ConstantLocation;
    var offsetLocation:ConstantLocation;
    var originLocation:ConstantLocation;
    var scaleLocation:ConstantLocation;
    var mvpLocation:ConstantLocation;
    var levelLocation:ConstantLocation;

    var timeLocation:ConstantLocation;
    var time:Float;
    
    var totalWidthLocation:ConstantLocation;
    var textureOffsetLocation:ConstantLocation;
    
    //var heightMapUnits:Vector<TextureUnit>;
    var textureUnit:TextureUnit;
    
    var textures:Vector<Image>;

    var mvp:FastMatrix4;
    var startTime:Float;
    
    var cam:FreeCam;
    var texWidth:Int;
    
	public function new() {
        cam = new FreeCam();
        cam.pos.y = 3.0;
        noise = new PerlinNoise();
        
        startTime = haxe.Timer.stamp();
        
		structure = new VertexStructure();
        structure.add("pos", VertexData.Float2);
        
        pipeline = new PipelineState();
        pipeline.inputLayout = [structure];
        pipeline.fragmentShader = Shaders.default_frag;
        pipeline.vertexShader = Shaders.default_vert;
        
        pipeline.depthWrite = true;
        pipeline.depthMode = kha.graphics4.CompareMode.LessEqual;
        
        pipeline.compile();
        
        n = (m - 1) * 4 + 3;
        
        texWidth = n + 1;
        colorLocation = pipeline.getConstantLocation("color");
        originLocation = pipeline.getConstantLocation("origin");
        offsetLocation = pipeline.getConstantLocation("offset");
        scaleLocation = pipeline.getConstantLocation("scale");
        mvpLocation = pipeline.getConstantLocation("MVP");
        totalWidthLocation = pipeline.getConstantLocation("totalWidth");
        textureOffsetLocation = pipeline.getConstantLocation("textureOffset");
        timeLocation = pipeline.getConstantLocation("time");
        levelLocation = pipeline.getConstantLocation("level");
        nLocation = pipeline.getConstantLocation("n");
        
        kha.Scheduler.addFrameTask(function(){
            time = haxe.Timer.stamp() - startTime;
        }, 0);
           
        textures = new Vector<Image>(levels);
        //heightMapUnits = new Vector<TextureUnit>(levels);
        
        for(i in 0...levels) {
            textures[i] = Image.create(texWidth, texWidth,
            TextureFormat.L8,//kha.graphics4.TextureFormat.A32,
            Usage.DynamicUsage);    
            //heightMapUnits[i] = pipeline.getTextureUnit("heightMap" + i);
        }
        
        textureUnit = pipeline.getTextureUnit("heightMaps");
        
        var a = kha.ScreenCanvas.the.height / kha.ScreenCanvas.the.width;
        mvp = FastMatrix4.perspectiveProjection(90.0, a, 0.0001, 100.0);
        
        generateBuffers();
        
        updateTextures();
    }
    
    function generateSquareBuffer(){
        var v = generateRectangularBuffer(m, m);
        squareVerts = v.verts;
        squareIndices = v.indices;
        
        v = generateRectangularBuffer(3, m);
        horizontalFixupVerts = v.verts;
        horizontalFixupIndices = v.indices;
        
        v = generateRectangularBuffer(m, 3);
        verticalFixupVerts = v.verts;
        verticalFixupIndices = v.indices;
        
        v = generateRectangularBuffer(m * 2, m * 2);
        centerVerts = v.verts;
        centerIndices = v.indices;   
    }
    
    function generateBuffers() {
        generateSquareBuffer();
        
        //L shape.
        lVerts = new VertexBuffer(((m * 2 + 1) * 4 - 2),
            structure,
            Usage.StaticUsage);
        
        lIndices = new IndexBuffer((m * 4 - 1) * 6,
            Usage.StaticUsage);
        
        var i = 0;
        var vs = lVerts.lock();
        
        //Generate vertical line
        for(y in 0...(m * 2 + 1)){    
            for(x in 0...2) {
                vs.set(i++, x);
                vs.set(i++, y);
            }
        }
        
        var sy = m * 2 - 1;    
        //Generate horizontal line
        for(x in 1...(m * 2 +1)) {
            for(y in 0...2) {
                vs.set(i++, x);
                vs.set(i++, y + sy);
            }
        }
       
        lVerts.unlock();
        
        var indices = lIndices.lock();
        
        var si  = 0; //StartIndex
        var vsi = 0; //VertexArrayStartIndex
        
        for(i in 0...(m * 4) + 1) {
            si = i * 6;
            
            vsi = i * 2;
            if(i >= (m * 2)) {
                vsi += 2;
            }
            
            indices[si++] = vsi;
            indices[si++] = vsi + 2;
            indices[si++] = vsi + 1;
           
            indices[si++] = vsi + 1;
            indices[si++] = vsi + 2;
            indices[si++] = vsi + 3;
        }
        lIndices.unlock();
        
        //Inverted L shape.
        invLVerts = new VertexBuffer(((m * 2 + 1) * 4 - 2),
            structure,
            Usage.StaticUsage);
        
        invLIndices = new IndexBuffer((m * 4 - 1) * 6,
            Usage.StaticUsage);
        
        var i = 0;
        var vs = invLVerts.lock();
        
        //Generate vertical line
        for(y in 0...(m * 2 + 1)){    
            for(x in 0...2) {
                vs.set(i++, (m * 2 - 1) + x);
                vs.set(i++, y);
            }
        }
            
        //Generate horizontal line
        for(x in 0...(m * 2)) {
            for(y in 0...2) {
                vs.set(i++, x);
                vs.set(i++, y);
            }
        }
       
        invLVerts.unlock();
        
        var indices = invLIndices.lock();
        
        var si  = 0; //StartIndex
        var vsi = 0; //VertexArrayStartIndex
        
        for(i in 0...(m * 4) + 1) {
            si = i * 6;
            
            vsi = i * 2;
            if(i >= (m * 2)) {
                vsi += 2;
            }
            
            indices[si++] = vsi;
            indices[si++] = vsi + 2;
            indices[si++] = vsi + 1;
            
            indices[si++] = vsi + 1;
            indices[si++] = vsi + 2;
            indices[si++] = vsi + 3;
        }
        
        invLIndices.unlock();
        
        outerRing = new VertexBuffer((n * 4 * 2),
            structure,
            Usage.StaticUsage);
            
        outerRingIndices = new IndexBuffer((n - 1) * 4 * 3, Usage.StaticUsage);
        
        var indices = outerRingIndices.lock();
        var verts = outerRing.lock();
        var ci = 0;
        
        for(i in 0...indices.length) indices[i] = 0;
        
        for(i in 0...n) {
            verts.set(ci++, i);
            verts.set(ci++, 0.0);
            
            if(i < n - 1) {
                verts.set(ci++, i + 0.01);
                verts.set(ci++, 0.01);
                
                indices[i * 3] = (i * 2);
                indices[i * 3 + 1] = (i * 2) + 2;
                indices[i * 3 + 2] = (i * 2) + 1;
            }   
        }
        
        for(i in 0...n) {
            verts.set(ci++, i);
            verts.set(ci++, n - 1.0);
            
            if(i < n - 1) {
                verts.set(ci++, i + 0.01);
                verts.set(ci++, n - 1.0 + 0.01);
                
                indices[(n + i + 1) * 3] = ((n + i) * 2) + 1;
                indices[(n + i + 1) * 3 + 1] = ((n + i) * 2) + 3;
                indices[(n + i + 1) * 3 + 2] = ((n + i) * 2) + 2;
            }   
        }
        
        for(i in 0...n) {
            verts.set(ci++, n - 1.0);
            verts.set(ci++, i);
            
            if(i < n - 1) {
                verts.set(ci++, n - 1.0 + 0.01);
                verts.set(ci++, i + 0.01);
                
                indices[(n*2 + i + 1) * 3]     = ((n *2+ i) * 2) + 2;
                indices[(n*2 + i + 1) * 3 + 1] = ((n*2 + i) * 2) + 4;
                indices[(n*2 + i + 1) * 3 + 2] = ((n*2 + i) * 2) + 3;
            }   
        }
        
        
        for(i in 0...n) {
            verts.set(ci++, .0);
            verts.set(ci++, i);
            
            if(i < n - 1) {
                verts.set(ci++, 0.01);
                verts.set(ci++, i + 0.01);
                
                indices[(n*3 + i + 1) * 3]     = ((n *3+ i) * 2) + 3;
                indices[(n*3 + i + 1) * 3 + 1] = ((n*3 + i) * 2) + 5;
                indices[(n*3 + i + 1) * 3 + 2] = ((n*3 + i) * 2) + 4;
            }   
        }
        
        outerRing.unlock();
        outerRingIndices.unlock();
    }
    
    var originX = 0.0;
    var originY = 0.0;
    
    function startLevels() {
        originX = -(m * 2 - 1);
        originY = -(m * 2 - 1);
    }
        
    function renderLevel(level:Int, g:kha.graphics4.Graphics) {
        g.setInt(levelLocation, level);
        g.setTexture(textureUnit, textures[level]);    
        
        g.setTextureParameters(textureUnit,
            TextureAddressing.Repeat,
            TextureAddressing.Repeat,
            TextureFilter.PointFilter,
            TextureFilter.PointFilter,
            kha.graphics4.MipMapFilter.NoMipFilter
        );

        var color = levelColors[level % levelColors.length];
        g.setFloat3(colorLocation, color.R, color.G, color.B);
        
        var sm = 1 << level;
        var s = finestDetailSize;
    
        var cellSize = sm * s;
        
        g.setFloat(scaleLocation, cellSize);
        g.setFloat2(originLocation, 
            (originX) * cellSize, 
            (originY) * cellSize);
                 
        //Draw center thing
        if(level == 0) {
            g.setFloat2(offsetLocation,
                (originX + m) * s, 
                (originY + m - 1) * s);
            
            g.setVertexBuffer(centerVerts);
            g.setIndexBuffer(centerIndices);
            g.drawIndexedVertices();
        }
               
        //Level has a "L" piece
        if(level % 2 == 0) {
            if(level != 0){
                originX = originX * 0.5 - (m);
                originY = originY * 0.5 - (m - 1);
            }
            
            g.setVertexBuffer(lVerts);
            g.setIndexBuffer(lIndices);
            
        }else //Level has an inverse "L" piece
        {
            if(level != 0){
                originX = originX * 0.5 - (m - 1);
                originY = originY * 0.5 - (m);
            }
            
            g.setVertexBuffer(invLVerts);
            g.setIndexBuffer(invLIndices);
        }
        
        g.setFloat2(originLocation, 
            (originX) * cellSize, 
            (originY) * cellSize);
        
        //Draw L/Inverted L  
        g.setFloat2(offsetLocation, 
            (originX + m - 1) * cellSize, 
            (originY + m - 1) * cellSize);
        g.drawIndexedVertices();
        
        //Draw outer degenerates
        g.setFloat2(offsetLocation, originX * cellSize, originY * cellSize);
        g.setVertexBuffer(outerRing);
        g.setIndexBuffer(outerRingIndices);
        g.drawIndexedVertices();
      
        //Draw main ring
        g.setVertexBuffer(squareVerts);
        g.setIndexBuffer(squareIndices);
        
        var bs = m - 1;
        var ox = 0;
        
        //Draw top and bottom row
        for(x in 0...4) {
            if(x > 1) {
                ox = 2;
            }
            
            g.setFloat2(offsetLocation, 
                (originX + x * bs + ox) * cellSize, 
                (originY) * cellSize);
                
            g.drawIndexedVertices();
            
            g.setFloat2(offsetLocation, 
                (originX + x * bs + ox) * cellSize, 
                (originY + (m - 1) * 3 + 2) * cellSize);
                
            g.drawIndexedVertices();
        }
        
        ox = 0;
        
        //Draw left and right column 
        for(x in 1...3) {
            if(x > 1) {
                ox = 2;
            }
            
            g.setFloat2(offsetLocation, 
                (originX) * cellSize, 
                (originY + x * bs + ox) * cellSize);
            g.drawIndexedVertices();
        
            g.setFloat2(offsetLocation, 
                (originX + (m - 1) * 3 + 2) * cellSize, 
                (originY + x * bs + ox) * cellSize);
            g.drawIndexedVertices();
        }
        
        //Horizontal fixup pieces
        g.setVertexBuffer(horizontalFixupVerts);
        g.setIndexBuffer(horizontalFixupIndices);
        
        g.setFloat2(offsetLocation, 
                (originX + (m - 1) * 2) * cellSize, 
                (originY) * cellSize);
        g.drawIndexedVertices();
        g.setFloat2(offsetLocation, 
                (originX + (m - 1) * 2) * cellSize, 
                (originY + (m - 1) * 3 + 2) * cellSize);
        g.drawIndexedVertices();
        
        //Vertical fixup pieces
        g.setVertexBuffer(verticalFixupVerts);
        g.setIndexBuffer(verticalFixupIndices);
        
        g.setFloat2(offsetLocation, 
                (originX) * cellSize,
                (originY + (m - 1) * 2) * cellSize);
        g.drawIndexedVertices();
        g.setFloat2(offsetLocation, 
                (originX + (m - 1) * 3 + 2) * cellSize,
                (originY + (m - 1) * 2) * cellSize);
        g.drawIndexedVertices();
        
    }
    
    function worldHeight(wx:Float, wz:Float):Float {
        wx *= 0.3;
        wz *= 0.3;
        return noise.noise2D(wx, wz) * Math.max(0.001, Math.min(1.0, Math.sqrt(wx * wx + wz * wz) * 0.01));
    }
    
    function updateTextures() {
        var cellSize = 1.0;
        
        var originX = -(n - 1) * 0.5;
        var originY = -(n - 1) * 0.5;
        
        originX = 0;
        originY = 0;
        
        var level = 0;
         
        for(texture in textures) {
            
            var pixels = texture.lock();
            var multiplier = 1;
            
            multiplier = 1;
            
            trace(pixels.length);
            
            for(x in 0...texWidth) {
                for(y in 0...texWidth) {
                    var wx = x * cellSize + originX;
                    var wy = y * cellSize + originY;
       
                    var i = x * texWidth + y;
                    var h = 0.5 * (
                        Math.cos(wx * 0.2) + 
                        Math.sin(wy * 0.2));
                    h = worldHeight(wx, wy);
                    /*h = 0.0;
                    
                    if(x == 0 && y == 0) {
                        h = 1.0;
                    }
                    
                    if(x == 0 || y == 0) {
                    //    h = 1.0;
                    }
                     
                    if(x == n - 1 || y == n - 1) {
                    //    h = 1.0;
                    }
                    
                    if(x == texWidth - 1 && y == texWidth - 1) {
                        h = 1.0;
                    }
                    */
                    /*
                    var ss = 100.0;
                    if(wx % ss > ss * 0.5) {
                        if(wy % ss > ss * 0.5) {
                            h = 1.0;
                        }
                    }
                    */
                    //h /= 8.0;
                    //if(pixels.length > i * multiplier + multiplier) {
                    pixels.set(i, Std.int(h * 0xff));
                    //pixels.setFloat(x * multiplier, h);
                    //}
                }
            }
          
            texture.unlock();
            
            cellSize *= 2.0;
            
            level ++;
            if(level % 2 == 0) {
                originX = originX - (m - 1) * cellSize;
                originY = originY - (m) * cellSize;
            } else {    
                originX = originX - (m) * cellSize;
                originY = originY - (m - 1) * cellSize;
            }
        }
        
  /*
        for(i in 0...pixels.length) {
                //var h = Math.cos(x * 0.1) + Math.sin(y * 0.1);
      //
        //        pixels.set((x * n + y) * 4 + 3, 0xff);
          //      pixels.set((x * n + y) * 4 + 4, 0xff);
            //    pixels.set((x * n + y) * 4 + 6, 0xff);
              
              pixels.set(i, 0xff);  
                //pixels.setFloat((x * n + y) * 4 + 1, 1.0);
            }
       // }
    */    
    }
    
    var o = 0.0;
    public function render(buf:kha.Framebuffer) {
        /*
        cam.pos.y = Math.max(
            worldHeight(
                cam.pos.x / finestDetailSize, 
                cam.pos.z / finestDetailSize) * 50.0 + 0.5, 
                cam.pos.y);
        */
        cam.update();
        
        var g4 = buf.g4;
       
        g4.setPipeline(pipeline);
        g4.setFloat(nLocation, n);
        g4.setFloat(timeLocation, time);
        g4.setFloat2(textureOffsetLocation, o, o);
        g4.setFloat(totalWidthLocation, texWidth);
        g4.setFloat2(offsetLocation, 0.0, 0.0);
        
        //Camera things
        var a = buf.width / buf.height;
        mvp = FastMatrix4.perspectiveProjection(90.0, a, 0.001, 1000.0);
        var camMat = cam.matrix;  
        camMat = mvp.multmat(camMat);
        
        g4.setMatrix(mvpLocation, camMat);
        
        g4.begin();
        g4.clear(kha.Color.fromFloats(0.74, 0.74, 0.74), 1.0);
            
        startLevels();
        for(level in 0...levels) {
            renderLevel(level, g4);
        }
        
        g4.end();
    }
    
    
    inline function squareIndex(x:Int, y:Int, w:Int, h:Int):Int {
        return x * h + y;
    }
    
    function generateRectangularBuffer(_x:Int, _y:Int):BufferIndexPair {
        var squareVerts = new VertexBuffer(_x * _y, 
            structure, 
            Usage.StaticUsage);
        var squareIndices = new IndexBuffer(
            (_x - 1) * (_y - 1) * 3 * 2, 
            Usage.StaticUsage);
         
        //Generate verts
        var i = 0;
        var verts = squareVerts.lock();   
        for(x in 0..._x) {
            for(y in 0..._y) {
                verts.set(i++, x);
                verts.set(i++, y);
            }
        }
        squareVerts.unlock();
        
        i = 0;
        var indices = squareIndices.lock();
        for(x in 0...(_x - 1)) {
            for(y in 0...(_y - 1)) {
                indices[i++] = squareIndex(x + 0, y + 0, _x, _y);
                indices[i++] = squareIndex(x + 0, y + 1, _x, _y);
                indices[i++] = squareIndex(x + 1, y + 0, _x, _y);
                          
                //continue;
                
                indices[i++] = squareIndex(x + 1, y + 0, _x, _y);
                indices[i++] = squareIndex(x + 0, y + 1, _x, _y);
                indices[i++] = squareIndex(x + 1, y + 1, _x, _y); 
            }
        }
        
        squareIndices.unlock();
        
        return {
            verts : squareVerts,
            indices : squareIndices
        };
    }
}