import "dart:io";
import "package:ccompilers/ccompilers.dart";
import "package:build_tools/build_shell.dart";
import "package:build_tools/build_tools.dart";
import "package:file_utils/file_utils.dart";
import "package:patsubst/top_level.dart";

void main(List<String> args) {
  const String PROJECT_NAME = "sample_extension";
  const String LIBNAME_LINUX = "lib$PROJECT_NAME.so";
  const String LIBNAME_MACOS = "lib$PROJECT_NAME.dylib";
  const String LIBNAME_WINDOWS = "$PROJECT_NAME.dll";

  // Determine operating system
  var os = Platform.operatingSystem;

  // Setup Dart SDK bitness for extension
  var bits = DartSDK.getVmBits();

  // Compiler options
  var compilerDefine = {};
  var compilerInclude = ['$DART_SDK/bin', '$DART_SDK/include'];

  // Linker options
  var linkerLibpath = <String>[];

  // OS dependent parameters
  var libname = "";
  var objExtension = "";
  switch (os) {
    case "linux":
      libname = LIBNAME_LINUX;
      objExtension = ".o";
      break;
    case "macos":
      libname = LIBNAME_MACOS;
      objExtension = ".o";
      break;
    case "windows":
      libname = LIBNAME_WINDOWS;
      objExtension = ".obj";
      break;
    default:
      print("Unsupported operating system: $os");
      exit(-1);
  }

  // http://dartbug.com/20119
  var bug20119 = Platform.script;

  // Set working directory
  FileUtils.chdir("../lib/src");

  // C++ files
  var cppFiles = FileUtils.glob("*.cc");
  if (os != "windows") {
    cppFiles = FileUtils.exclude(cppFiles, "sample_extension_dllmain_win.cc");
  }

  cppFiles = cppFiles.map((e) => FileUtils.basename(e));

  // Object files
  var objFiles = patsubst("%.cc", "%${objExtension}").replaceAll(cppFiles);

  // Makefile
  // Target: default
  target("default", ["build"], null, description: "Build and clean.");

  // Target: build
  target("build", ["clean_all", "compile_link", "clean"], (Target t, Map args) {
    print("The ${t.name} successful.");
  }, description: "Build '$PROJECT_NAME'.");

  // Target: compile_link
  target("compile_link", [libname], (Target t, Map args) {
    print("The ${t.name} successful.");
  }, description: "Compile and link '$PROJECT_NAME'.");

  // Target: clean
  target("clean", [], (Target t, Map args) {
    FileUtils.rm(["*.exp", "*.lib", "*.o", "*.obj"], force: true);
    print("The ${t.name} successful.");
  }, description: "Deletes all intermediate files.", reusable: true);

  // Target: clean_all
  target("clean_all", ["clean"], (Target t, Map args) {
    FileUtils.rm([libname], force: true);
    print("The ${t.name} successful.");
  }, description: "Deletes all intermediate and output files.", reusable: true);

  // Compile on Posix
  rule("%.o", ["%.cc"], (Target t, Map args) {
    var args = new CommandLineArguments();
    var compiler = new Gpp();
    args.add('-c');
    args.addAll(['-fPIC', '-Wall']);
    args.add('-m32', test: bits == 32);
    args.add('-m64', test: bits == 64);
    args.addAll(compilerInclude, prefix: '-I');
    args.addKeys(compilerDefine, prefix: '-D');
    args.addAll(t.sources);
    return compiler.run(args.arguments).exitCode;
  });

  // Compile on Windows
  rule("%.obj", ["%.cc"], (Target t, Map args) {
    var args = new CommandLineArguments();
    var compiler = new Msvc(bits: bits);
    args.add('/c');
    args.addAll(t.sources);
    args.addAll(compilerInclude, prefix: '-I');
    args.addKeys(compilerDefine, prefix: '-D');
    args.addKey('DART_SHARED_LIB', null, prefix: '-D');
    return compiler.run(args.arguments).exitCode;
  });

  // Link on Linux
  file(LIBNAME_LINUX, objFiles, (Target t, Map args) {
    var args = new CommandLineArguments();
    var linker = new Gcc();
    args.addAll(t.sources);
    args.add('-m32', test: bits == 32);
    args.add('-m64', test: bits == 64);
    args.addAll(linkerLibpath, prefix: '-L');
    args.add('-shared');
    args.addAll(['-o', t.name]);
    return linker.run(args.arguments).exitCode;
  });

  // Link on Macos
  file(LIBNAME_MACOS, objFiles, (Target t, Map args) {
    var args = new CommandLineArguments();
    var linker = new Gcc();
    args.addAll(t.sources);
    args.add('-m32', test: bits == 32);
    args.add('-m64', test: bits == 64);
    args.addAll(linkerLibpath, prefix: '-L');
    args.addAll(['-dynamiclib', '-undefined', 'dynamic_lookup']);
    args.addAll(['-o', t.name]);
    return linker.run(args.arguments).exitCode;
  });

  // Link on Windows
  file(LIBNAME_WINDOWS, objFiles, (Target t, Map args) {
    var args = new CommandLineArguments();
    var linker = new Mslink(bits: bits);
    args.add('/DLL');
    args.addAll(t.sources);
    args.addAll(['dart.lib']);
    args.addAll(linkerLibpath, prefix: '/LIBPATH:');
    args.add('$DART_SDK/bin', prefix: '/LIBPATH:');
    args.add(t.name, prefix: '/OUT:');
    return linker.run(args.arguments).exitCode;
  });

  new BuildShell().run(args).then((exitCode) => exit(exitCode));
}
