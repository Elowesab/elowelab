// Lagging chromosome maco by Luciano G. Braga
// v 1 21-10-2019
// Given a first image immunostained for the mitotic poles, it will ask or calculate the coordinates for each pole.
// A second image will be charged with the kinetochore positioning. The macro will create an alignment zone according to the set number of divisions.
// The image outside the alignment zone will be cleared, and the reamining chormosomes will be counted with the count particle function.

// Open images, first for the poles then kinetochores

	title = "Images open";
	msg = "Please make sure the first opened image is immunostained for the kinetochores and the second for chromatin.";
	waitForUser(title, msg);
	selectImage(1);
	run("Select None");
	Kinetochores_image = getTitle();
	selectImage(2);
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
	Dialog.addNumber("Total number of sections:",5 );
	Dialog.addNumber("Number of middle section:",3 );
	Dialog.addNumber("Y axis inferior limite:",15000 );
	Dialog.show();
	divisions= Dialog.getNumber();
	aligned_region= Dialog.getNumber();
	ylimit= Dialog.getNumber();
		
	selectImage(DAPI);
	
// Get the pole coordinates

	// Isolat the cell in the image for the poles
	roiManager("Select",0);
	run("Clear Outside");
	//Ask if should try to get the poles automatically
	
	Dialog.create("Automatically detect chromosome masses?");
	Dialog.addCheckbox("Yes.", true);
    Dialog.show();
    Auto = Dialog.getCheckbox();
    if (Auto==true){
    
    //Choose first mass
    	
	selectImage(DAPI);
	run("Select None");
	run("Duplicate...", " ");
	setTool("oval");
	title = "Select first chromosome mass";
	msg = "Please select the desired area, then click \"OK\".";
	waitForUser(title, msg);
	run("Clear Outside");
	setAutoThreshold("Default dark");
	run("Create Selection");
	run("Measure");
	close();
	
	//Choose second mass
    	
	selectImage(DAPI);
	run("Select None");
	run("Duplicate...", " ");
	setTool("oval");
	title = "Select second chromosome mass";
	msg = "Please select the desired area, then click \"OK\".";
	waitForUser(title, msg);
	run("Clear Outside");
	setAutoThreshold("Default dark");
	run("Create Selection");
	run("Measure");
	close();

     
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
	setTool("Chromosome mass selection";
	msg = "Please select the two anaphasic masses with multi-point tool, then click \"OK\".";
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
	title = "Evaluation";
	msg = "Region selection evaluation, click \"OK\" to continue.";
	waitForUser(title, msg);
// Clear outside of alignment zone
	run("Clear Outside");
//Finding the kinetochores

// Filter image. If the function threshold does not result in a clear posiitoning of the kinetochore signal, try setting the threshold manually or using the same value for all images.
// To use the a specific set threshold, substitute the setAuroThreshold function for: run("Threshold...");
// For the images analyzed, the auto threshold using the function MaxEntropy correctly identified most of the kinetochores.
	run("Select None");
	//run("Threshold...");
	//setThreshold(1700, 30000);
	setAutoThreshold("MaxEntropy dark");

// Evaluate the kinetochore selection
	title = "Image treatment evaluation";
	msg = "Image evaluation. If necessary, use threshold to optimize kinetochore slection, then click \"OK\" to continue.";
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
close();close();
