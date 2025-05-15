{
  description = "Project Templates";
  outputs = {self}: 
   { ... }:
    {
    templates = {
      r = {
        path = ./templates/r;
        description = "R development environment";
      };
    };
  defaultTemplate = self.templates.r;
  };
}
