{ pkgs, lib, ... }:
let
  clang = pkgs.clang_14;
  clang-compile = pkgs.clang-compile.override {
    inherit clang;
  };

  clang-version = lib.versions.major clang.version;
in
{
  id = "cpp-clang${clang-version}";
  name = "C++ Tools (with Clang)";

  packages = [
    clang
  ];

  replit.runners.clang-project = {
    name = "Clang++: Project";
    compile = "${clang-compile}/bin/clang-compile main.cpp cpp all";
    fileParam = false;
    language = "cpp";
    start = "./main.cpp.bin";
  };

  # TODO: add single runners/debuggers when we have priority for runners

  replit.languageServers.ccls = {
    name = "ccls";
    language = "cpp";
    start = "${pkgs.ccls}/bin/ccls";
  };

  replit.debuggers.gdb-project = {
    name = "GDB C++: Project";
    language = "cpp";
    start = "${pkgs.dap-cpp}/bin/dap-cpp";
    fileParam = false;
    compile = "${clang-compile}/bin/clang-compile main.cpp cpp all debug";
    transport = "stdio";
    initializeMessage = pkgs.dap-cpp.messages.dapInitializeMessage;
    launchMessage = pkgs.dap-cpp.messages.dapLaunchMessage "./main.cpp.bin";
  };
}