

inDir = getDirectory("Choose Directory Containing Files ");

fileList = getFileList(inDir);
run("Set Measurements...", "area limit display redirect=None decimal=2");

//Set Threshold for all Images//
run("Close All", "");
run("Clear Results");
roiManager("reset");

//Set size Value for Exclusion of small particles 
//in um^2
Exclude=300;


numb=0;
//Exclude non image files//

for (i=0; i<fileList.length; i++) {
	
	file = inDir + fileList[i];
	Run = 1;
	matching=(endsWith(file, ".csv"));
	if (matching==1) Run=0;	
	matching=(endsWith(file, "_overlay.tif"));
	if (matching==1) Run=0;
	matching=(endsWith(file, "_Original.tif"));
	if (matching==1) Run=0;

	//exit
	matching=(endsWith(file, "segment_CH2.tif"));
	if (matching==1) Run=0;
	matching=(endsWith(file, ".xls"));
	if (matching==1) Run=0;
	matching=(endsWith(file, ".txt"));
	if (matching==1) Run=0;
	matching=(endsWith(file, ".zip"));
	if (matching==1) Run=0;
	matching=(endsWith(file, "Merge.tif"));
	if (matching==1) Run=0;
	matching=(endsWith(file, "Area.tif"));
	if (matching==1) Run=0;

	print(Run);
	//exit
	if (Run==0){}
	else {
	//Open files//
		//open(file);
		setBatchMode(false);
		run("Bio-Formats Importer", "open=file");
		run("Properties...", "channels=3 slices=1 frames=1 unit=micron pixel_width=2.58 pixel_height=2.58 voxel_depth=1.0000");
		print(file);
		Namelong=fileList[i];
		getDimensions(width, height, channels, slices, frames); 
		//exit
		inFileCut = lengthOf(Namelong)-4; 
  		Name=substring(Namelong,0,inFileCut);
		print(Name);
//exit	

	//Split Channels and perform Filtering//
		roiManager("reset");
		roiManager("Show All");
		//run("Subtract Background...", "rolling=50 stack");
		run("Duplicate...", "duplicate");
		rename("Original");
		//exit
	
	//Mark Regions that should be removed	
		selectWindow(Namelong);
 		waitForUser("Please mark regions to remove, add them to the ROI Manager pressing \"t\", then click OK.");

	//Switch to batch mode
  		setBatchMode("hide");
  		setBatchMode(true);

	//Split the two channels		
		run("Split Channels");
		
	//Create Mask for Border exclusion
		selectWindow("C3-"+Namelong);
		run("Auto Local Threshold", "method=Phansalkar radius=15 parameter_1=0 parameter_2=0 white");
		run("Options...", "iterations=8 count=1 black do=Close");
		run("Duplicate...", "duplicate");

	//Clear ROIS from Manager creating Hole Mask
		ROIcount=roiManager("count");
		for(r=0; r<ROIcount; r++){
			roiManager("Select", r);
			setBackgroundColor(0, 0, 0);
			run("Clear", "slice");
		}
		roiManager("reset");
		run("Select None");
		rename("Mask_Holes");

	//Fill up Holes for Creating Outer and Inner Mask
		selectWindow("C3-"+Namelong);
		run("Fill Holes");
		run("Options...", "iterations=10 count=1 black do=Erode");
		rename("Mask_total");
		run("Duplicate...", "duplicate");
		rename("Mask_inner");

//exit
	//Shrink Mask for creating Ring
		setAutoThreshold("Triangle dark stack");	
		run("Set Measurements...", "area limit display redirect=None decimal=2");
		run("Measure");
		resetThreshold();
		Area=getResult("Area",0);
		AreaNew=Area/3;
		a=Area;
		print(Area);
		print(AreaNew);
		print(a);

		for(;a>=AreaNew;) {
			run("Clear Results");	
			selectWindow("Mask_inner");
			run("Options...", "iterations=10 count=2 black do=Erode");
			setAutoThreshold("Triangle dark stack");	
			run("Set Measurements...", "area limit display redirect=None decimal=2");
			run("Measure");
			a=getResult("Area",0);
		}
//exit
	//Create different Masks and add selections to ROI manager 
		imageCalculator("XOR create", "Mask_total","Mask_inner");
		rename("Mask_outer");
		//exit
		imageCalculator("AND", "Mask_outer","Mask_Holes");    
		setAutoThreshold("Triangle dark stack");
		run("Create Selection");
		roiManager("Add");
		selectWindow("Mask_inner");
		imageCalculator("AND", "Mask_inner","Mask_Holes");
		setAutoThreshold("Triangle dark stack");
		run("Create Selection");
		roiManager("Add");
		imageCalculator("AND", "Mask_total","Mask_Holes");

//exit
	//close("Mask_inner");
		selectWindow("Mask_total");
		run("Divide...", "value=255");
		run("Clear Results");

		selectWindow("Original");
		roiManager("Show All");
		saveAs("TIFF", file+"_Original");
		
	//Measure Mask area
		selectWindow("Mask_total");
		setThreshold(1, 255);
		run("Measure");

		selectWindow("Mask_inner");
		setThreshold(1, 255);
		run("Measure");

		selectWindow("Mask_outer");
		setThreshold(1, 255);
		run("Measure");

		roiManager("reset");
		//exit
		

		
//exit
		
	//Filter Channel1//	
		selectWindow("C1-"+Namelong);
		CH1=getImageID();
		run("Bandpass Filter...", "filter_large=20 filter_small=4 suppress=None tolerance=5 autoscale");
		rename("Filtered_CH1");
		//exit
		//run("16-bit");
		resetMinAndMax();
		//run("Invert", "stack");
		setAutoThreshold("Triangle dark stack");
		//waitForUser("Set manual Threshold");


	//Exclude small Objects
		setOption("BlackBackground", true);
		run("Analyze Particles...", "size="+Exclude+"-Infinity add");
		Nmbr=roiManager("count");
		N=Array.getSequence(Nmbr);
		Array.print(N);
		roiManager("select", 1);
		//exit
		run("Clear Outside");
				//exit
 		if(Nmbr>0){
 			for(e=0; e<Nmbr; e++){
 			roiManager("select", e);
 			run("Fill", "slice");	
 			}
 		}
		roiManager("reset");
		run("Select None");
		//exit
		imageCalculator("Multiply create", "Filtered_CH1", "Mask_total");
		rename("Mask_CH1");
		//run("Create Selection");
		//roiManager("Add");
		setAutoThreshold("Triangle dark stack");
	
		run("Measure");
		resetThreshold();
		close("Filtered_CH1");
		print("numb = "+numb);
		numb=numb+1;

	//Filter Channel2//
		selectWindow("C2-"+Namelong);
		CH2=getImageID();
		//setSlice(slices/2);
		//exit
		
		//resetMinAndMax();
		//run("FeatureJ Laplacian", "compute smoothing=2");
		run("Bandpass Filter...", "filter_large=20 filter_small=4 suppress=None tolerance=5 autoscale");
		rename("Filtered_CH2");

		//run("16-bit");
		resetMinAndMax();
		//run("Invert", "stack");
		setAutoThreshold("Triangle dark stack");
		//waitForUser("Set manual Threshold");
		//roiManager("reset");
//exit

	//Exclude small Objects
		setOption("BlackBackground", true);
		run("Analyze Particles...", "size="+Exclude+"-Infinity add");
		//exit
		Nmbr=roiManager("count");
		N=Array.getSequence(Nmbr);
		Array.print(N);
		roiManager("select", 1);
		
		run("Clear Outside");
				//exit
 		if(Nmbr>0){
 			for(e=0; e<Nmbr; e++){
 			roiManager("select", e);
 			run("Fill", "slice");	
 			}
 		}
 		
 		//exit
		roiManager("reset");
		run("Select None");
		imageCalculator("Multiply create", "Filtered_CH2", "Mask_total");
		rename("Mask_CH2");
		//run("Create Selection");
		setAutoThreshold("Triangle dark stack");
		run("Measure");
		//exit
		resetThreshold();
		close("Filtered_CH2");
		//run("Convert to Mask");


	//Restore ROIs of Masks
		selectWindow("Mask_outer");
		run("Create Selection");
		roiManager("Add");
		selectWindow("Mask_inner");
		run("Create Selection");
		roiManager("Add");
		close();
		selectWindow("Mask_total");
		close();	
		selectWindow("Mask_Holes");
		close();		
		

	//Save Merged Channels
		run("Merge Channels...", "c1=[Mask_CH1] c2=[Mask_CH2] create keep");
		roiManager("Show All");
		saveAs("TIFF", file+"_overlay");
		close();


	//Measure Overlap
		imageCalculator("AND create", "Mask_CH1","Mask_CH2");
		rename("Overlap");
		//run("Create Selection");
		//roiManager("Add");
		setAutoThreshold("Triangle dark stack");
		run("Measure");
//exit
	//Measure Inner Region
		selectWindow("Mask_CH1");
		run("Duplicate...", " ");
		rename("Mask_CH1_inner");
		roiManager("Select", 1);
		run("Clear Outside");
		setAutoThreshold("Triangle dark stack");
		run("Measure");
		//close("Mask_CH1_inner");

		selectWindow("Mask_CH2");
		run("Duplicate...", " ");
		rename("Mask_CH2_inner");
		roiManager("Select", 1);
		run("Clear Outside");
		setAutoThreshold("Triangle dark stack");
		run("Measure");
		//close("Mask_CH2_inner");

		selectWindow("Overlap");
		run("Duplicate...", " ");
		rename("Overlap_inner");
		roiManager("Select", 1);
		run("Clear Outside");
		setAutoThreshold("Triangle dark stack");
		run("Measure");
		//close("Overlap_inner"); 


	//Measure Outer Region
		selectWindow("Mask_CH1");
		run("Duplicate...", " ");
		rename("Mask_CH1_outer");
		roiManager("Select", 0);
		run("Clear Outside");
		setAutoThreshold("Triangle dark stack");
		run("Measure");
		//close("Mask_CH1_outer");

		selectWindow("Mask_CH2");
		run("Duplicate...", " ");
		rename("Mask_CH2_outer");
		roiManager("Select", 0);
		run("Clear Outside");
		setAutoThreshold("Triangle dark stack");
		run("Measure");
		//close("Mask_CH2_outer");

		selectWindow("Overlap");
		run("Duplicate...", " ");
		rename("Overlap_outer");
		roiManager("Select", 0);
		run("Clear Outside");
		setAutoThreshold("Triangle dark stack");
		run("Measure");
		//close("Overlap_outer");
//exit
		saveAs("Results", file+"Areas.xls");
		run("Clear Results");

//exit
	//Measure single Objects in Ch1
		selectWindow("Overlap");
		run("Divide...", "value=255");
		rename("Overlap_in_Ch1_inner");
		roiManager("Reset");
		selectWindow("Mask_CH1_inner");
		run("Set Measurements...", "area integrated limit display redirect=Overlap_in_Ch1_inner decimal=2");
		run("Analyze Particles...", "size=0-Infinity display add");
//exit
		wait(50);
		selectWindow("Overlap_in_Ch1_inner");
		rename("Overlap_in_Ch1_outer");
		//roiManager("Reset");
		selectWindow("Mask_CH1_outer");
		run("Set Measurements...", "area integrated limit display redirect=Overlap_in_Ch1_outer decimal=2");
		run("Analyze Particles...", "size=0-Infinity display add");

	//Save Object ROIs and Results in Ch1
	//	selectWindow("Overlap_in_Ch1_outer");
	//	roiManager("Show All");
		run("Enhance Contrast", "saturated=0.35");
		roiManager("Save", file+"ROIs_Overlap_CH1.zip");
		saveAs("Results", file+"Areas_Objects_inCH1.xls");
		run("Clear Results");

		wait(50);
		selectWindow("Overlap_in_Ch1_outer");
		rename("Overlap_in_Ch2_inner");
		roiManager("Reset");
		selectWindow("Mask_CH2_inner");
		run("Set Measurements...", "area integrated limit display redirect=Overlap_in_Ch2_inner decimal=2");
		run("Analyze Particles...", "size=0-Infinity display add");
		
		wait(50);
		selectWindow("Overlap_in_Ch2_inner");
		rename("Overlap_in_Ch2_outer");
		//roiManager("Reset");
		selectWindow("Mask_CH2_outer");
		run("Set Measurements...", "area integrated limit display redirect=Overlap_in_Ch2_outer decimal=2");
		run("Analyze Particles...", "size=0-Infinity display add");		
		
		wait(50);
	//Save Object ROIs and Results in Ch2		
		roiManager("Save", file+"ROIs_Overlap_CH2.zip");		
		saveAs("Results", file+"Areas_Objects_inCH2.xls");
//exit

	//Save Results		
		//selectWindow("Results");
		//exit
	//	saveAs("Results", file+"Areas_Objects.xls");
		run("Clear Results");	
		roiManager("Reset");

		
	}
	//setOption("ShowRowNumbers", true);
	updateResults;

	//close();

	run("Close All", "");
	//exit
}

setBatchMode(false);
