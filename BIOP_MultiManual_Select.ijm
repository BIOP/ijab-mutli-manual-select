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

// Define the Path to use the ActionBar
runFrom = "jar:file:BIOP/BIOP_MultiManual_Select.jar!/BIOP_MultiManual_Select.ijm";

// DEBUG LINE, uncomment as needed
//runFrom = "/plugins/ActionBar/Debug/BIOP_MultiManual_Select.ijm";

// Run the ActionBar
run("Action Bar",runFrom);

exit();

//Start of ActionBar

<codeLibrary>

function toolName() {
	return "MultiManual Selector";
}

function getColorHexFromName(color){
	colorArray = newArray("Red","Green","Blue","Yellow","Cyan","Magenta");
	degree = "00";
	degreeFull = "dd";
	hexArray = newArray("#"+degreeFull+degree+degree+"", "#"+degree+degreeFull+degree+"", "#"+degree+degree+degreeFull+"","#"+degreeFull+degreeFull+degree+"","#"+degree+degreeFull+degreeFull+"","#"+degreeFull+degree+degreeFull+"");
	//hexArray = newArray("#"+degree+degree+degreeFull+"","#"+degreeFull+degreeFull+degree+"","#"+degre+degreeFull+degreeFull+"","#"+degreeFull+degree+degreeFull+"");
	for (i = 0 ; i < lengthOf(colorArray) ; i++){
		if( colorArray[i]== color){
			return hexArray[i];
		}
	}
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
	colorArray = newArray("Red","Green","Blue","Yellow","Cyan","Magenta");
	Dialog.create("Name "+cat+" Categories");
	for (i=1; i<=cat; i++) {
		categoryName = getData("Category #"+(i));
		Dialog.addString("Category #"+i, categoryName);
		colorROI = getData("Color for "+categoryName);
		if (colorROI == ""){
			colorROI = colorArray[0];
		} 
		Dialog.addChoice("Category #"+(i)+" color", colorArray,colorROI);
	}
	strokeWidth = getDataD("Stroke width",3);
	Dialog.addNumber("Stroke width", strokeWidth);
	Dialog.show();
	
	for (i=1; i<=cat; i++) {
		catname = Dialog.getString();
		setData("Category #"+i, catname);
		categoryColor = Dialog.getChoice();
		setData("Color for "+catname,categoryColor);
	}
	strokeWidth = Dialog.getNumber();
	setData("Stroke width", strokeWidth);
	if (nImages > 0){
		reColorRois();
	}

	// Add padding 
	setData("Padding", 5);
}

function reColorRois(){
	nROIs 	= roiManager("Count");
	
	for (i=0; i<nROIs; i++) {
		roiManager("Select", i);
		currentRoiName 	= 	Roi.getName;													// get the full name of the current ROI (name #ROInumber)
		category 		= 	substring(currentRoiName, 0, lastIndexOf(currentRoiName,"#")-1);// // extract the category name
		colorROI 		= 	getData("Color for "+category);									// retrieve the color
		strokeWidth		=	getData("Stroke width");
			
		if (colorROI != "") { // if the category exists
			Roi.setStrokeColor(colorROI);
			roiManager("Update");
		}
	}
}

