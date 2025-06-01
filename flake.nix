{
  description = "Project Templates";
  outputs = {self}: 
  {
    templates = {
      r = {
        path = ./templates/r;
        description = "R development environment";
      };
      sci = {
        path = ./templates/sci;
        description = "Scientific computing environment (Julia, Python, R)";
      };
    };
    defaultTemplate = self.templates.sci;
  };
}
