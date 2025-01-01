/* [Accuracy Settings] */
// Define fragment angle and size 
// number of facets for cylinders
//$fn = 75;
// Minimum angle for each fragment 
$fa = 3; 
// Minimum size for each fragment
$fs = .1; 

/* [Plug Size] */

// Plug Diameter
plug_diameter = PLUG_DIAMETER; // in inches
// Plug handle length
plug_handle_length = PLUG_HANDLE_LENGTH; // in inches
// Plug overall length
plug_overall_length = PLUG_OVERALL_LENGTH; // in inches

/*
// Plug Diameter
plug_diameter = 1.75; // in inches
// Plug handle length
plug_handle_length = 2; // in inches
// Plug overall length
plug_overall_length = 3; // in inches
*/

/* [Lip Parameters] */
lip_size = 0.1; // in inches
lip_threshold = 0.25; // in inches


// extra standoff length in inches
holder_standoff_length = 1; // extra standoff length in inches
// Define the dimensions of the cube
cube_width = ceil((plug_diameter + 0.8) * 2) / 2 * 25.4; 
cube_height = ceil((plug_diameter + 0.8) * 2) / 2 * 25.4;
cube_depth = 6*25.4;//(plug_overall_length - plug_handle_length + holder_standoff_length) * 25.4; // convert to mm


hole_clearance = 0.075; // in inches
// Define the diameter of the hole
hole_diameter_mm = (plug_diameter + hole_clearance) * 25.4; // convert to mm

/* [Chamfer Parameters] */
// Define the chamfer parameters
chamfer_width = 4; // 4 mm larger than the hole radius
chamfer_angle = 45; // Chamfer angle in degrees
chamfer_depth = chamfer_width * tan(chamfer_angle); // Depth of the chamfer in mm
chamfer_r2 = (hole_diameter_mm / 2) + chamfer_width; // r2 is 4 mm larger than the hole radius

/* [Magnet Parameters] */
// Define the magnet size. Width, Thickness, Height
Magnet_size_small = [10,5,65]; // bar magnet
//Clearance for magnet (width, thickness, depth)
magnet_clearance = [1,0,3]; //clearance for magnet
mc = magnet_clearance;
//Magnet distance from the edge
edge_distance = 3; //distance from the edge

/* [Hidden] */
cube_size = [cube_width, cube_height, cube_depth];
cube_center = [0, 0, 0];

module create_cube_with_chamfered_hole_and_lip() {
    difference() {
        // Create the main cube
        translate(cube_center)
            cube(cube_size, center = true);

        // Create the centered hole
        translate(cube_center)
            cylinder(h = cube_depth + 1, d = hole_diameter_mm, center = true);

        // Create the cone for the chamfer
        translate([0, 0, cube_depth / 2 - chamfer_depth])
            cylinder(h = chamfer_depth, r1 = hole_diameter_mm / 2, r2 = chamfer_r2, center = false);

        // Add the slot to the bottom of the cube
        translate([0, -cube_height/2+Magnet_size_small[1]/2+edge_distance, -cube_depth/2+Magnet_size_small[2]/2+mc[2]/2-.01])
            cube([Magnet_size_small[0]+mc[1],Magnet_size_small[1],Magnet_size_small[2]+mc[2]], center = true);
    }
    
    // Add the lip if plug_diameter is greater than 0.25 inches
    if (plug_diameter > lip_threshold) {
        lip_size_mm = lip_size * 25.4; // height of the lip in mm
        //lip_diameter = (plug_diameter - 0.25) * 25.4; // diameter of the lip in mm
        
        difference() {
            // Create the main lip cylinder
            translate([0, 0, -cube_depth / 2])
                cylinder(h = cube_depth - (plug_overall_length - plug_handle_length+1) * 25.4, d = hole_diameter_mm);
            
            // Subtract the inner cylinder to create the lip
            translate([0, 0, -cube_depth / 2])
                cylinder(h = cube_depth - (plug_overall_length - plug_handle_length+1) * 25.4, d = hole_diameter_mm - lip_size_mm);
        }
    }
}

// Generate the cube with the chamfered hole and lip
create_cube_with_chamfered_hole_and_lip();

// Add text to the top of the cube
module add_text_to_top() {
    // Define the text parameters
    text_value = str(plug_diameter);
    text_height = 0.6; // height of the text in mm
    text_size = 5; // size of the text
    text_font = "Arial Rounded MT Bold:style=Regular"; // specify the font

    // Position the text on top of the cube
    translate([0, -cube_height / 2 + text_size / 2 + 1, cube_depth / 2])
        linear_extrude(height = text_height)
            text(text_value, size = text_size, valign = "center", halign = "center", font = text_font);
}

// Call the module to add the text
add_text_to_top();