function measureCurrentImage() {
	////////////////////////////////////////////////////////////////////////////////////// get image infos
	imageName	=	getTitle();
	getDimensions(imageWidth, imageHeight, channels, slices, frames);
	getVoxelSize(pixelWidth, pixelHeight, pixelDepth, unit);

	////////////////////////////////////////////////////////////////////////////////////// get the number of category, determine the number of slice of the new image	
	nCats 		= parseInt(getData("Categories"));
	
	////////////////////////////////////////////////////////////////////////////////////// make a new image
	newImage(imageName+"-ROIs", "8-bit black", imageWidth, imageHeight, nCats);
	run("Make Composite", "display=Composite");
	setVoxelSize(pixelWidth, pixelHeight, pixelDepth, unit);

	////////////////////////////////////////////////////////////////////////////////////// color to fill ROI with
	color = 125;	
	setForegroundColor(color, color, color);

	
	////////////////////////////////////////////////////////////////////////////////////// Now go through the ROIs and color them
	nROIs		= roiManager("Count");													// get the number of ROIs to process
	colorArray	= newArray(nCats);														// create an array to store colors of the ROI
	for (i=0; i<nROIs; i++) {
		roiManager("Select", i);////////////////////////////////////////////////////////// select the ith ROI
		currentRoiName = Roi.getName; 													// get the full name of the current ROI (name #ROInumber)
		cat = substring(currentRoiName, 0, lastIndexOf(currentRoiName,"#")-1); 			// extract the category name
	
		currentCategoryNumber = -1;/////////////////////////////////////////////////////// using the category name of the ROI, get the corresponding category number 
		for (ii = 1; ii <= nCats; ii++) {												// for each existing category
			compareRoiName = getData( "Category #"+ii );								// get its name
			if(cat == compareRoiName){													// compare to the one of the currentROI
				currentCategoryNumber = ii;												// if it matches, get the currentCategoryNumber (for loop index)
			}
		}

		if (currentCategoryNumber == -1) {
			exit("There are no categories matching this ROI name: '"+cat+"'");
		}
		colorChannel = getData("Color for "+cat);										// retrieve its color
		colorArray[currentCategoryNumber-1] = colorChannel;								// and store it in the colorArray ( that will be used later, using changeLUTs)
		//colorArray[currentCategoryNumber-1] = getData("Color for "+cat);				// I don't get why this line doesn't work ! 
	
		setSlice(currentCategoryNumber);												// set the slice corresponding to the category	
		run("Fill", "slice");															// fill the ROI
		run("Measure");																	// mesaure it 
		//setResult("Cat Number", nResults-1, currentCategoryNumber);					// and add a column with category number, not necessary because measure indicates the slice value
		//updateResults;
	}
	updateResults;																		// never miss an Update ;)
	changeLUTs(colorArray);																// change the LUTs using the custom function
	run("Add Image...", "image=["+imageName+"] x=0 y=0 opacity=70 zero");					// add the original image as an overlay
	run("Flatten");																		// and Flatten
	run("Select None");																	// to save the image without an associated ROI
}

function changeLUTs(arrayOfLUT){
	// for each channel 'n' of an image 
	// will use the LUT specified in the arrayOfLUT[channelIndex-1]
	getDimensions(imageWidth, imageHeight, channels, slices, frames);

		for(channelIndex=1; channelIndex <= channels; channelIndex++){
			if (channels > 1) {	Stack.setChannel(channelIndex); }
			
			if((arrayOfLUT[channelIndex-1] == "0")||(arrayOfLUT[channelIndex-1] == "")||(arrayOfLUT[channelIndex-1] == "White")){
				run("Grays");
			}else{
				run(arrayOfLUT[channelIndex-1]);
			}
		}
	}

function buildSettingsCounter() {
	// Get the number of categories and Their Names
	totalCounterNbr 	= parseInt(getData("Counters"));
	counter 			= getNumber("How Many Counters?",totalCounterNbr);
	setData("Counters", counter);
	
	counterNameArray 	= newArray("P","G","I");
	counterNbrArray 	= newArray(9,5,6);
	
	Dialog.create("Name "+counter+" Counter");
	for (i=1; i<=counter; i++) {
		counterName = getData("Counters"+(i));
		if ( (counterName == "") && (i <= lengthOf(counterNameArray) ) ){
			counterName = counterNameArray[i-1];
		}
		Dialog.addString("Counter #"+i, counterName);
		counterNbr 	= getData("Counter #"+i+" nbr");
		if ( (counterNbr == "") && (i <= lengthOf(counterNbrArray) ) ){
			counterNbr = counterNbrArray[i-1];
		}
		Dialog.addNumber("Counter #"+i+" nbr", counterNbr);
	}
	Dialog.show();
	
	for (i=1; i<=counter; i++) {
		counterName = Dialog.getString();
		setData("Counter #"+i, counterName);
		counterNbr = Dialog.getNumber();
		setData("Counter #"+i+" nbr",counterNbr);
	}
}

