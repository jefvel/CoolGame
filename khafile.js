var project = new Project('Bonk');

//Android settings
project.targetOptions.android.screenOrientation = "sensorPortrait";
project.targetOptions.android.package = "com.jefvel.coolgame";

project.addAssets("Assets/**");
project.addShaders('Shaders/**');
project.addLibrary("zui");
project.addSources('Sources');

return project;
