/* Macro for manually outlining objects of interest in images
 *  Olivier Burri, Romain Guiet May 03 2013
 *  Updated July 2014
 *  EPFL - SV - PTECH - PTBIOP
 *  http://biop.epfl.ch
*/


requires("1.38m");
// Minimal version because we use "Detect Right Click" 
// utility from Wayne's Macro Language. 

// Action Bar settings
sep = File.separator;

// Install the BIOP Library
call("BIOP_LibInstaller.installLibrary", "BIOP"+sep+"BIOPLib.ijm");


run("Action Bar","jar:file:BIOP/BIOP_MultiManual_Select.jar!/BIOP_MultiManual_Select.ijm");


exit();

//Start of ActionBar

<codeLibrary>

function toolName() {
	return "MultiManual Selector";
}


/*
 * Fancier functions used to draw ROIs on the graphics tablet. This uses the 
 * 'DisablePopupMenu' option for when right-clicking on an image
 * Stupid thing: It cannot undertand the 'right click' or any click from the 
 * graphic tablet's input, so the user must click with the mouse. More tests should be done.
 */

function buildSettings() {
	// Get the number of categories and Their Names
	catNum = parseInt(getData("Categories"));
	cat = getNumber("How Many Categories?",catNum);
	setData("Categories", cat);
	
	Dialog.create("Name "+cat+" Categories");
	for (i=1; i<=cat; i++) {
		categoryName = getData("Category #"+(i));
		Dialog.addString("Category #"+i, categoryName);
	}
	Dialog.show();
	
	for (i=1; i<=cat; i++) {
		catname = Dialog.getString();
		setData("Category #"+i, catname);
	}
}
 
function countRoisOfCategory(category) {
	nRois = roiManager("count");
	roiNum = 0;
	for (i=0; i<nRois; i++) {
		name = call("ij.plugin.frame.RoiManager.getName", i);
		expr = roiNameExp(category);
		if (matches(name, expr)) {
			roiNum++;
		}
	}
	print("There are "+roiNum+" ROIs of category '"+category+"'");
	return roiNum;
}

function roiName(category, index) {
	return category+" #"+index;
}

function roiNameExp(category) {
	return category+" #\\d+";
}


function DrawRois(category) {
	if (getVersion>="1.37r")
        	setOption("DisablePopupMenu", true);

	// Setup some variables. Basically these numbers
	// Represent an action that has taken place (it's the action's ID)
	shift=1;
	ctrl=2; 
	rightButton=4;
	alt=8;
	leftButton=16;
	insideROI = 32; // requires 1.42i or later

	// Now we initialize the ROI counts and check if there are already ROIs with this name. 
	
	roiNum = countRoisOfCategory(category);

	// done boolean to stop the loop that checks the mouse's location
	done=false;

	// rightClicked to make sure the function saves the ROI ONCE and not
	// continuously while "right click" is presed
	rightClicked = false;
	print("Started mouse tracking for "+category+", press 'ALT' to stop");
	while(!done) {
		// getCursorLoc gives the x,y,z position of the mouse and the flags associated
		// to see if a particular action has happened, say a left click while shift is 
		// pressed, you do it like this: 
		// if (flags&leftButton!=0 && flags&shift!=0) { blah blah... }
		
		getCursorLoc(x,y,z,flags);
		// print(x,y,z,flags);
		//If a freehand selection exists and the right button was clicked AND that right click was not pressed before already
		if (flags&rightButton!=0 && selectionType!=-1 && !rightClicked) {
			// set rightCLicked to true to stop this condition from writing several times the same ROI
			rightClicked = true;

			// Add the ROI to the manager
			roiManager("Add");

			newName = roiName(category, roiNum+1);
			renameLastRoi(newName);
			roiManager("Sort");
			roiNum++;
			print(roiNum+" saved.");
		}

		// Once we stopped pressing the right mouse button, we can then click it again and add a new ROI
		if (flags&rightButton==0) {
			rightClicked = false;
		}
		
		//We stop the loop when the user presses ALT
		if(isKeyDown("alt")) {
			done=true;
			print("ALT Pressed: Done");
			setKeyDown("none");
		}

		// This wait of 10ms is just to avoid checking the mouse position too often
		wait(10);
	}
	// Here we are out of the drawROI loop, so you can do some post processing already here if you want

}

