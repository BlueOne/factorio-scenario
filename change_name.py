#!/usr/bin/env python3
# file: rename.py
# Rename the parent directory to reflect the mod-info version name. 

import json
import os


cwd = os.path.dirname(os.path.abspath(__file__))

with open(os.path.join(cwd, 'info.json')) as f:
    mod_info = json.load(f)

name = mod_info["name"]
version = mod_info["version"]

dest = os.path.join(cwd, '..', name + '_' + version)
os.rename(cwd, dest)
