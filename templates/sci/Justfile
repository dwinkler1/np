rverurl := 'https://raw.githubusercontent.com/ropensci/rix/refs/heads/main/inst/extdata/available_df.csv'
update-r-version:
    RVER=$( wget -qO- {{rverurl}} | tail -n 2 | head -n 1 | cut -d',' -f4 | tr -d '"' ) &&\
     sed -i  "s|rixpkgs.url = \"https://github.com/rstats-on-nix/nixpkgs/archive/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\.tar\.gz\";|rixpkgs.url = \"https://github.com/rstats-on-nix/nixpkgs/archive/$RVER.tar.gz\";|" flake.nix
