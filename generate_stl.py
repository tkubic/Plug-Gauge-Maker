import os
import subprocess
import pandas as pd
from tkinter import Tk, Radiobutton, StringVar, Button, Label
from tkinter.filedialog import askopenfilename
from concurrent.futures import ThreadPoolExecutor
import uuid

# Define the OpenSCAD template file and the output directory
template_file = 'template.scad'
output_dir = 'STL'
os.makedirs(output_dir, exist_ok=True)

# Function to prompt for file if not found
def prompt_for_file():
    Tk().withdraw()  # We don't want a full GUI, so keep the root window from appearing
    file_path = askopenfilename(title="Select the Excel file", filetypes=[("Excel files", "*.xlsx")])
    if file_path:  # If a file is selected
        return file_path
    else:
        raise FileNotFoundError("No file selected")

# Function to prompt for worksheet using radio buttons
def prompt_for_worksheet(sheet_names):
    root = Tk()
    root.title("Select Worksheet")

    selected_sheet = StringVar()
    selected_sheet.set(sheet_names[0])  # Set default selection

    Label(root, text="Select the worksheet to process:").pack(anchor='w')
    for sheet_name in sheet_names:
        Radiobutton(root, text=sheet_name, variable=selected_sheet, value=sheet_name).pack(anchor='w')

    def on_submit():
        root.quit()

    submit_button = Button(root, text="Submit", command=on_submit)
    submit_button.pack(pady=20)

    root.mainloop()
    root.destroy()

    return selected_sheet.get()

# Try to read the Excel file, prompt if not found
excel_file = 'values.xlsx'
if not os.path.exists(excel_file):
    print(f"File {excel_file} not found. Please select the file.")
    excel_file = prompt_for_file()

# Read the available sheet names
xls = pd.ExcelFile(excel_file)
sheet_names = xls.sheet_names
print(f"Available sheets: {sheet_names}")

# Prompt the user to select one worksheet
selected_sheet = prompt_for_worksheet(sheet_names)
print(f"Selected sheet: {selected_sheet}")

# Function to generate STL from OpenSCAD
def generate_stl(plug_diameter, plug_handle_length, plug_overall_length, output_file):
    # Read the template file
    with open(template_file, 'r') as file:
        scad_content = file.read()

    # Debugging: Print the values being replaced
    print(f"Generating STL with: plug_diameter={plug_diameter}, plug_handle_length={plug_handle_length}, plug_overall_length={plug_overall_length}")

    # Replace placeholders with actual values
    scad_content = scad_content.replace('.782', str(plug_diameter))
    scad_content = scad_content.replace('2.0123', str(plug_handle_length))
    scad_content = scad_content.replace('3.0123', str(plug_overall_length))

    # Generate a unique temporary OpenSCAD file name
    temp_scad_file = f'temp_{uuid.uuid4().hex}.scad'
    with open(temp_scad_file, 'w') as file:
        file.write(scad_content)

    # Full path to OpenSCAD executable
    openscad_path = r'C:\Program Files\OpenSCAD\openscad.exe'

    # Call OpenSCAD to generate the STL file
    subprocess.run([openscad_path, '-o', output_file, temp_scad_file], check=True)

    # Remove the temporary OpenSCAD file
    os.remove(temp_scad_file)

def process_row(index, row):
    plug_diameter = row['plug_diameter']
    plug_handle_length = row['plug_handle_length']
    plug_overall_length = row['plug_overall_length']

    # Check if any value is NaN
    if pd.isna(plug_diameter) or pd.isna(plug_handle_length) or pd.isna(plug_overall_length):
        print(f"Skipping row {index + 1} due to NaN values in sheet '{selected_sheet}'.")
        return
    
    # Define the output STL file name based on the parameter values
    output_file = os.path.join(output_dir, f'{plug_diameter}_{plug_handle_length}_{plug_overall_length}.stl')
    
    # Generate the STL file
    generate_stl(plug_diameter, plug_handle_length, plug_overall_length, output_file)

# Read the specified worksheet from the Excel file
df = pd.read_excel(excel_file, sheet_name=selected_sheet, usecols=[0, 1, 2], skiprows=2, header=None, names=["plug_diameter", "plug_handle_length", "plug_overall_length"])

# Debugging: Print the DataFrame to ensure it is read correctly
print(f"DataFrame read from sheet '{selected_sheet}':")
print(df)

# Use ThreadPoolExecutor to parallelize the processing of rows
with ThreadPoolExecutor() as executor:
    list(executor.map(lambda row: process_row(*row), df.iterrows()))

print(f'STL files have been generated in the {output_dir} directory')
