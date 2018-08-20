#!/usr/bin/env python
import re as _re
from subprocess import check_output
import json
import sys
# Simple test to ensure the dictionary is correctly built
def verify_bios_vendor(dmidecode_input):
    try:
        bios_vendor_value = dmidecode_input['BIOS_Information'][0]['Vendor']
    except (IndexError, ValueError) as e:
        print ("Parsing error, dictionary incorrectly built")
        return False
    args = ["dmidecode","--quiet","-s","bios-vendor"]
    args = " ".join(args)
    try:
        expected_bios_vendor = _execute_cmd(args)
    except:
        print ("error occured running dmidecode")
        return False
    # Removing whitespaces
    if "".join(expected_bios_vendor.split()) == "".join(bios_vendor_value.split()):
        return True
    else:
        # If the 2 vars don't match, it means that either dictionary isn't built
        # the way it was intended, or could be because dmidecode isn't working
        # the way it's supposed to
        # Both of which imply that this code is not acheieving desired output
        return False

def _parse(dmide_fullinput):
    output_data = {}
    #in case of output such as
    #   BIOS Information
    #      Vendor: LENOVO
    #      ROM Size: 16 MB
    #      Characteristics:
	# 	        PCI is supported
    # 	        PNP is supported
    #    	    BIOS is upgradeable
    # The values for Characteristics can't be made into a key: val easily,
    # Thus instead of making Characteristics an array, resorted to a simple str
    # This is what the next line does
    dmide_fullinput = dmide_fullinput.replace('\n\t\t',' ')
    split_output = dmide_fullinput.replace('\t','').split('\n\n')
    if len(split_output)<=1:
        sys.exit(1)
    for record in split_output:
        split_lines = record.split('\n')
        for x in range(len(split_lines)):
            # There are cases where the value has leading whitespaces
            # And also removing multiple whitespaces in general
            split_lines[x] = _re.sub(r":\s\s+",": ", split_lines[x])
            split_lines[x] = _re.sub(r"\s\s+","", split_lines[x])
        if split_lines[0]!="" and len(split_lines)>=2:
            # Dealing with keys having whitespaces
            split_lines[0] = split_lines[0].replace(' ','_')
            if split_lines[0] not in output_data:
                output_data[split_lines[0]] = []
            current_dict = {}
            # splitting only on first occurence as some fields can have multiple
            # example
        	# String 1: PSF:
        	# String 2: Product ID: 670635-S01
            for s in split_lines[1:]:
                if ': ' in s:
                    key_val = s.split(': ',1)
                else:
                    continue
                if len(key_val) <= 1:
                    key_val.append("None")
                current_dict[key_val[0].replace(' ','_')]=key_val[1]
            output_data[split_lines[0]].append(current_dict)
    return output_data

def parse():
    args = ["dmidecode"]
    args.append("--quiet")
    args = " ".join(args)
    data_output = _execute_cmd(args)
    _data = _parse(data_output)
    return _data

def _execute_cmd(args):
    p1 = check_output(args, shell=True).decode("utf-8")
    return p1

def main():
    dmidecode_dict = parse()
    if isinstance(dmidecode_dict, dict) and verify_bios_vendor(dmidecode_dict):
        print (json.dumps(dmidecode_dict, sort_keys=True, indent=2))
        return 0
    print ("There seems to be a parsing error")
    return 1

if __name__ == '__main__':
    sys.exit(main())
