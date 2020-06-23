// Chromosome alignment maco by Luciano G. Braga
// v 1 21-10-2019
// Given a first image immunostained for the mitotic poles, it will ask or calculate the coordinates for each pole.
// A second image will be charged with the kinetochore positioning. The macro will create an alignment zone according to the set number of divisions.
// The image inside the alignment zone will be cleared, and the reamining chormosomes (misaligned chromosomes) will be counted with the count particle function.

// Open images, first for the poles then kinetochores

	title = "Images open";
	msg = "Please make sure the first opened image is immunostained for the poles, the second opened image for the kinetochores, and the third with DAPI.";
	waitForUser(title, msg);
	selectImage(1);
	run("Select None");
	Poles_image = getTitle();
	selectImage(2);
	run("Select None");
	Kinetochores_image = getTitle();
	selectImage(3);
	run("Select None");
	DAPI = getTitle();


// Isolate the cell excluding all that is outside

	
	selectImage(DAPI);
	run("Select None");
	setTool("oval");
	title = "Cell selection";
	msg = "Please select the desired cell, then click \"OK\".";
	waitForUser(title, msg);
	roiManager("Add");
	run("Select None");
	
// Create the dialog box for divisions

	Dialog.create("How many sections?");
	Dialog.addNumber("Total number of segments:",6 );
	Dialog.addNumber("Aligned segments:",4 );
	Dialog.addNumber("Y axis inferior limite:",15000 );
	Dialog.show();
	divisions= Dialog.getNumber();
	aligned_region= Dialog.getNumber();
	ylimit= Dialog.getNumber();
		
	selectImage(Poles_image);
	
// Get the pole coordinates

	// Isolat the cell in the image for the poles
	roiManager("Select",0);
	run("Clear Outside");
	//Ask if should try to get the poles automatically
	
	Dialog.create("Automatically detect poles?");
	Dialog.addCheckbox("Yes.", true);
    Dialog.show();
    Auto = Dialog.getCheckbox();
    if (Auto==true){
    //convert the pole image to binary
    setAutoThreshold("MaxEntropy dark");
    run("Make Binary");
    run("Set Measurements...", "area mean min centroid display redirect=None decimal=3");
    run("Analyze Particles...",  "size=40-Infinity circularity=0.2-1.00 show=[Overlay Masks] ");
    Xcoord=newArray(nResults);
    Ycoord=newArray(nResults);
    for (row=0; row<(nResults); row++) { 
    
    Xcoord[row]=getResult("X",row);
    Ycoord[row]=getResult("Y",row);
    xp1=Xcoord[0];
    xp2=Xcoord[1];
	yp1=Ycoord[0];
	yp2=Ycoord[1];
	
    }};
    
    //Get the poles manually
    
	if (Auto==false){ 
	run("Select None");
	setTool("multipoint");
	title = "Spindle pole selection";
	msg = "Please select the two poles, then click \"OK\".";
	waitForUser(title, msg);
	getSelectionCoordinates(x, y);
	xp1=x[0];
	yp1=y[0];
	xp2=x[1];
	yp2=y[1];
 	}
	
// Calculations for the definition of the metaphase zone

range=aligned_region/divisions;
f1=0.5-(range/2);
f2=0.5+(range/2);

x1=xp1+(f1*(xp2-xp1));
y1=yp1+(f1*(yp2-yp1));
x2=xp1+(f2*(xp2-xp1));
y2=yp1+(f2*(yp2-yp1));
a_spindle=(yp2-yp1)/(xp2-xp1);

a=-1/a_spindle;

b1=y1-(a*x1);
b2=y2-(a*x2);

// The first point will be calculated depending on the slope 
if (a>0) {
xr1=0;
yr1=b1;
} else{
xr1=-b1/a;
yr1=0;
}


xr2=(xr1+(a*yr1)-(a*b2))/((a*a)+1);
yr2=a*xr2+b2;


xr3=(ylimit-b1)/a;
yr3=ylimit;

xr4=(xr3+(a*yr3)-(a*b2))/((a*a)+1);
yr4=a*xr4+b2;

// Select the alignment region and add it to ROI manager
makePolygon(xr1,yr1,xr3,yr3,xr4,yr4,xr2,yr2);
roiManager("Add");


// Isolate cell in kinetochore image
	selectImage(Kinetochores_image);
	roiManager("Select",0);
	run("Clear Outside");
// Transfer alignment selection to kinetochore image and evaluate alignment zone
	roiManager("Select",1);
	title = "Region selection evaluation";
	msg = "Region selection evaluation, click \"OK\" to continue.";
	waitForUser(title, msg);
// Clear inside of alignment zone
	run("Clear", "slice");
//Finding the kinetochores

// Filter image. If the function threshold does not result in a clear posiitoning of the kinetochore signal, try setting the threshold manually and using the same value for all images.
// To use the a specific set threshold, substitute the setAuroThreshold function for: run("Threshold...");
// For the images analyzed, the auto threshold using the function MaxEntropy correctly identified most of the kinetochores.
	run("Select None");
	//run("Threshold...");
	//setThreshold(1700, 30000);
	setAutoThreshold("MaxEntropy dark"); // Delete this line if Threshold will be set manually

// Evaluate the kinetochore selection
	title = "Image treatment evaluation";
	msg = "Image evaluation, click \"OK\" to continue.";
	waitForUser(title, msg);

// Convert to binary to be analyzed
	run("Make Binary");
	run("Watershed");


// Run Analyze particles function. The parameter for the Analyze Particles can be changed to increase detection.
	run("Analyze Particles...",  "size=6-Infinity circularity=0.3-1.00 show=[Overlay Masks] display summarize");
	title = "Results";
	msg = "Click \"OK\" to continue and finish.";
	waitForUser(title, msg);

// Clear ROI cache 
	roiManager("deselect");
	roiManager("delete");
close();close();close();
