package
{
	public class Utils
	{
		public	static function toVector(array:Array, type:String):*
		{
			var result:*;
			switch (type)
			{
				case "uint":
					result = new Vector.<uint>(array.length);
					break;
				case "number":
					result = new Vector.<Number>(array.length);
					break;
				case "function":
					result = new Vector.<Function>(array.length);
					break;
			}
			var i:uint = 0,j:uint = 0;
			var total:uint = array.length;
			while (i<total)
			{
				result[i++] = array[j++];
			}
			return result;
		}
	}
}