function measureCurrentImage() {
	name=getTitle();
	// Duplicate the image and add a channel
	run("Select None");
	run("Duplicate...", "title=["+name+" Overlay]");
	
	// Now go through the ROIs and color them
	n = roiManager("Count");
	currentCat = "*none*";
	catNum=0;
	nCats = parseInt(getData("Categories"));
	
	for (i=0; i<n; i++) {
		roiManager("Select", i);
		name = call("ij.plugin.frame.RoiManager.getName", i);
		cat = substring(name, 0, lastIndexOf(name,"#")-1);
		if (cat != currentCat) {
			setSlice(catNum+1);
			currentCat = cat;
			catNum++;
			color = 50;	
			run("Add Slice");
			setForegroundColor(color, color, color);;
		}
		setSlice(1);
		run("Measure");
		setResult("Cat Number", nResults-1, catNum);
		setSlice(catNum+1);
		print(catNum);
	
		run("Fill", "slice");
	}
	run("Properties...", "channels="+(catNum+1)+" slices=1 frames=1");
	run("Make Composite", "display=Composite");
	setSlice(1);
	run("Grays");
}
</codeLibrary>
<line>
<button>
label=Select Folder
icon=noicon
arg=<macro>
//Open the file and parse the data
openParamsIfNeeded();

setImageFolder("Select Working Folder");
</macro>
</line>

<line>
<button>
label=Select Image
icon=noicon
arg=<macro>

selectImageDialog();
</macro>
</line>

<line>
<button>
label=Save image (+ ROI)
icon=noicon
arg=<macro>

saveCurrentImage();
//Saves the ROI Set with the name of the current image
saveRois("Open");
</macro>
</line>

<line>
<button>
label=Settings
icon=noicon
arg=<macro>
buildSettings();
</macro>
</line>

<line>
<button>
label=Draw ROIs
icon=noicon
arg=<macro>
nRois = parseInt(getData("Categories"));
// Draw the ROIs and stop when the user presses "ALT"
for (i=1; i<=nRois; i++) {
	category = getData("Category #"+i);
	DrawRois(category);
	wait(1000);
}

// Then save the ROIs right away.
saveRois("Open");
</macro>

<button>
label=Batch Draw ROIs
icon=noicon
arg=<macro>
nI = getNumberImages();
for (i=0; i<nI; i++) {
	roiManager("reset");
	openImage(i);
	nRois = parseInt(getData("Categories"));
	// Draw the ROIs and stop when the user presses "ALT"
	for (j=1; j<=nRois; j++) {
		category = getData("Category #"+j);
		DrawRois(category);
		wait(1000);
	}

	//Save ROIs
	saveRois("Open");

	//Close the image before going to the next one
	close();
}
</macro>
</line>

<line>
<button>
label=Clear ROIs
icon=noicon
arg=<macro>
roiManager("Reset");
</macro>
</line>
</line>

<line>
<button>
label=Measure Current Image
icon=noicon
arg=<macro>
measureCurrentImage();

</macro>
</line>
<line>
<button>
label=Batch Measure
icon=noicon
arg=<macro>
run("Clear Results");
nI = getNumberImages();
for (i=0; i<nI; i++) {
	roiManager("reset");
	openImage(i);
	n= roiManager("Count");
	if (n>0) {
		measureCurrentImage();
	
		saveCurrentImage();
		//DrawROIs
		saveRois("Save");
	}
	//Close the image before going to the next one
	close();
}
</macro>
</line>