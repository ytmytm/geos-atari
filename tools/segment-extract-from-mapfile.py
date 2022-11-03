#!/usr/bin/python3

import pdb
import re
import pprint
import argparse
from ortools.linear_solver import pywraplp

def parse_mapfile(fname = "kernal.map", verbose=True):
    with open(fname,'r') as f:
        lines = f.readlines()

    linenum = 0
    for l in lines:
        if "Segment list:" in l:
            startline = linenum + 4
        if "Exports list by name:" in l:
            endline = linenum - 2
        linenum = linenum+1

#   for l in range(startline,endline):
#       print(lines[l].strip())

    segments = []

    for l in range(startline,endline):
        items = re.split("\s+",lines[l].strip())
        seg = {
             'name' : items[0].strip()
             ,'start' : int(items[1],16)
             ,'length' : int(items[3],16)
        }
        if seg['start'] < 0x9580: # not 9d80 because for starter I might keep them just above DRIVE
            if verbose:
                print(f"\tskipping {seg['name']} because it's in boot/bank0 space")
        elif seg['start'] >= 0xfe80:
            if verbose:
                print(f"\tskipping {seg['name']} because it's in input driver space")
        else:
            segments.append(seg)
    return segments
"""
pprint.pprint(segments)
print("extracting segment 'time1'")
for k in segments:
    if k['name'] == 'time1':
        segments.remove(k)
pprint.pprint(segments)
"""

"""Solve a multiple knapsack problem using a MIP solver."""

# additional constraints (subtract these sizes from relevant bins and remove these segments from consideration)
# - bank_jmptab_front   KERNALHL    ($d800)
# - header              KERNALHDR   ($c000)
# - jumptab             KERNALL     ($c100)
# - init1,init2,hw1b,ramexp2    LOKERNAL    ($9D80)


def calculate(segments,verbose=True):

    data = {}
    data['bin_capacities'] = [ 0x0280   ,0x0088 ,0x0100        ,0x0f00        ,0x400         ,0x2170        ,0x00f0]
    data['bin_labels'] =     ['LOKERNAL','ICONS','KERNALHDR'   ,'KERNALL'     ,'KERNALHL'    ,'KERNALH'     ,'CIAGAP']
    data['bin_loadlabels'] = ['LOKERNAL','ICONS','KERNALHDRREL','KERNALRELOCL','KERNALRELOHL','KERNALRELOCH','CIAGAPRELOC']
    assert len(data['bin_capacities']) == len(data['bin_labels'])
    assert len(data['bin_labels']) == len(data['bin_loadlabels'])

    # additional constraints, few segments must be in specific RAM areas
    new_segments = []
    for k in segments:
        if k['name']=='bank_jmptab_front':
            data['bin_capacities'][4] = data['bin_capacities'][4] - k['length'] # KERNALHL
        elif k['name']=='header':
            data['bin_capacities'][2] = data['bin_capacities'][2] - k['length'] # KERNALHDR
        elif k['name']=='jumptab':
            data['bin_capacities'][3] = data['bin_capacities'][3] - k['length'] # KERNALL
        elif k['name'] in ['init1','init2','hw1b','ramexp2']:
            data['bin_capacities'][0] = data['bin_capacities'][0] - k['length'] # LOKERNAL
        else:
            new_segments.append(k)

    data['segmentlabels'] = [ x['name'] for x in new_segments ]
    data['weights'] = [ x['length'] for x in new_segments ]
    data['values'] = data['weights']

    assert len(data['weights']) == len(data['values'])
    data['num_items'] = len(data['weights'])
    data['all_items'] = range(data['num_items'])

    data['num_bins'] = len(data['bin_capacities'])
    data['all_bins'] = range(data['num_bins'])

    # Create the mip solver with the SCIP backend.
    solver = pywraplp.Solver.CreateSolver('SCIP')
    if solver is None:
        print('SCIP solver unavailable.')
        return

    # Variables.
    # x[i, b] = 1 if item i is packed in bin b.
    x = {}
    for i in data['all_items']:
        for b in data['all_bins']:
            x[i, b] = solver.BoolVar(f'x_{i}_{b}')

    # Constraints.
    # Each item is assigned to at most one bin.
    for i in data['all_items']:
        solver.Add(sum(x[i, b] for b in data['all_bins']) <= 1)

    # The amount packed in each bin cannot exceed its capacity.
    for b in data['all_bins']:
        solver.Add(
            sum(x[i, b] * data['weights'][i]
                for i in data['all_items']) <= data['bin_capacities'][b])

    # Objective.
    # Maximize total value of packed items.
    objective = solver.Objective()
    for i in data['all_items']:
        for b in data['all_bins']:
            objective.SetCoefficient(x[i, b], data['values'][i])
    objective.SetMaximization()

    status = solver.Solve()

    if status == pywraplp.Solver.OPTIMAL:
        if verbose:
            print(f'Total packed value: {objective.Value()}')
        total_weight = 0
        for b in data['all_bins']:
            if verbose:
                print(f"Bin {data['bin_labels'][b]}")
            bin_weight = 0
            bin_value = 0
            for i in data['all_items']:
                if x[i, b].solution_value() > 0:
                    if verbose:
                        print(
                            f"\t{data['segmentlabels'][i]}\t weight: {data['weights'][i]}"
                        )
                    else:
                        print(
                            f"{data['segmentlabels'][i]}:\tload = {data['bin_loadlabels'][b]}, run = {data['bin_labels'][b]}, type = ro;"
                    )
                    bin_weight += data['weights'][i]
                    bin_value += data['values'][i]
            if verbose:
                print(f"Packed bin weight:\t{format(bin_weight,'04x')}")
                print(f"Packed bin capacity:\t{format(data['bin_capacities'][b],'04x')}")
                print(f"Capacity wasted:\t{format(data['bin_capacities'][b]-bin_weight,'04x')}")
            total_weight += bin_weight
        total_cap = sum(data['bin_capacities'])
        if verbose:
            print()
            print(f"Total packed weight:\t{format(total_weight,'04x')}")
            print(f"Total bin capacity:\t{format(total_cap,'04x')}")
            print(f"Capacity remaining:\t{format(total_cap-total_weight,'04x')}")
    else:
        print('The problem does not have an optimal solution.')


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Analyze .map file from ld65 and optimize segment arrangement to memory areas')
    parser.add_argument("--map","-m",type=str,help=".map file generated by ld65",default="build/atari_320/kernal/kernal.map")
    parser.add_argument("--verbose","-v",help="verbose output",action='store_true',default=False)

    args = parser.parse_args()

    segments = parse_mapfile(args.map,args.verbose)
    calculate(segments,args.verbose)