function analyseCounterTextFile(){
	// parameters from parameters window detected
	pathName   		= getData("Image Folder");
	totalCounterNbr = parseInt(getData("Counters"));
	// parameters automatically detected
	imageName					= getTitle();
	//imageNameNoExt				= File.nameWithoutExtension;
	imageNameNoExt				= substring(imageName,0,(indexOf(imageName, "tif")-1));
	//print(imageNameNoExt);
	getDimensions(imageWidth, imageHeight, channels, slices, frames);

	if (isOpen("Results")){
		firstRow = nResults;
		IJ.renameResults("Results", "Temp");
	}else{
		
		for (counterIndex = 1 ; counterIndex <= totalCounterNbr ; counterIndex++){
		
			counterName = getData("Counter #"+counterIndex);
		//	print(counterName);
			counterNbr 	= getData("Counter #"+counterIndex+" nbr");
		//	print(counterNbr);
			for (index = 0 ; index < counterNbr; index++){
				columnName = counterName+(index+1);						
				setResult(columnName,0,0);
			}
		}
	//	updateResults;
		IJ.renameResults("Results", "Temp");
		firstRow = 0 ;
	}

	for (counterIndex = 1 ; counterIndex <= totalCounterNbr ; counterIndex++){
		counterName = getData("Counter #"+counterIndex);
	//	print(counterName);
		counterNbr 	= getData("Counter #"+counterIndex+" nbr");
	//	print(counterNbr);
		countInsideAndFillResultTable(counterName	,counterNbr,firstRow);
	}

	IJ.renameResults("Temp", "Results");
	updateResults;
}

function countInsideAndFillResultTable(typeIdentifier,maxValue,firstRow){
	// open imageName_CounterPhenotype.txt (rfom cell counter) counting the different phenotype observed in image imageName
	// open the corresponding counter table	
	//run("Clear Results");
	//print(imageNameNoExt);
	//print(pathName+imageNameNoExt+"_"+typeIdentifier+".txt");
	if( File.exists(pathName+imageNameNoExt+"_"+typeIdentifier+".txt") ){/////////////////////	if the file exists, open it 
		run("Results... ", "open=["+pathName+imageNameNoExt+"_"+typeIdentifier+".txt]");	// open it
		updateResults();
		resultsLength 			=  nResults;												// and get how many
		//################################################################ get coord(x,y) and phenotype Nbr from  the results Table:
		xCoord 					= newArray(resultsLength);
		yCoord 					= newArray(resultsLength);
		typeNbr					= newArray(resultsLength); 
		for (rowIndex = 0; rowIndex < resultsLength ; rowIndex++ ){
			xCoord [rowIndex] 	= getResult("X"		, rowIndex);
			yCoord [rowIndex]	= getResult("Y"		, rowIndex);
			typeNbr[rowIndex]	= getResult("Type"	, rowIndex);
		}
		
		//run("Clear Results");
		
		IJ.renameResults("Temp", "Results");
		rowCounter = firstRow;
		
		for (roiIndex = 0 ; roiIndex<roiManager("count");roiIndex++){		// For all the ROIs
			roiManager("Select", roiIndex);									// select the ROI roiIndex
			setResult("Label", rowCounter,imageNameNoExt+":"+Roi.getName);	// write the results in the table
			setResult("Count", rowCounter,1);								// colum to retrieve the total count of each category
			
			countInsideCurrent = newArray(maxValue);						// create a an array, to add total number of each type per ROI
			
			for (indexContains = 0; indexContains < lengthOf(xCoord); indexContains++ ){								// for each cursor poistion at (x,y)
				if (Roi.contains(xCoord[indexContains], yCoord[indexContains]))			{								// if it contained inside the current ROI, 
					countInsideCurrent[(typeNbr[indexContains]-1)] = countInsideCurrent[(typeNbr[indexContains]-1)] + 1;//increases the corresponding Phenotype counter
				}
			}
			
			for (index = 0 ; index < maxValue; index++){					// write the results in the table
				type = typeIdentifier+(index+1);	
				setResult(type,rowCounter,countInsideCurrent[index]);	
			}
			
			rowCounter++;
		}
		IJ.renameResults("Results", "Temp");
	} else {
		IJ.renameResults("Temp", "Results");
		rowCounter = firstRow;
		
		for (roiIndex = 0 ; roiIndex<roiManager("count");roiIndex++){		// For all the ROIs
			roiManager("Select", roiIndex);									// select the ROI roiIndex
			setResult("Label", rowCounter,imageNameNoExt+":"+Roi.getName);	// write the results in the table
			
			for (index = 0 ; index < maxValue; index++){					// write the results in the table
				type = typeIdentifier+(index+1);	
				setResult(type,rowCounter,NaN);	
			}
			
			rowCounter++;
		}
		IJ.renameResults("Results", "Temp");
	}
}	

/*
 * Code to procedurally create an ActionBar to manage categories individually, if needed.  
 * 
 */
