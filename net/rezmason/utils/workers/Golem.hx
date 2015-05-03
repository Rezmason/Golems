package net.rezmason.utils.workers;

#if macro
    import haxe.io.Path;
    import haxe.macro.Context;
    import haxe.macro.Expr;
    import sys.FileSystem;
    import sys.io.File;
    using Lambda;
#end

class Golem {

    #if macro static var golems:Array<String> = []; #end

    macro public static function rise(buildPath:String):Expr {

        // Resolve the build path because on some targets (for example ios) it must be relativ to the build directory
        buildPath = Context.resolvePath(buildPath);

        var key:String = 'main';
        if (Context.defined('flash')) key = 'swf';
        else if (Context.defined('js')) key = 'js';

        if (!FileSystem.exists(buildPath)) throw 'Golem "$buildPath" not found.';

        var outputPath:String = null;
        var properBuild:String = null;
        for (build in File.getContent(buildPath).split('\n--next').map(cleanStr)) {
            var args:Array<String> = build.split('\n').map(cleanStr);
            if (!args.has('##GOLEM##')) continue;

            for (arg in args) {
                if (arg.indexOf('-$key ') == 0) {
                    outputPath = arg.substr(key.length + 2);
                    break;
                }
            }

            if (outputPath != null) {
                var goodArgs:Array<String> = [];
                for (arg in args) if (arg.charAt(0) != '#') goodArgs.push(arg);
                properBuild = goodArgs.join(' ');
                break;
            }
        }

        if (outputPath == null) throw 'Golem "$buildPath" has no $key argument.';

        if (key == 'main') {

            return macro $p{outputPath.split('.').map(cleanStr)};

        } else {

            var path:Path = new Path(buildPath);
            var minionID:String = 'GOLEM__$buildPath';

            if (!golems.has(buildPath)) {
                golems.push(buildPath);
                var origin:String = Sys.getCwd();
                if (path.dir != null) Sys.setCwd(path.dir);
                Sys.command('haxe', properBuild.split(' ').map(cleanStr).concat(['-D', 'GOLEM']));
                Sys.setCwd (origin);
                if (path.dir != null) outputPath = Path.addTrailingSlash(path.dir) + outputPath;
                if (!FileSystem.exists(outputPath)) throw 'Golem "$buildPath" output not found. Build failed?';
                Context.addResource(minionID, File.getBytes(outputPath));
            }

            return macro haxe.Resource.getBytes($v{minionID});
        }
    }

    inline static function cleanStr(s:String):String {
        return (s.charCodeAt(s.length - 1) == 13) ? s.substr(0, s.length - 1) : s;
    }
}
