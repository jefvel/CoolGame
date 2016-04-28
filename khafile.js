var project = new Project('Bonk');

//Android settings
project.targetOptions.android.screenOrientation = "sensor";
project.targetOptions.android.package = "com.jefvel.coolgame";

//Files
project.addAssets("Assets/**");
project.addShaders('Shaders/**');
project.addLibrary("zui");
project.addLibrary("enet");
//project.addDefine("windows");
//project.addParameter("-cpp cpp/");
//project.addParameter("-cp ../Libraries/linc_enet");

//project.addParameter("-cp Library/linc_enet");
//project.addParameter("-cp Library/linc_enet/lib/enet/include");

project.addSources('Sources');

return project;
