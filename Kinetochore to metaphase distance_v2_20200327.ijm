// Distance of all kinetochores to the Metaphase line by Luciano G. Braga
// v1 
// 27-March-2020
// Macro for imageJ2 (Fiji)
// This macro will find the pole positioning automatically or manually, and then calculate a theoretical metaphase line. Then it will find the kinetochores automatically
// or manually and calculate their distance to the metaphase line. It will outputs the spindle length and a table containing the distance of each kinetochore to the metaphase
// line. The spindle length can be used to normalize the distance. The distances are given in pixels.



// Open images, first for the poles then kinetochores
	title = "Images open";
	msg = "Please make sure the first opened image is immunostained for the poles and the second opened image for the kinetochoresI.";
	waitForUser(title, msg);
	selectImage(1);
	run("Select None");
	Poles_image = getTitle();
	selectImage(2);
	run("Select None");
	Kinetochores_image = getTitle();



// Isolate the cell excluding all that is outside
	selectImage(Poles_image);
	run("Select None");
	setTool("oval");
	title = "Cell selection";
	msg = "Please select the desired cell, then click \"OK\".";
	waitForUser(title, msg);
	roiManager("Add");
	run("Select None");
	
	
// Get the pole coordinates
	// Isolat the cell in the image for the poles
	selectImage(Poles_image);
	roiManager("Select",0);
	run("Clear Outside");
	selectImage(Kinetochores_image);
	roiManager("Select",0);
	run("Enlarge...", "enlarge=2");
	run("Clear Outside");
	
	//Ask if should try to get the poles automatically
	selectImage(Poles_image);
	run("Select None");
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
	selectImage(Poles_image);
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
	

//Finding the kinetochores

	//Ask if should try to get the KTs automatically
	
	Dialog.create("Automatically detect kinetochores?");
	Dialog.addCheckbox("Yes.", true);
    Dialog.show();
    Auto = Dialog.getCheckbox();
    if (Auto==true){
    
    // Filter image. If the function threshold does not result in a clear posiitoning of the kinetochore signal, try setting the threshold manually and using the same value for all images.
	// To use the a specific set threshold, substitute the setAuroThreshold function for: run("Threshold...");
	// For the images analyzed, the auto threshold using the function MaxEntropy correctly identified most of the kinetochores.
	selectImage(Kinetochores_image);
	run("Select None");
	//run("Threshold...");
	//setThreshold(1700, 30000);
	run("Convolve...", "text1=[-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 24 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n] normalize");
	selectImage(Kinetochores_image);
	roiManager("Select",0);
	run("Clear Outside");
	setAutoThreshold("MaxEntropy dark"); // Delete this line if Threshold will be set manually
	
	// Evaluate the kinetochore selection.
	title = "Image treatment evaluation";
	msg = "Threshold evaluation. Press Shift+T to change the threshold if necessary. Click \"OK\" to continue.";
	waitForUser(title, msg);
    run("Make Binary");
    run("Set Measurements...", "area mean min centroid display redirect=None decimal=3");
    run("Analyze Particles...",  "size=15-Infinity circularity=0.2-1.00 show=[Overlay Masks] ");
    X_KT=newArray(nResults);
    Y_KT=newArray(nResults);
    for (row=0; row<(nResults); row++) { 
    
    X_KT[row]=getResult("X",row);
    Y_KT[row]=getResult("Y",row);
    }
	Nb_KT=lengthOf(X_KT);
	
    };
    
    //Get the KTs manually
    
	if (Auto==false){ 
	selectImage(Kinetochores_image);
	run("Select None");
	setTool("multipoint");
	title = "Select  kinetochores";
	msg = "Please select the kinetochores with the multipoint tool, then click \"OK\".";
	waitForUser(title, msg);
	getSelectionCoordinates(X_KT, Y_KT);
	Nb_KT=lengthOf(X_KT);
 	}

// Calculate the distance to the line that identifies
// the metaphase plate
// knowing the midpoint and that the slope of the metaphase is
// -1/slope_spindle, one can calculate the b from the line equation of the
// metaphase plate
	a_spindle=(yp2-yp1)/(xp2-xp1);

	slope_metaphase=-1/a_spindle;
	b_metaphase=(yp2/2)+(yp1/2)-(((xp2/2)+(xp1/2))*((xp1-xp2)/(yp2-yp1)));

//Distance of a point to a line
Dist_KT = newArray(Nb_KT);
for (row=0; row<Nb_KT; row++) { 
    
    Dist_KT[row]=(abs((X_KT[row]*slope_metaphase)-Y_KT[row]+b_metaphase))/sqrt(pow(slope_metaphase,2)+1);

 }


//Calculate the spindle lenghth

spindlelength= sqrt(pow((xp2-xp1),2)+pow((yp2-yp1),2));

// Show results

print("Spindle length");
print(spindlelength);

	// Print the distance of each KT
	run("Set Measurements...", "area mean centroid display redirect=None decimal=3");
	for (i=0; i<Nb_KT;i++) {
		setResult("Distance to Metaphase in pixels", i, Dist_KT[i]);
	}
	updateResults();



// Clear ROI cache 
	roiManager("deselect");
	roiManager("delete");

