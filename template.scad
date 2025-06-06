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
plug_diameter = .782; // in inches
// Plug handle length
plug_handle_length = 2.0123; // in inches
// Plug overall length
plug_overall_length = 3.0123; // in inches

/* [Text Parameters] */
text_thickness = 0.6; // height of the text in mm
text_size = 6; // size of the text
text_font = "Arial Rounded MT Bold:style=Regular"; // specify the font
use_input_text = false; // Set to true to use input text, false to use formula
input_text_value = "Custom Text"; // Input text value

/* [Other] */
include_plug_gauge = true; // Set to false to exclude the plug gauge
include_baseplate = false; // Set to true to include the baseplate
// Option to include the additional bowtie
include_additional_bowtie = false; // Set to true to include the additional bowtie
extend_top_height_inch = 2;
extend_top_height = extend_top_height_inch * 25.4; // in mm
hole_clearance = .075; // in inches
// Define the diameter of the hole
hole_diameter_mm = (plug_diameter + hole_clearance) * 25.4; // convert to mm
baseplate_angle = 38; // Define angle in degrees

/* [Hidden] */
// Lip Parameters
lip_size = 1.2; // in inches
lip_threshold = 0.5; // in inches

// Define the chamfer parameters
chamfer_width = 4; // 4 mm larger than the hole radius
chamfer_angle = 45; // Chamfer angle in degrees
chamfer_depth = chamfer_width * tan(chamfer_angle); // Depth of the chamfer in mm
chamfer_r2 = (hole_diameter_mm / 2) + chamfer_width; // r2 is 4 mm larger than the hole radius

// Define the dimensions of the cube
cube_width = max(ceil((hole_diameter_mm + chamfer_width * 2 + 5) / (25.4 * 0.5)) * (25.4 * 0.5), 25.4); // Round up to nearest 0.5 inch in mm
cube_height = ceil((hole_diameter_mm + text_size * 2 + chamfer_width * 2 + 5) / 25.4) * 25.4; // Round up to nearest inch in mm
cube_depth = 6 * 25.4; // in mm
cube_size = [cube_width, cube_height, cube_depth];
cube_center = [0, 0, 0];


bowtie_width_top = 30; // Top width of the bowtie in mm
bowtie_width_bottom = 14; // Bottom width of the bowtie in mm
bowtie_height = 6; // Height of the bowtie in mm
bowtie_offset = 50; // Offset of the bowtie in mm
bowtie_chamfer = 3; 

bowtie_height_top = cube_height / tan(baseplate_angle);

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

// Add text to the top of the cube
module add_text_to_top() {
    // Define the text parameters
    plug_diameter_str = str(plug_diameter*10000);
    text_value = use_input_text ? input_text_value : 
        (plug_diameter < .1) ? str(".0", plug_diameter_str) : 
        ((plug_diameter < 1) ? str(".", plug_diameter_str) : 
        str(plug_diameter));

    // Position the text on top of the cube
    translate([0, -cube_height / 2 + text_size / 2 +1, cube_depth / 2 + extend_top_height])
        linear_extrude(height = text_thickness)
            text(text_value, size = text_size, valign = "center", halign = "center", font = text_font);
}

/* [Dovetail Parameters] */
dovetail_width = 50; // Width of the dovetail in mm
dovetail_height = 10; // Height of the dovetail in mm

module create_dovetail() {
    translate([cube_width/2, -cube_height / 2+dovetail_height, 0])
        rotate([180, 90, 0])
            linear_extrude(height = cube_width)
                polygon(points=[
                    [0, 0],
                    [dovetail_width, 0],
                    [dovetail_width - dovetail_height, dovetail_height],
                    [-dovetail_height, dovetail_height]
                ]);
}

// Define the bowtie polygon as a static variable
bowtie_polygon = [
    [-bowtie_width_top / 2, -bowtie_height / 2],
    [bowtie_width_top / 2, -bowtie_height / 2],
    [bowtie_width_bottom / 2, bowtie_height / 2],
    [bowtie_width_top / 2, bowtie_height * 1.5],
    [-bowtie_width_top / 2, bowtie_height * 1.5],
    [-bowtie_width_bottom / 2, bowtie_height / 2]
];

// Add bowtie cutout
module add_bowtie_cutout() {
    translate([-cube_width / 2, cube_height / 2 - bowtie_height / 2, bowtie_offset - bowtie_height_top])
        rotate([90, 90, 90])
            linear_extrude(height = cube_width)
                polygon(points = bowtie_polygon);
                
    translate([-cube_width / 2, -cube_height / 2 - bowtie_height / 2, bowtie_offset])
        rotate([90, 90, 90])
            linear_extrude(height = cube_width)
                polygon(points = bowtie_polygon);

