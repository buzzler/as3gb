package com.mobswing.gb.model
{
	import __AS3__.vec.Vector;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	/** This class represents a tile in the tile data area.  It
	 * contains images for a tile in each of it's three palettes
	 * and images that are flipped horizontally and vertically.
	 * The images are only created when needed, by calling
	 * updateImage().  They can then be drawn by calling draw().
	 */
	public class GameboyTile
	{
		  private var image:Vector.<BitmapData> = new Vector.<BitmapData>(64);	//Image[64]
		
		  /** True, if the tile's image in the image[] array is a valid representation of the tile as it
		   *  appers in video memory. */
		  private var valid:Vector.<Boolean> = new Vector.<Boolean>(64);	//boolean[64]
		
		  private var source:Vector.<BitmapData> = new Vector.<BitmapData>(64);	//MemoryImageSource[64]

		  /** Current magnification value of Gameboy screen */
		  private var magnify:int = 2;
		  private var imageData:Vector.<uint> = new Vector.<uint>(64 * magnify * magnify);	//int[]
		  private var a:DisplayObject;
		  private var dmgcpu:Dmgcpu;
		  private var ppu:TileBasedGraphicsChip;

		/** Intialize a new Gameboy tile */
		public function GameboyTile(a:DisplayObject, d:Dmgcpu, p:TileBasedGraphicsChip)
		{
			allocateImage(GraphicsChip.TILE_BKG, a);
			this.a = a;
			this.dmgcpu = d;
			this.ppu = p;
		}


		  /** Allocate memory for the tile image with the specified attributes */
		  public function allocateImage(attribs:int, a:DisplayObject):void {
		  	var bmp:BitmapData = new BitmapData(8 * magnify, 8 * magnify, false);
		  	bmp.setVector(new Rectangle(0,0,8 * magnify, 8 * magnify), imageData);
		    source[attribs] = bmp;
			image[attribs] = bmp.clone();
		  }
		
		  /** Free memory used by this tile */
		  public function dispose():void {                  
		   for (var r:int = 0; r < 64; r++) {
		    if (image[r] != null) {
		     image[r].dispose();
		     image[r] = null;
		     valid[r] = false;
		    }
		   }
		  }
		
		  /** Returns true if this tile does not contian a valid image for the tile with the specified
		   *  attributes
		   */
		  public function invalid(attribs:int):Boolean {
		   return (!valid[attribs]);
		  }
		
		  /** Create the image of a tile in the tile cache by reading the relevant data from video
		   *  memory
		   */
		  public function updateImage(videoRam:ByteArrayAdvanced, offset:int, attribs:int):void {	//@param videoRam:byte[]
		   var px:int, py:int;
		   var rgbValue:int;
		 
		   if (image[attribs] == null) {
		    allocateImage(attribs, a);
		   }
		 
		   var pal:GameboyPalette;
		
		   if (offset == 0x31E0) {
		//	 trace("window updated with " + Javaboy.hexByte(attribs) + " xflip = " + (attribs & TILE_FLIPX) + "  yflip = " + (attribs & TILE_FLIPY));
		   }
		
		   if (dmgcpu.gbcFeatures) {
		    if (attribs < 32) {
		     pal = ppu.gbcBackground[attribs >> 2];
		    } else {
		     pal = ppu.gbcSprite[(attribs >> 2) - 8];
		    }
		   } else {
		    if ((attribs & GraphicsChip.TILE_OBJ1) != 0) {
		     pal = ppu.obj1Palette;
		    } else if ((attribs & GraphicsChip.TILE_OBJ2) != 0) {
		     pal = ppu.obj2Palette;
		    } else {
		     pal = ppu.backgroundPalette;
		    }
		   }
		
		   for (var y:int = 0; y < 8; y++) {
		    for (var x:int = 0; x < 8; x++) {
		
		     if ((attribs & GraphicsChip.TILE_FLIPX) != 0) {
		      px = 7 - x;
		     } else {
		      px = x;
		     }
		     if ((attribs & GraphicsChip.TILE_FLIPY) != 0) {
		      py = 7 - y;
		     } else {
		      py = y;
		     }
		
		     var pixelColorLower:int = (videoRam.read(offset + (py * 2)) & (0x80 >> px)) >> (7 - px);
		     var pixelColorUpper:int = (videoRam.read(offset + (py * 2) + 1) & (0x80 >> px)) >> (7 - px);
		
		     var entryNumber:int = (pixelColorUpper * 2) + pixelColorLower;
		     var pixelColor:int = pal.getEntry(entryNumber);
		
		/*     switch (pixelColor) {
		      case 0 : rgbValue = 0xFFFFFFFF;
		               break;
		      case 1 : rgbValue = 0xFFAAAAAA;
		               break;
		      case 2 : rgbValue = 0xFF555555;
		               break;
		      default :
		      case 3 : rgbValue = 0xFF000000;
		               break;
		     }*/
		     rgbValue = pal.getRgbEntry(entryNumber);
		
		     /* Turn on transparency for background */
		
		     if ((!dmgcpu.gbcFeatures) || ((attribs >> 2) > 7)) {
		      if (entryNumber == 0) {
		       rgbValue &= 0x00FFFFFF;
		      }
		     }
		/*     if ((entryNumber == 0) &&  ( ( (attribs & TILE_OBJ1) != 0) ||
		                                  ( (attribs & TILE_OBJ2) != 0) ) ) {
		      rgbValue &= 0x00FFFFFF;
		     } else if ((entryNumber == 0) &&
		         ((attribs & (TILE_OBJ1 | TILE_OBJ2)) == 0)) {
		      rgbValue &= 0x00FFFFFF;
		     } */
		
		     for (var cy:int = 0; cy < magnify; cy++) {
		      for (var cx:int = 0; cx < magnify; cx++) {
		       imageData[(y * 8 * magnify * magnify) + (cy * 8 * magnify) + (x * magnify) + cx] = rgbValue;
		      }
		     }
		
		    }
		   }
		
		   source[attribs].setVector(new Rectangle(0, 0, 8*magnify, 8*magnify), imageData);
		   image[attribs].setVector(new Rectangle(0, 0, 8*magnify, 8*magnify), imageData);
		   valid[attribs] = true;
		  }
		
		  /** Draw the tile with the specified attributes into the graphics context given */
		  public function draw(g:BitmapData, x:int, y:int, attribs:int):void {	//@param g:Graphics
		   g.draw(image[attribs], new Matrix(1,0,0,1,x*magnify,y*magnify));
		  }
		
		  /** Ensure that the tile is valid */
		  public function validate(videoRam:ByteArrayAdvanced, offset:int, attribs:int):void {	//@param videoRam:byte[]
		   if (!valid[attribs]) {
		    updateImage(videoRam, offset, attribs);
		   }
		  }
		
		  /** Change the magnification of the tile */
		  public function setMagnify(m:int):void {
		   for (var r:int = 0; r < 64; r++) {
		    valid[r] = false;
		    if (source[r] != null) {
		    	source[r].dispose();
		    	source[r] = null;
		    }
		    if (image[r] != null) {
		     source[r] = image[r].clone();
		     image[r].dispose();
		     image[r] = null;
		    }
		   }
		   magnify = m;
		   imageData = new Vector.<uint>(64 * magnify * magnify);
		  }
		
		  /** Invalidate tile with the specified palette, including all flipped versions. */
		  public function invalidate(attribs:int):void {
		   valid[attribs] = false;       /* Invalidate original image and */
		   if (image[attribs] != null)
		   {
		   	 source[attribs] = image[attribs].clone();
		     image[attribs].dispose();
		     image[attribs] = null;
		   }
		   valid[attribs + 1] = false;   /* all flipped versions in cache */
		   if (image[attribs + 1] != null)
		   {
		   	 source[attribs+ 1] = image[attribs+1].clone();
		   	 image[attribs + 1].dispose();
		   	 image[attribs + 1] = null
		   }
		   valid[attribs + 2] = false;
		   if (image[attribs + 2] != null)
		   {
		   	 source[attribs+ 2] = image[attribs+2].clone();
		   	 image[attribs + 2].dispose();
		   	 image[attribs + 2] = null
		   }
		   valid[attribs + 3] = false;
		   if (image[attribs + 4] != null)
		   {
		   	 source[attribs+ 4] = image[attribs+4].clone();
		   	 image[attribs + 4].dispose();
		   	 image[attribs + 4] = null
		   }
		  }
		
		  /** Invalidate this tile */
		  public function invalidateAll():void {
		   for (var r:int = 0; r < 64; r++) {
		    valid[r] = false;
		    if (image[r] != null)
		    {
		      source[r] = image[r].clone();
		      image[r].dispose();
		      image[r] = null;
		    }
		   }
		  }

	}
}