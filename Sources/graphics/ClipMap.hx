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
    textureOffsetX:Int,
    textureOffsetY:Int,
    originWorldX:Int,
    originWorldY:Int,
    heightMapValues:haxe.io.Bytes,
    requiresFullUpdate:Bool,
    lastOffsetX:Int,
    lastOffsetY:Int,
    cellSize:Int
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
        kha.Color.Orange
    ];
        
    var levels:Int = 2;
    var m:Int = 32;
    var n:Int;
    
    var finestDetailSize:Float = 0.1;
    var largestDetailSize:Float;
    
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
    var levelParams:Vector<ClipMapLevelParams>;

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
        largestDetailSize = (1 << levels) * finestDetailSize;
        
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
        levelParams = new Vector<ClipMapLevelParams>(levels);
        
        for(i in 0...levels) {
            textures[i] = Image.create(texWidth, texWidth,
            TextureFormat.L8,//kha.graphics4.TextureFormat.A32,
            Usage.DynamicUsage);
            levelParams[i] = {
                textureOffsetX: 0,
                textureOffsetY: 0,
                heightMapValues:haxe.io.Bytes.alloc(texWidth * texWidth),
                requiresFullUpdate: true,
                lastOffsetX:0,
                lastOffsetY:0,
                originWorldX:0,
                originWorldY:0,
                cellSize:1 << i
            };
        }
        
        textureUnit = pipeline.getTextureUnit("heightMaps");
        
        var a = kha.ScreenCanvas.the.height / kha.ScreenCanvas.the.width;
        mvp = FastMatrix4.perspectiveProjection(90.0, a, 0.0001, 100.0);
        
        generateBuffers();
        
        centerOn(10000, 8000);
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
        
        
        //Create ring of degenerate triangles
        var ringVertCount = n * 4 - 4;
        
        outerRing = new VertexBuffer(ringVertCount * 2,
            structure,
            Usage.StaticUsage);
        
            
        outerRingIndices = new IndexBuffer((n - 1) * 4 * 3, Usage.StaticUsage);
        
        var indices = outerRingIndices.lock();
        var verts = outerRing.lock();
        var ci = 0;
        
        for(i in 0...indices.length) indices[i] = 0;
        for(i in 0...(n >> 1)) {
            verts.set(ci, i * 1);
            verts.set(ci + 1, 0.0);
            
            verts.set(ci + ringVertCount * 2, i * 1 + 0.5);
            verts.set(ci + ringVertCount * 2 + 1, 0);
            
            ci += 2;
            
            if(i < (n >> 1) - 1) {
            //if(i < n - 1 ) {
                indices[i * 3] = (i);
                indices[i * 3 + 1] = (i) + ringVertCount;
                indices[i * 3 + 2] = (i) + 1;
            }   
        }
        
        /*
        
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
        
        */
        
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
        var params = levelParams[level];
        
        g.setInt(levelLocation, level);
        g.setTexture(textureUnit, textures[level]);
        
        g.setFloat2(textureOffsetLocation, 
            params.textureOffsetX, params.textureOffsetY);
        
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
        
                
        //Draw outer degenerates
        //g.setVertexBuffer(outerRing);
        //g.setIndexBuffer(outerRingIndices);
        //g.drawIndexedVertices();
               
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
        wx *= 0.1;
        wz *= 0.1;
        //return Math.abs(Math.sin(wx) + Math.cos(wz)) * 0.4;
        return noise.noise2D(wx + 1000, wz + 1000);// * Math.max(0.001, Math.min(1.0, Math.sqrt(wx * wx + wz * wz) * 0.01));
    }
    
    function centerOn(worldX:Int, worldY:Int) {
        var originX:Int = worldX - (n >> 2);
        var originY:Int =  worldY - (n >> 2);
        
        for(level in 0...levels) {
            var params = levelParams[level];
            if(level != 0){
                if((level + 1) % 2 == 0) {
                    originX = originX - (m - 1) * params.cellSize;
                    originY = originY - (m) * params.cellSize;
                } else {    
                    originX = originX - (m) * params.cellSize;
                    originY = originY - (m - 1) * params.cellSize;
                }
            }
            
            params.originWorldX = originX;
            params.originWorldY = originY;
            
            params.textureOffsetX = 0;
            params.textureOffsetY = 0;
            
            params.requiresFullUpdate = true;   
        }
        
        updateTextures();
    }
    
    function updateTextures(refresh:Bool = false) {
        for(level in 0...levels) {
            var texture = textures[level];
            var pixels = texture.lock();
            
            var params = levelParams[level];
            
            if(params.requiresFullUpdate || true) {
                for(x in 0...texWidth) {
                    for(y in 0...texWidth) {
                        var wx:Float = ((x) * params.cellSize) + params.textureOffsetX + params.originWorldX;
                        if(x < params.textureOffsetX){
                            wx += params.cellSize * texWidth;
                        }
                        
                        
                        if(x < params.textureOffsetX) {
                            wx += texWidth * params.cellSize;
                        }
                        
                        
                        var wy:Float = ((y) * params.cellSize + params.textureOffsetX + params.originWorldY);
                        if(y < params.textureOffsetY){
                            wy += params.cellSize * texWidth;
                        }
                        
                        
                        if(y < params.textureOffsetY) {
                            wy += texWidth * params.cellSize;
                        } 
                        
                        
                        var i = y * texWidth + x;
                        var h = worldHeight(wx, wy);
                        
                        params.heightMapValues.set(i, Std.int(h * 0xff));
                    }
                }
            } else {
                var sx = params.textureOffsetX - params.lastOffsetX;
                var sy = params.textureOffsetY - params.lastOffsetY;

                if(sx != 0) {
                    var startX = params.lastOffsetX;
                    var endX = startX + Std.int(Math.abs(sx));
                                      
                    for(y in 0...texWidth){
                        for(x in 0...texWidth) { 
                            var texX = (x + params.textureOffsetX) % texWidth;
                            var texY = (y + params.textureOffsetY) % texWidth;
                            
                            if(texX > endX || texX < startX) {
                                continue;
                            }
                            
                            var wx = (x + params.textureOffsetX);
                            var wy = (y + params.textureOffsetY);
            
                            var i =  texY * texWidth + 
                                    texX;
                                    
                            var h = worldHeight(wx, wy);
                            
                            //h = 0.0;
                            
                            params.heightMapValues.set(i, Std.int(h * 0xff));
                        }
                    }
                }
                
                if(sy != 0) {
                    var startY = params.lastOffsetY;
                    var endY = startY + Std.int(Math.abs(sy));
                    
                    
                    for(y in 0...texWidth) {
                        for(x in 0...texWidth) {
                            var texX = (x + params.textureOffsetX) % texWidth;
                            var texY = (y + params.textureOffsetY) % texWidth;
                            
                            if(texY > endY || texY < startY) {
                                continue;
                            }
                            
                            var wx = (x + params.textureOffsetX);
                            var wy = (y + params.textureOffsetY);
            
                            var i =  texY * texWidth + texX;
                                    
                            var h = worldHeight(wx, wy);
                            
                            params.heightMapValues.set(i, Std.int(h * 0xff));
                        }
                    }
                }
            }
            
            params.requiresFullUpdate = false;
            
            params.lastOffsetX = params.textureOffsetX;
            params.lastOffsetY = params.textureOffsetY;
            
            pixels.blit(0, params.heightMapValues, 0, pixels.length);
    
            texture.unlock();
        }    
    }
    
    function shiftMap(x:Int, z:Int) {
        var cellShift = 1;
        worldOffsetX += x;
        worldOffsetY += z;
        
        for(i in 0...levelParams.length) {
            var l = levelParams[i];//levelParams.length - 1 - i];
         
            
            l.originWorldX += x * cellShift;
            l.originWorldY += z * cellShift;
            
            //l.textureOffsetX += x * cellShift;
            l.textureOffsetX %= texWidth;
            
            //l.textureOffsetY += z * cellShift;
            l.textureOffsetY %= texWidth;
            cellShift *= 2;
            
        }
        
        updateTextures(true);
    }
    
    var worldOffsetX = 0;
    var worldOffsetY = 0;
    
    var o = 0.0;
    public function render(g4:kha.graphics4.Graphics) {
        
        cam.pos.y = Math.max(
            worldHeight(
                cam.pos.x + largestDetailSize * worldOffsetX, 
                cam.pos.z + largestDetailSize * worldOffsetY) * 30.0 + 0.5, 
                cam.pos.y);
       
        cam.update();
        
        var shiftX = Std.int(cam.pos.x / (largestDetailSize ));
        var shiftZ = Std.int(cam.pos.z / (largestDetailSize ));
        if(shiftX != 0 || shiftZ != 0) {
            shiftMap(shiftX, shiftZ);
            cam.pos.x += -shiftX * largestDetailSize;
            cam.pos.z += -shiftZ * largestDetailSize;
        }
        
        g4.setPipeline(pipeline);
        g4.setFloat(nLocation, n);
        g4.setFloat(timeLocation, time);
        g4.setFloat(totalWidthLocation, texWidth);
        g4.setFloat2(offsetLocation, 0.0, 0.0);
        
        //Camera things
        var a = kha.ScreenCanvas.the.width / kha.ScreenCanvas.the.height;
        mvp = FastMatrix4.perspectiveProjection(90.0, a, 0.001, 1000.0);
        var camMat = cam.matrix;  
        camMat = mvp.multmat(camMat);
        
        g4.setMatrix(mvpLocation, camMat);
        
        g4.begin();
        g4.clear(kha.Color.fromFloats(0.1, 0.1, 0.1), 1.0);
            
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