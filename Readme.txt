This is a simple folder setup for editing ActionBars inside JAR files

The General Workflow

1. Edit .ijm file inside this folder
2. Run updateJar.bat
3. Copy JAR file to Fiji folder

When the 'updateJar' batch file is run, it adds:
- all .ijm files
- the files in the 'icons' folder (if you need any) 
- 'plugins.config' file

To the JAR file. That way everything is packed and ready to go and we need only move the JAR file to the plugins Folder.