{
  description = "Project Templates";
  outputs = {self}: {
    templates = {
      rde = {
        path = ./templates/rde;
        description = "Research Development Environment";
      };
    };
    defaultTemplate = self.templates.n;
  };
}
