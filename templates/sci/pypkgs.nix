final: prev: let
  reqPkgs = (pyPackages: with pyPackages;[
    requests
  ]);
in {
  py = prev.python3.withPackages reqPkgs;
}

