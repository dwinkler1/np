final: prev: let
  reqPkgs = (pyPackages: with pyPackages;[
    pandas
    requests
  ]);
in {
  py = prev.python3.withPackages reqPkgs;
}

