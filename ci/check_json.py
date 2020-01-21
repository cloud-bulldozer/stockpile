#!/usr/bin/env python

import argparse
import sys
import os
import json


def _is_json(input_file):
    my_json = json.load(open(input_file,'r'))
    my_key = list(my_json.keys())
    for i in range(len(my_key)):
        for key in my_json[my_key[i]].keys():
            if "stockpile_" in key and "stockpile_output_path" not in key and "stockpile_user" not in key:
               print(my_key[i],key)
               print(json.dumps(my_json[my_key[i]][key], indent=4))
    

def main():
    parser = argparse.ArgumentParser(description="Stockpile JSON validator")
    parser.add_argument(
        '-i', '--input',
        help='Provide JSON input file location')
    args = parser.parse_args()

    _is_json(args.input)

if __name__ == '__main__':
    sys.exit(main())
