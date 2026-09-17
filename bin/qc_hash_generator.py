"""
Nazi Zombies: Portable QuakeC CRC generator

Takes input .CSV files and outputs an FTEQCC-compilable
QuakeC struct with its contents, always assumes the first
entry should be IBM 3740 CRC16 hashed, adding its length
as an entry as well, for collision detection.
"""

import argparse
import pandas as pd
from pathlib import Path
from fastcrc import crc16
from colorama import Fore, Style


COL_BLUE = Fore.BLUE
COL_RED = Fore.RED
COL_YEL = Fore.YELLOW
COL_GREEN = Fore.GREEN
COL_NONE = Style.RESET_ALL


def main():
    global args
    parser = argparse.ArgumentParser(description='IBM 3740 CRC16 hash generator in FTE QuakeC-readable data structure.')
    parser.add_argument('-i', '--input_file', help='.CSV input file to parse.', required=True)
    parser.add_argument('-o', '--output_file', help='File name for generated .QC file.', default='hashes.qc')
    parser.add_argument('-n', '--struct_name', help='Name of the struct generated.', default='asset_conversion_table')
    args = parser.parse_args()

    input_file = Path(args.input_file).resolve()
    assert input_file.exists(), f'{COL_RED}Error{COL_NONE}: Input .CSV file does not exist. Exiting.'
    output_file = Path(args.output_file).resolve()
    
    # -------------------------------------------------------------------------
    # Parse CSV, calculate CRC, sort 
    # -------------------------------------------------------------------------
    csv_data_df = pd.read_csv(input_file)
    # Add `hash` column by hashing values in `old_path` column
    csv_data_df['hash'] = [int(crc16.ibm_3740(str.encode(path))) for path in csv_data_df['old_path']]
    # Add `length` column by taking strlen of `old_path` column
    csv_data_df['length'] = [len(path) for path in csv_data_df['old_path']]
    # Order df in ascending order by hash
    csv_data_df = csv_data_df.sort_values(by='hash')
    # -------------------------------------------------------------------------
    
    
    # -------------------------------------------------------------------------
    # Write to QC file
    # -------------------------------------------------------------------------
    # Template QC file content to fill in
    output_file_content_template = """var struct {{
    float old_path_crc;
    string current_path;
    float crc_strlen;
}} asset_conversion_table[] = {{
{entry_rows}}};
"""
    entry_rows_str = ''
    
    # Add first (n-1) rows with trailing comma
    for _,row_vals in csv_data_df[:-1].iterrows():
        entry_rows_str += f'\t{{ {row_vals.hash}, "{row_vals.current_path}", {row_vals.length}}}, \t// {row_vals.old_path}\n'

    # Add last row without trailing comma
    row_vals = csv_data_df.iloc[-1]
    entry_rows_str += f'\t{{ {row_vals.hash}, "{row_vals.current_path}", {row_vals.length}}} \t// {row_vals.old_path}\n'
    
    # Fill in the template
    output_file_content = output_file_content_template.format(entry_rows=entry_rows_str) 

    with output_file.open('w') as f:
        f.write(output_file_content)
    # -------------------------------------------------------------------------
    

if __name__ == '__main__':
    main()