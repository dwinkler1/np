{
  description = "Project Templates";
  output = {self}: {
    templates = {
      r = {
        path = ./templates/r;
        description = "R development environment";
      };
    };
  defaultTemplate = self.templates.r;
  };
}