    // Add cube cutout at the same location as both polygons
     translate([0, cube_height / 2 , bowtie_offset - bowtie_height_top])
        rotate([90, 90, 90])
        cube([bowtie_width_bottom+bowtie_chamfer*2, bowtie_height*2,cube_width ], center = true);
        
     translate([0, -cube_height / 2 , bowtie_offset])
        rotate([90, 90, 90])
        cube([bowtie_width_bottom+bowtie_chamfer*2, bowtie_height*2,cube_width ], center = true);
}

// [Baseplate Bowtie Parameters]
bowtie_tolerance = 0.1; // Tolerance for bowtie/dovetail fit (mm)
baseplate_bowtie_chamfer = 3; // Chamfer size at the top of the dovetail (mm)

// Module to create the dovetail/bowtie shape with offset applied
module baseplate_bowtie() {
    difference() {
        translate([0, -bowtie_tolerance, 0])
            linear_extrude(height = cube_depth) // Use cube_depth for extrusion height
                offset(delta = -bowtie_tolerance)
                    polygon(points = [
                        [-(bowtie_width_bottom/2), 0],
                        [(bowtie_width_bottom/2), 0],
                        [(bowtie_width_top/2), bowtie_height],
                        [-(bowtie_width_top/2), bowtie_height]
                    ]);
        // Cut a square at the top right edge
        translate([bowtie_width_top/2 - baseplate_bowtie_chamfer, 0, 0])
            linear_extrude(height = cube_depth)
                square([bowtie_height, bowtie_height], center = false);
        // Cut a square at the top left edge (mirrored on y axis)
        translate([-(bowtie_width_top/2 - baseplate_bowtie_chamfer) - bowtie_height, 0, 0])
            linear_extrude(height = cube_depth)
                square([bowtie_height, bowtie_height], center = false);
    }
}

// Module to create a right triangle baseplate with a subtracted square and attached bowtie/dovetail
module baseplate_with_bowtie() {
    // Calculate triangle points
    a = 8 * 25.4 * cos(baseplate_angle); // triangle_hypotenuse = 8*25.4
    b = 8 * 25.4 * sin(baseplate_angle);
    dovetail_offset = 3*25.4+50; // cube depth / 2 +50mm
    dir_x = cos(baseplate_angle);
    dir_y = sin(baseplate_angle);
    place_x = a - dovetail_offset * dir_x;
    place_y = 0 + dovetail_offset * dir_y;
    
    // Combine baseplate and bowtie/dovetail
    union() {
        // Baseplate triangle with subtracted square
        linear_extrude(height = cube_depth)
            difference() {
                polygon(points = [
                    [0, 0],
                    [a, 0],
                    [0, b]
                ]);
                // Subtract a square starting at (a-50, 0) with height b
                translate([a-50, 0, 0])
                    square([50, b], center = false);
            }
        // Place and rotate the bowtie/dovetail
        translate([place_x, place_y, 0])
            rotate([0, 0, -baseplate_angle])
                difference() {
                    translate([0, -bowtie_tolerance, 0])
                        linear_extrude(height = cube_depth)
                            offset(delta = -bowtie_tolerance)
                                polygon(points = [
                                    [-(bowtie_width_bottom/2), 0],
                                    [(bowtie_width_bottom/2), 0],
                                    [(bowtie_width_top/2), bowtie_height],
                                    [-(bowtie_width_top/2), bowtie_height]
                                ]);
                    // Cut a square at the top right edge
                    translate([bowtie_width_top/2 - baseplate_bowtie_chamfer, 0, 0])
                        linear_extrude(height = cube_depth)
                            square([bowtie_height, bowtie_height], center = false);
                    // Cut a square at the top left edge (mirrored on y axis)
                    translate([-(bowtie_width_top/2 - baseplate_bowtie_chamfer) - bowtie_height, 0, 0])
                        linear_extrude(height = cube_depth)
                            square([bowtie_height, bowtie_height], center = false);
                }
    }
}

// Draw the combined baseplate and bowtie/dovetail as one object at the desired position, only if include_baseplate is true
if (include_baseplate) {
    translate([cube_width/2 + 50, 0, 0])
        baseplate_with_bowtie();
}

// Extend the top of the cube
module extend_top() {
    translate([-cube_width/2,  -cube_height/2 , cube_depth / 2])
        cube([cube_width, text_size+2.5, extend_top_height], center = false);
}
// Combine the modules
difference() {
    union() {
        if (include_plug_gauge) {
            create_cube_with_chamfered_hole_and_lip();
            add_text_to_top();
            extend_top();
        }
    }
    add_bowtie_cutout();
}

// Add the additional bowtie if include_additional_bowtie is true
if (include_additional_bowtie) {
    translate([cube_width / 2 + bowtie_width_top/2+ 5, 0, 0])
        linear_extrude(height = cube_width)
            polygon(points = bowtie_polygon);
}