#!/usr/bin/python

import random
import sys

SAVING = {
    'STR': 1,
    'DEX': 5,
    'CONST': 2,
    'INTEL': 0,
    'WIS': 4,
    'CHAR': -1,
    'INIT': 3
}

WEAPONS = {
    'SHORTSWORD': {
        'HIT': 5,
        'DAM': {
            'd': 6,
            'mod': 3
        }
    },
    'LONGBOW': {
        'HIT': 5,
        
    }
}

for s in SAVING.keys():
    print "%s -> %s" %(s, random.randint(1, 20) + SAVING[s])
