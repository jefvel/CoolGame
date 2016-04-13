var project = new Project('Bonk');

project.addAssets("Assets/**");
project.addLibrary("zui");
project.addLibrary("linc_enet");
project.addSources('Sources');

return project;
