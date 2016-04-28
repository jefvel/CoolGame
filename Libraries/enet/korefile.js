var project = new Project('enet');

project.addFile('cpp/**');
project.addIncludeDir('cpp/include');
project.addLibFor("Win32", "winmm");

return project;
