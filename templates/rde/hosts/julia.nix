# Julia-related host configurations
config: pkgs: {
  jl = {
    enable = config.enabledLanguages.julia;
    path = {
      value = "${pkgs.julia-bin}/bin/julia";
      args = ["--add-flags" "--project=."];
    };
  };

  initJl = {
    enable = config.enabledLanguages.julia;
    path = {
      value = "${pkgs.julia-bin}/bin/julia";
      args = ["--add-flags" "--project=. -e 'using Pkg; Pkg.instantiate(); Pkg.add(\"Pluto\")'"];
    };
  };

  pluto = let
    runPluto = ''
      import Pkg; import TOML; Pkg.instantiate();
      if !isfile("Project.toml") || !haskey(TOML.parsefile(Base.active_project())["deps"], "Pluto")
        Pkg.add("Pluto");
      end
      import Pluto; Pluto.run();
    '';
  in {
    enable = config.enabledLanguages.julia;
    path = {
      value = "${pkgs.julia-bin}/bin/julia";
      args = ["--add-flags" "--project=. -e '${runPluto}'"];
    };
  };
}
