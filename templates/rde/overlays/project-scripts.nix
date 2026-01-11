# Project scripts overlay
config: final: prev: let
  # Helper function to substitute config placeholders in scripts
  substituteScript = scriptPath:
    prev.lib.replaceStrings
      ["@defaultPackageName@"]
      [config.defaultPackageName]
      (builtins.readFile scriptPath);
in {
  initPython = prev.writeShellScriptBin "initPython" (substituteScript ./scripts/initPython.sh);
  initProject = prev.writeShellScriptBin "initProject" (substituteScript ./scripts/initProject.sh);
  updateDeps = prev.writeShellScriptBin "updateDeps" (substituteScript ./scripts/updateDeps.sh);
  activateDevenv = prev.writeShellScriptBin "activateDevenv" (substituteScript ./scripts/activateDevenv.sh);
}