function makeABSelManager() {

	sep = File.separator;
	path = getDirectory("plugins");
	
	nCat= parseInt(getData("Categories"));
	catNames = newArray(nCat);
	for (i=0; i<nCat; i++) {
		cat = getData("Category #"+(i+1));
		catNames[i] = cat;
	}
	
	String.resetBuffer;
	// import codeLibrary
	txt = getCodeLibSelector();
	String.append("<codeLibrary>\n"+txt+"\n"+"</codeLibrary>\n");

											
	
	for (i=0; i<nCat; i++) {
		colorChannel = getData("Color for "+catNames[i]); // retrieve its color
		colorHex = getColorHexFromName(colorChannel);
		// Make the buttons
		String.append("<text><html><font size=3 color="+colorHex+">" + catNames[i]+"\n");
		String.append("<line>\n");
		String.append("<button>\n");
		String.append("label=Add\n");
		String.append("icon=noicon\n");
		String.append("arg=<macro>\n");
		String.append(addMacro(catNames[i]));
		String.append("</macro>\n");
	
		String.append("<button>\n");
		String.append("label=Remove\n");
		String.append("icon=noicon\n");
		String.append("arg=<macro>\n");
		String.append(delMacro(catNames[i]));
		String.append("</macro>\n");
	
		String.append("<button>\n");
		String.append("label=Batch\n");
		String.append("icon=noicon\n");
		String.append("arg=<macro>\n");
		String.append(batchFolderMacro(catNames[i]));
		String.append("</macro>\n");
	
		
		String.append("</line>\n");
	}
	File.makeDirectory(path+"ActionBar");
	File.makeDirectory(path+"ActionBar"+sep+"selector"+sep);
	fullPath = path+"ActionBar"+sep+"selector"+sep+"Selector.ijm";
	
	File.saveString(String.buffer, fullPath);
	
	run("Action Bar","plugins/ActionBar/selector/Selector.ijm");

}

function addMacro(catName){
	return "DrawRoisL(\""+catName+"\");\n"+"saveRois(\"Open\");\n");
}

function delMacro(catName){
	txt = "pad = parseInt(getData(\"Padding\"));"+"\n";
	txt += "ori = roiManager(\"index\");"+"\n";
	txt += "idx = findRoisWithName(\""+catName+".*\");"+"\n";
	txt +="roiList = newArray(idx.length+1);"+"\n";
	txt +="roiList[0] = \"None\";"+"\n";
	txt +="for (i=0; i<idx.length; i++) {"+"\n";
	txt +="	roiManager(\"Select\", idx[i]);"+"\n";
	txt +="	roiList[i+1] = Roi.getName();"+"\n";
		
	txt +="}"+"\n";
	//txt +="roiManager(\"Select\", ori);"+"\n";
	txt +="Dialog.create(\"Select ROI to Delete\");"+"\n";
	txt +="Dialog.addChoice(\"ROI Name\", roiList, roiList[0]);"+"\n";
	txt +="Dialog.show();"+"\n";

	txt +="toDel = Dialog.getChoice();"+"\n";
	txt +="if(toDel != \"None\") {"+"\n";
	txt +="	idx2 = findRoiWithName(toDel);"+"\n";
	txt +="	roiManager(\"Select\", idx2);"+"\n";
	txt +="	roiManager(\"Delete\");"+"\n";
	txt +="	// Now move every object up"+"\n";
	txt +="	roiNum = IJ.pad( parseInt(substring(toDel, lastIndexOf(toDel, \"#\")+1)) , pad); "+"\n"; 
	//txt +=" roiNum = parseInt(substring(toDel, lastIndexOf(toDel, \"#\")+1));"+"\n";
	txt +="	if(roiNum != idx.length) {"+"\n";
	txt +="		for(i=roiNum; i<idx.length; i++) {"+"\n";
	txt +="			roiManager(\"Select\", idx[i-1]);"+"\n";
	//txt +="			roiManager(\"Rename\", \""+catName+" #\"+i);"+"\n";
	txt +="			roiManager(\"Rename\", \""+catName+" #\"+ IJ.pad(i,pad));"+"\n"; // sorting causes trouble ! pad the umber of the ROIs  
	txt +="		}"+"\n";
	txt +="	}"+"\n";
	txt +="}"+"\n";
	txt +="saveRois(\"Open\");"+"\n";

	return txt;
}

