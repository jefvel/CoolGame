package graphics;

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
                          
          //      continue;
                
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
    
    var pipeline:PipelineState;
    var structure:VertexStructure;
    
    var levelColors = [
        kha.Color.fromFloats(0.34, 0.34, 0.34),
        kha.Color.Green, 
        kha.Color.Red, 
        kha.Color.Blue,
        kha.Color.Orange];
        
    var levels:Int = 2;
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
    
    var colorLocation:kha.graphics4.ConstantLocation;
    var offsetLocation:kha.graphics4.ConstantLocation;
    var originLocation:ConstantLocation;
    var scaleLocation:kha.graphics4.ConstantLocation;
    var mvpLocation:kha.graphics4.ConstantLocation;

    var totalWidthLocation:ConstantLocation;
    var textureOffsetLocation:ConstantLocation;
    
    var textureUnit:TextureUnit;
    
    var texture:Image;
    var textures:Vector<Image>;

    var mvp:FastMatrix4;

	public function new() {
		structure = new VertexStructure();
        structure.add("pos", VertexData.Float2);
        
        pipeline = new PipelineState();
        pipeline.inputLayout = [structure];
        pipeline.fragmentShader = Shaders.default_frag;
        pipeline.vertexShader = Shaders.default_vert;
        
        pipeline.depthWrite = true;
        pipeline.depthMode = kha.graphics4.CompareMode.Less;
        
        pipeline.compile();
        
        n = (m - 1) * 4 + 4;
        
        colorLocation = pipeline.getConstantLocation("color");
        originLocation = pipeline.getConstantLocation("origin");
        offsetLocation = pipeline.getConstantLocation("offset");
        scaleLocation = pipeline.getConstantLocation("scale");
        mvpLocation = pipeline.getConstantLocation("MVP");
        totalWidthLocation = pipeline.getConstantLocation("totalWidth");
        textureOffsetLocation = pipeline.getConstantLocation("textureOffset");
        
        texture = Image.create(n , n , 
            kha.graphics4.TextureFormat.A32,
            Usage.DynamicUsage);
        
        textures = new Vector<Image>(levels);
        
        for(i in 0...levels) {
            textures[i] = Image.create(n, n,
            kha.graphics4.TextureFormat.A32,
            Usage.DynamicUsage);    
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
    }
    
    
    var originX = 0.0;
    var originY = 0.0;
        
    function renderLevel(level:Int, g:kha.graphics4.Graphics) {
        var color = levelColors[level % levelColors.length];
        
        g.setTexture(textureUnit, textures[level]);    
        g.setTextureParameters(textureUnit, 
            TextureAddressing.Repeat,
            TextureAddressing.Repeat,
            TextureFilter.PointFilter,
            TextureFilter.PointFilter,
            kha.graphics4.MipMapFilter.NoMipFilter
        );
        
        g.setFloat3(colorLocation, color.R, color.G, color.B);
        
        var sm = 1 << level;
        var s = finestDetailSize;
    
        var cellSize = sm * s;
        
        g.setFloat2(originLocation, 
            (originX) * cellSize, 
            (originY) * cellSize);
                
        g.setFloat(scaleLocation, cellSize);
        
        //Draw center thing
        if(level == 0) {
            originX = -(m * 2 - 1);
            originY = -(m * 2 - 1);
            
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
    
    function updateTextures() {
        var cellSize = 1.0;
        
        for(texture in textures) {
            var pixels = texture.lock();

            for(x in 0...n) {
                for(y in 0...n) {
                    var wx = x * cellSize;
                    var wy = y * cellSize;
                    
                    var h = Math.cos(wx * 0.1) + Math.sin(wy * 0.1);
                    pixels.setFloat((x * n + y) * 4, h);
                }
            }
            
            texture.unlock();
            cellSize *= 2.0;
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
        var g4 = buf.g4;
       
        g4.setPipeline(pipeline);
        g4.begin();
        
        //updateTextures();     
            
        g4.setFloat(totalWidthLocation, n);
        g4.setFloat2(offsetLocation, 0.0, 0.0);
        
        //o++;
        
        g4.setFloat2(textureOffsetLocation, o, o);
        var t = haxe.Timer.stamp() * 0.4;
        var d = 1 + (Math.cos(t * 0.3) + 1) * 3;
        var pos = new FastVector3( Math.cos(t) * d, 0, Math.sin(t) * d);
        pos.y = (Math.cos(pos.x) + Math.sin(pos.z)) + 8.0;
        
        var a = buf.width / buf.height;
        mvp = FastMatrix4.perspectiveProjection(90.0, a, 0.0001, 100.0);
        
        var cam = FastMatrix4.lookAt(
            pos, 
            new FastVector3(0, 0, 0.0),
            new FastVector3(0, 1, 0));  
        cam = mvp.multmat(cam);
        
        g4.setMatrix(mvpLocation, cam);
        g4.clear(kha.Color.fromFloats(0.74, 0.74, 0.74), 1.0);
        
        for(level in 0...levels) {
            renderLevel(level, g4);
        }
        
        g4.end();
    }
}