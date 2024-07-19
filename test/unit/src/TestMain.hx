package;

import haxe.io.Path;

class TestMain
{
	public static function main():Void
	{
		resetWorkingDir();

		trace('===STARTING TESTS===');

		// hScriptTest();

		json.util.SliceUtilTest.test();

		json.JSONDataTest.test();

		json.path.JSONPathLexerTest.test();
		json.path.JSONPathParserTest.test();
		json.path.JSONPathTest.test();

		trace('===ALL TESTS DONE===');
	}

	public static function resetWorkingDir():Void
	{
		#if sys
		var exeDir:String = Path.addTrailingSlash(Path.directory(Sys.programPath()));
		#if mac
		exeDir = Path.addTrailingSlash(Path.join([exeDir, '../Resources/']));
		#end
		var cwd:String = Path.addTrailingSlash(Sys.getCwd());
		if (cwd == exeDir)
		{
			trace('Working directory is already correct.');
		}
		else
		{
			trace('Changing working directory from ${Sys.getCwd()} to ${exeDir}');
			Sys.setCwd(exeDir);
		}
		#end
	}
}
