package away3d.loaders.parsers;

import away3d.events.Asset3DEvent;
import away3d.library.assets.BitmapDataAsset;
import away3d.loaders.parsers.utils.ParserUtil;
import away3d.textures.ATFTexture;
import away3d.textures.BitmapTexture;
import away3d.textures.Texture2DBase;
import away3d.tools.utils.TextureUtils;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Loader;
import openfl.events.Event;
import openfl.utils.ByteArray;

/**
 * ImageParser provides a "parser" for natively supported image types (jpg, png). While it simply loads bytes into
 * a loader object, it wraps it in a BitmapDataResource so resource management can happen consistently without
 * exception cases.
 */
class ImageParser extends ParserBase
{
	private var _byteData:ByteArray;
	private var _startedParsing:Bool;
	private var _doneParsing:Bool;
	private var _loader:Loader;
	
	/**
	 * Creates a new ImageParser object.
	 * @param uri The url or id of the data or file to be parsed.
	 * @param extra The holder for extra contextual data that the parser might need.
	 */
	public function new()
	{
		super(ParserDataFormat.BINARY);
	}
	
	/**
	 * Indicates whether or not a given file extension is supported by the parser.
	 * @param extension The file extension of a potential file to be parsed.
	 * @return Whether or not the given file type is supported.
	 */
	
	public static function supportsType(extension:String):Bool
	{
		extension = extension.toLowerCase();
		return extension == "jpg" || extension == "jpeg" || extension == "png" || extension == "gif" || extension == "bmp" || extension == "atf";
	}
	
	/**
	 * Tests whether a data block can be parsed by the parser.
	 * @param data The data block to potentially be parsed.
	 * @return Whether or not the given data is supported.
	 */
	public static function supportsData(data:Dynamic):Bool
	{
		var ba:ByteArray;
		
		//shortcut if asset is IFlexAsset
		if (Std.is(data, Bitmap))
			return true;
		
		if (Std.is(data, BitmapData))
			return true;
		
		ba = ParserUtil.toByteArray(data);
		if (ba == null)
			return false;
		
		if (isJPEG(ba))
			return true; // JPEG/JFIF
		
		if (isBMP(ba))
			return true; // BMP
		
		if (isPNG(ba))
			return true; // PNG
		
		if (isGIF(ba))
			return true; // GIF87a/GIF89a
		
		if (isATF(ba))
			return true; // ATF
		
		return false;
	}
	
	/**
	 * @inheritDoc
	 */
	private override function proceedParsing():Bool
	{
		var asset:Texture2DBase;
		if (Std.is(_data, Bitmap)) {
			asset = new BitmapTexture(cast(_data, Bitmap).bitmapData);
			finalizeAsset(asset, _fileName);
			return ParserBase.PARSING_DONE;
		}
		
		if (Std.is(_data, BitmapData)) {
			asset = new BitmapTexture(cast(_data, BitmapData));
			finalizeAsset(asset, _fileName);
			return ParserBase.PARSING_DONE;
		}
		
		_byteData = getByteData();
		if (!_startedParsing) {
			if (isATF(_byteData)) {
				_byteData.position = 0;
				asset = new ATFTexture(_byteData);
				finalizeAsset(asset, _fileName);
				return ParserBase.PARSING_DONE;
			} else {
				_loader = new Loader();
				_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
				_loader.loadBytes(_byteData);
				_startedParsing = true;
			}
		}
		
		return _doneParsing;
	}
	
	/**
	 * Called when "loading" is complete.
	 */
	private function onLoadComplete(event:Event):Void
	{
		var bmp:BitmapData = cast(_loader.content, Bitmap).bitmapData;
		var asset:BitmapTexture;
		
		_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);
		
		if (!TextureUtils.isBitmapDataValid(bmp)) {
			var bmdAsset:BitmapDataAsset = new BitmapDataAsset(bmp);
			bmdAsset.name = _fileName;
			
			dispatchEvent(new Asset3DEvent(Asset3DEvent.TEXTURE_SIZE_ERROR, bmdAsset));
			
			bmp = new BitmapData(8, 8, false, 0x0);
			
			//create chekerboard for this texture rather than a new Default Material
			for (i in 0...8) {
				for (j in 0...8) {
					if (((j & 1) ^ (i & 1)) > 0)
						bmp.setPixel(i, j, 0xFFFFFF);
				}
			}
		}
		
		asset = new BitmapTexture(bmp);
		finalizeAsset(asset, _fileName);
		_doneParsing = true;
	}
	
	private static function isATF(ba:ByteArray):Bool
	{
		if (ba == null || ba.length < 3)
			return false;
		
		ba.position = 0;
		var a:Int = ba.readUnsignedShort();
		var b:Int = ba.readUnsignedByte();
		return a == 0x4154 && b == 0x46; // ATF
	}
	
	private static function isBMP(ba:ByteArray):Bool
	{
		if (ba == null || ba.length < 2)
			return false;
		
		ba.position = 0;
		var a:Int = ba.readUnsignedShort();
		return a == 0x424d; // BMP
	}
	
	private static function isGIF(ba:ByteArray):Bool
	{
		if (ba == null || ba.length < 6)
			return false;
		
		ba.position = 0;
		var a:Int = ba.readUnsignedInt();
		var b:Int = ba.readUnsignedShort();
		return a == 0x47494638 && (b == 0x3761 || b == 0x3961); // GIF87a/GIF89a
	}
	
	private static function isJPEG(ba:ByteArray):Bool
	{
		if (ba == null || ba.length < 4)
			return false;
		
		ba.position = 0;
		var a:Int = ba.readUnsignedShort();
		ba.position = ba.length - 2;
		var b:Int = ba.readUnsignedShort();
		return a == 0xffd8 || b == 0xffd9; // JPEG/JFIF
	}
	
	private static function isPNG(ba:ByteArray):Bool
	{
		if (ba == null || ba.length < 8)
			return false;
		
		ba.position = 0;
		var a:Int = ba.readUnsignedInt();
		var b:Int = ba.readUnsignedInt();
		return a == 0x89504e47 && b == 0x0d0a1a0a; // PNG
	}
}