function batchFolderMacro(category) {
	txt ="nI = getNumberImages();"+"\n";
	txt +="for (i=0; i<nI; i++) {"+"\n";
	txt +="roiManager(\"reset\");"+"\n";
	txt +="openImage(i);"+"\n";
	txt +="DrawRoisL(\""+category+"\");"+"\n";
	txt +="wait(200);"+"\n";
	txt +="//Save ROIs"+"\n";
	txt +="saveRois(\"Open\");"+"\n";
	txt +="//Close the image before going to the next one"+"\n";
	txt +="close();"+"\n";
	txt +="}"+"\n";
	return txt;
}

function getCodeLibSelector() {
txt ="function toolName() {"+"\n";
txt +="	return \"MultiManual Selector\";"+"\n";
txt +="}"+"\n";
return txt;
}
</codeLibrary>
<text><html><font size=2 color=#66666f> ---------------------------------------Parameters
<line>
<button>
label=Save
arg=<macro>
saveParameters();
</macro>

<button>
label=Load
arg=<macro>
loadParameters();
</macro>
</line>




<text><html><font size=2 color=#66666f> ---------------------------------------------Select

<line>
<button>
label= Folder
icon=noicon
arg=<macro>
//Open the file and parse the data
openParamsIfNeeded();
setImageFolder("Select Working Folder");
</macro>
</line>

<line>
<button>
label= Image
icon=noicon
arg=<macro>
selectImageDialog();
if(roiManager("count") >0) {
	roiManager("Sort");
}
</macro>
</line>

<text><html><font size=2 color=#66666f> ---------------------------------------Draw ROIs


<line>
<button>
label=Settings
icon=noicon
arg=<macro>
buildSettings();
makeABSelManager();
</macro>
</line>

<line>
<button>
label= on current Image
icon=noicon
arg=<macro>
nRois = parseInt(getData("Categories"));
// Draw the ROIs and stop when the user presses "ALT"
for (i=1; i<=nRois; i++) {
	category = getData("Category #"+i);
	DrawRoisL(category);
	wait(1000);
}

// Then save the ROIs right away.
saveRois("Open");
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

<button>
label=Clear ROIs
icon=noicon
arg=<macro>
roiManager("Reset");
</macro>
</line>

<line>
<button>
label= on current Folder
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
		DrawRoisL(category);
		wait(1000);
	}

	//Save ROIs
	saveRois("Open");

	//Close the image before going to the next one
	close();
}
</macro>
</line>

<text><html><font size=2 color=#66666f> ------------------------------------------Measure
<line>
<button>
label= on current Image
icon=noicon
arg=<macro>
measureCurrentImage();

</macro>
</line>
<line>
<button>
label= on current Folder
icon=noicon
arg=<macro>
savingDir = getSaveFolder();

setBatchMode(true);

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
	run("Close All");
}
selectWindow("Results");
saveAs("Results", savingDir+"Results_Area.txt");	

setBatchMode(false);
showMessage("Measure on current folder , DONE");
</macro>
</line>

<text><html><font size=2 color=#66666f> -----------------------------------------Counter
<line>
<button>
label=start manual counter
icon=noicon
arg=<macro>
run("Cell Counter");
</macro>
</line>

<text><html><font size=2 color=#66666f> -----------------------------------------Analyse
<line>
<button>
label=Settings
icon=noicon
arg=<macro>
buildSettingsCounter();
</macro>
</line>


<line>
<button>
label=current Image
icon=noicon
arg=<macro>
analyseCounterTextFile();
</macro>
</line>


<line>
<button>
label= current Folder
icon=noicon
arg=<macro>
run("Clear Results");
nI = getNumberImages();
for (i=0; i<nI; i++) {
	roiManager("reset");
	openImage(i);
	n= roiManager("Count");
	if (n>0) {
		analyseCounterTextFile();
	
		//saveCurrentImage();
		//DrawROIs
		//saveRois("Save");
	}
	//Close the image before going to the next one
	close();
}

path = getSaveFolder();
if (isOpen("Results")){
	selectWindow("Results");
	saveAs("Results", path+"Results_Analyse.txt");
}

showMessage("Analyse on current folder , DONE");
</macro>
</line>


<text><html><font size=2 color=#66666f> -------------------------------------------Help
<line>
<button>
label=BIOP website
icon=noicon
arg=<macro>
biopUrl = "http://biop.epfl.ch/index.php/";
run("URL...", "url="+biopUrl);
</macro>
</line>
