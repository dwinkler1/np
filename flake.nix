{
  description = "Project Templates";
  outputs = {self}: {
    templates = {
      n = {
        path = ./templates/n;
        description = "Minimal Development environment";
      };
      r = {
        path = ./templates/r;
        description = "R development environment";
      };
      sci = {
        path = ./templates/sci;
        description = "Scientific computing environment (Julia, Python, R)";
      };
      sci_minimal = {
        path = ./templates/sci_minimal;
        description = "Scientific computing environment (Julia, Python, R) without folder structure";
      };
    };
    defaultTemplate = self.templates.n;
  };
}
