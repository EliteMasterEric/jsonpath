package;

import test.consensus.src.json.path.JSONPathComplianceTest;
import haxe.io.Path;

class TestMain {
    public static function main():Void {
        resetWorkingDir();
      
        trace('===STARTING TESTS===');

        JSONPathComplianceTest.test();
        // json.path.JSONPathConsensusTest.test();

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