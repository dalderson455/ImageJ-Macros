//Background Subtraction Macro
// Subtracts average or median of last N frames from entire stack
// Options: crop FOV, choose number of frames, average vs median
// Aimed at removing interference patterns or other weird background that does not fade 

//original image
originalImageName = getTitle();
originalImage = getTitle();
selectWindow(originalImage);

//dimensions
getDimensions(width, height, channels, slices, frames);

totalFrames = frames;
if (totalFrames <= 1) {
    totalFrames = slices; // fallback to slices if frames = 1
}

if (totalFrames <= 5) {
    exit("Need at least 6 frames in the stack!");
}

// User options
Dialog.create("Background Subtraction Options");
Dialog.addCheckbox("Crop image first?", false);
Dialog.addNumber("Number of background frames:", 50);
Dialog.addChoice("Projection type:", newArray("Average Intensity", "Median Intensity"), "Average Intensity");
Dialog.addMessage("Average: best for stable background, max noise reduction | Median: robust to outliers/hot pixels");
Dialog.show();

doCrop = Dialog.getCheckbox();
numBgFrames = Dialog.getNumber();
projectionType = Dialog.getChoice();

// wrong frame bailout
if (numBgFrames > totalFrames) {
    exit("Number of background frames (" + numBgFrames + ") exceeds total frames (" + totalFrames + ")!");
}

// optional crop
if (doCrop) {
    setTool("rectangle");
    waitForUser("Select ROI to crop", "\nClick OK when ready.");
    
    if (selectionType() == -1) {
        exit("No selection made. Macro cancelled.");
    }
    
    run("Duplicate...", "duplicate");
    
    // Close original, work with crop
    selectWindow(originalImage);
    close();
    
    originalImage = getTitle();
    selectWindow(originalImage);
    
    // Update dimensions
    getDimensions(width, height, channels, slices, frames);
    totalFrames = frames;
    if (totalFrames <= 1) {
        totalFrames = slices;
    }
}

//User defined frame window
firstBgFrame = totalFrames - numBgFrames + 1;
lastBgFrame = totalFrames;

print("Background Subtraction");
print("Total frames: " + totalFrames);
print("Using frames " + firstBgFrame + " to " + lastBgFrame + " for background");
print("Projection type: " + projectionType);

// Duplicate last N frames
run("Duplicate...", "duplicate frames=" + firstBgFrame + "-" + lastBgFrame);
bgStack = getTitle();

//Z projection
selectWindow(bgStack);
if (projectionType == "Median Intensity") {
    run("Z Project...", "projection=Median");
} else {
    run("Z Project...", "projection=[Average Intensity]");
}
bgProjection = getTitle();

// Subtract background from original stack
imageCalculator("Subtract create 32-bit stack", originalImage, bgProjection);
resultImage = getTitle();
selectWindow(bgStack);
close();
selectWindow(bgProjection);
close();

// Rename and show
selectWindow(resultImage);
newName = "PP_" + originalImageName;
rename(newName);

print("Background subtraction completed");