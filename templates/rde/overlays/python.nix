# Python packages overlay
final: prev: {
  python = prev.python3.withPackages (pyPackages:
    with pyPackages; [
      requests
    ]);
}
