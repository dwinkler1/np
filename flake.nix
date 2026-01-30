{
  description = "Project Templates";
  outputs = {self}: {
    templates = {
      rde = {
        path = ./templates/rde;
        description = "Research Development Environment";
      };
      ed = {
        path = ./templates/ed;
        description = "Simple nvim Environment";
      };
    };
    defaultTemplate = self.templates.ed;
  };
}
