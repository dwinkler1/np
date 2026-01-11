# Python packages overlay
#
# This overlay configures the Python environment with essential packages.
# Note: Most Python packages should be managed via uv (pyproject.toml)
# This overlay is for packages needed at the system level.
#
# Usage:
#   - Add system-level Python packages to the list below
#   - For project-specific packages, use uv (e.g., 'uv add package-name')
#   - The Python interpreter is available via pkgs.python
#
# Example additions:
#   - numpy, pandas, scipy for scientific computing
#   - pytest, black, mypy for development tools
final: prev: {
  # Python 3 with system-level packages
  python = prev.python3.withPackages (pyPackages:
    with pyPackages; [
      requests  # HTTP library for making API calls
      # Add more system-level packages here
    ]);
}
