// Import the extended basic cup script
use <modules/module_gridfinity_cup.scad>;

/* [General Settings] */
width = 4; // .1 
depth = 3; // .1
height = 13; // .1

chamfer_height_in = 0.08; // Chamfer height in inches
chamfer_height_mm = chamfer_height_in * 25.4;

/* [Hole Settings] */
// Paste your hole_data from excel here
// hole data format: [[x, y, diameter, depth], ...]
hole_data = [[-1.7515,0,2.603,2.63],[0.65845,0.80845,1.2169,1.5],[0.65845,-0.80875,1.2175,1.5],[2.2753,0.80845,1.2168,1.5],[2.2753,-0.80875,1.2172,1.5]];

hole_shift = [0, 0]; // Shift holes by this amount in X and Y

/* [Other Options] */
half_pitch = false;

/* [Hidden] */
// [Hidden] - gridfinity_bin.scad compatibility
// These are required for gridfinity_cup
enable_magnets = false;
lip_style = "none";
filled_in = "enabled";
render_position = "center"; //[default,center,zero]
enable_screws = false;
magnet_easy_release = "off";
screw_size = [3, 6];
hole_overhang_remedy = 2;
floor_thickness = 0.7;
cavity_floor_radius = -1;
efficient_floor = "off";
flat_base = "off";
spacer = false;
flat_base_rounded_radius = -1;
flat_base_rounded_easyPrint = -1;
fa = 1;
fs = 0.4;
fn = 0;
force_render = true;
minimum_printable_pad_size = 0.2;
text_font = "Aldo";

module end_of_customizer_opts() {}

//Some online generators do not like direct setting of fa,fs,fn
$fa = fa; 
$fs = fs; 
$fn = fn;  

magnet_size = [6.5, 2.4];
center_magnet_size = [0,0];
box_corner_attachments_only = true;
text_1 = false;
text_2 = false;
text_2_text = "";
text_size = 0;
text_depth = 0.3;

// Cylinder cutouts from hole_data string using BOSL2



module cylinder_cutouts() {
    for (i = [0 : len(hole_data)-1]) {
        hole = hole_data[i];
        xpos = hole[0]*25.4+ hole_shift[0];
        ypos = hole[1]*25.4+ hole_shift[1];
        diameter = hole[2]*25.4;
        depth = hole[3]*25.4;
        zpos = height*7 - depth/2;
        // Main cylinder
        translate([xpos, ypos, zpos])
            cylinder(h=depth, d=diameter, center=true);
        // Chamfer (cone) at top edge
        if (chamfer_height_mm > 0) {
            translate([xpos, ypos, zpos + depth/2 - chamfer_height_mm/2])
                cylinder(h=chamfer_height_mm, d1=diameter, d2=diameter + 2*chamfer_height_mm, center=true);
        }
    }
}


// Main model: subtract cylinder from cup
render(convexity = 2)
// Main model: subtract cylinder from cup
difference() {
    set_environment(
        width = width,
        depth = depth,
        height = height,
        render_position = render_position,
        force_render = force_render
    )
    gridfinity_cup(
        width=width, depth=depth, height=height,
        filled_in=filled_in,
        lip_settings = LipSettings(
            lipStyle = lip_style,
            lipSideReliefTrigger = [1,1],
            lipTopReliefHeight = -1,
            lipTopReliefWidth = -1,
            lipNotch = false,
            lipClipPosition = "disabled",
            lipNonBlocking = false
        ),
        cupBase_settings = CupBaseSettings(
            magnetSize = enable_magnets?magnet_size:[0,0],
            magnetEasyRelease = magnet_easy_release, 
            centerMagnetSize = center_magnet_size, 
            screwSize = enable_screws?screw_size:[0,0],
            holeOverhangRemedy = hole_overhang_remedy, 
            cornerAttachmentsOnly = box_corner_attachments_only,
            floorThickness = floor_thickness,
            cavityFloorRadius = cavity_floor_radius,
            efficientFloor=efficient_floor,
            halfPitch=half_pitch,
            flatBase=flat_base,
            spacer=spacer,
            minimumPrintablePadSize=minimum_printable_pad_size,
            flatBaseRoundedRadius = flat_base_rounded_radius,
            flatBaseRoundedEasyPrint = flat_base_rounded_easyPrint
        ),
        cupBaseTextSettings = CupBaseTextSettings(
            baseTextLine1Enabled = text_1,
            baseTextLine2Enabled = text_2,
            baseTextLine2Value = text_2_text,
            baseTextFontSize = text_size,
            baseTextFont = text_font,
            baseTextDepth = text_depth
        )
    );
    // Subtract all holes
    cylinder_cutouts();
}
