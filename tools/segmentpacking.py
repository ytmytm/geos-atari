#!/usr/bin/python3

"""Solve a multiple knapsack problem using a MIP solver."""
from ortools.linear_solver import pywraplp

# parse data info from kernal.map segment list
# - ignore any BANK0 entries
# additional constraints (subtract these sizes from relevant bins and remove these segments from consideration)
# - bank_jmptab_front   KERNALH     ($d800)
# - header              KERNALHDR   ($c000)
# - jumptab             KERNALL     ($c100)
# - init1,init2,hw1b    LOKERNAL    ($9D80)


def main():
    data = {}
    data['segmentlabels'] = [ 'dlgbox1h'
     ,'dlgbox1j'
      ,'dlgbox1k'
       ,'files1a2a'
        ,'serial1'
         ,'displaylist'
          ,'files2'
           ,'init1'
            ,'hw1b'
             ,'init2'
              ,'keyboard1'
               ,'keyboard3'
                ,'ramexp2'
                 ,'mouseptr'
                  ,'dlgbox1i'
                   ,'header'
                    ,'tobasic2'
                     ,'mainloop1'
                      ,'dlgbox2'
                       ,'jumptab'
                        ,'math1b'
                         ,'fonts2'
                          ,'fonts3'
                           ,'fonts4'
                            ,'fonts4a'
                             ,'graph3a'
                              ,'graph3b'
                               ,'graph3c'
                                ,'conio1'
                                 ,'conio2'
                                  ,'conio3a'
                                   ,'conio3b'
                                    ,'conio4'
                                     ,'conio6'
                                      ,'math2'
                                       ,'bank_jmptab_front'
                                        ,'banking'
                                         ,'files1a2b'
                                          ,'files1b'
                                           ,'mainloop3'
                                            ,'bitmask1'
                                             ,'bitmask2'
                                              ,'bitmask3'
                                               ,'files3'
                                                ,'load1a'
                                                 ,'load1b'
                                                  ,'load1c'
                                                   ,'load1d'
                                                    ,'graph1'
                                                     ,'memory1a'
                                                      ,'memory1b'
     ,'misc'
      ,'load2'
       ,'graph2b'
        ,'graph2d'
         ,'graph2f'
          ,'graph2h'
           ,'inline'
            ,'graph2j'
             ,'graph2k'
              ,'graph2l1'
               ,'graph2l2'
                ,'graph2m'
                 ,'process1'
                  ,'process2'
                   ,'process3a'
                    ,'process3aa'
                     ,'process3b'
                      ,'process3c'
                       ,'sprites'
                        ,'math1a1'
                         ,'math1a2'
                          ,'math1c2'
                           ,'math1d'
                            ,'memory2'
                             ,'mouse1'
                              ,'panic1'
                               ,'panic2'
                                ,'panic3'
                                 ,'serial2'
                                  ,'fonts1'
                                   ,'bswfont'
                                    ,'memory3'
                                     ,'load3'
                                      ,'files6a'
                                       ,'files6b'
                                        ,'files6c'
                                         ,'deskacc1'
                                          ,'load4b'
                                           ,'deskacc2'
                                            ,'deskacc3'
                                             ,'files8'
                                              ,'files9'
                                               ,'files10'
                                                ,'init4'
                                                 ,'fonts4b'
                                                  ,'mouse2'
                                                   ,'menu1'
                                                    ,'menu2'
                                                     ,'menu3'
                                                      ,'icon1'
                                                       ,'mouse3'
                                                        ,'icon2'
                                                         ,'dlgbox1a'
                                                          ,'dlgbox1b'
                                                           ,'dlgbox1c'
                                                            ,'dlgbox1d'
                                                             ,'dlgbox1e1'
                                                              ,'dlgbox1e2'
                                                               ,'dlgbox1f'
                                                                ,'dlgbox1g'
                                                                 ,'mouse4'
                                                                  ,'irq'
                                                                   ,'time1'
 ]
    data['weights'] = [
 339
     ,421
      ,322
       ,12
        ,3
         ,210
          ,8
           ,14
            ,170
             ,62
              ,60
               ,79
                ,74
                 ,24
                  ,35
                   ,27
                    ,30
                     ,22
                      ,168
                       ,471
                        ,163
                         ,1071
                          ,148
                           ,33
                            ,5
                             ,82
                              ,46
                               ,204
                                ,355
                                 ,57
                                  ,19
                                   ,75
                                    ,372
                                     ,137
                                      ,58
                                       ,55
                                        ,64
                                         ,156
                                          ,127
                                           ,15
                                            ,7
                                             ,8
                                              ,16
                                               ,14
                                                ,98
                                                 ,15
                                                  ,9
                                                   ,50
                                                    ,19
                                                     ,38
                                                      ,56
 ,29
  ,92
   ,24
    ,12
     ,12
      ,15
       ,50
        ,19
         ,179
          ,83
           ,62
            ,28
             ,105
              ,63
               ,68
                ,26
                 ,38
                  ,81
                   ,388
                    ,11
                     ,11
                      ,13
                       ,55
                        ,247
                         ,44
                          ,78
                           ,10
                            ,18
                             ,13
                              ,256
                               ,744
                                ,18
                                 ,112
                                  ,181
                                   ,29
                                    ,281
                                     ,141
                                      ,33
                                       ,11
                                        ,27
                                         ,202
                                          ,126
                                           ,1127
                                            ,61
                                             ,103
                                              ,412
                                               ,521
                                                ,11
                                                 ,509
                                                  ,51
                                                   ,27
                                                    ,284
                                                     ,132
                                                      ,38
                                                       ,243
                                                        ,239
                                                         ,48
                                                          ,38
                                                           ,11
                                                            ,73
                                                             ,76
                                                              ,168
                                                               ,142
    ]
    data['values'] = data['weights']

    assert len(data['weights']) == len(data['values'])
    data['num_items'] = len(data['weights'])
    data['all_items'] = range(data['num_items'])

    data['bin_capacities'] = [0x280     ,0x88   ,0x100         ,0xf00         , 0x2680]
    data['bin_labels'] =     ['LOKERNAL','ICONS','KERNALHDR'   ,'KERNALL'     ,'KERNALH']
    data['bin_loadlabels'] = ['LOKERNAL','ICONS','KERNALHDRREL','KERNALRELOCL','KERNALREOCH']
    assert len(data['bin_capacities']) == len(data['bin_labels'])
    assert len(data['bin_labels']) == len(data['bin_loadlabels'])

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
        print(f'Total packed value: {objective.Value()}')
        total_weight = 0
        for b in data['all_bins']:
            print(f"Bin {data['bin_labels'][b]}")
            bin_weight = 0
            bin_value = 0
            for i in data['all_items']:
                if x[i, b].solution_value() > 0:
                    print(
                        f"\t{data['segmentlabels'][i]}\t weight: {data['weights'][i]}"
                    )
#                    print(
#                        f"{data['segmentlabels'][i]}:\tload = {data['bin_loadlabels'][b]}, run = {data['bin_labels'][b]}, type = ro;"
#                    )
                    bin_weight += data['weights'][i]
                    bin_value += data['values'][i]
            print(f"Packed bin weight:\t{format(bin_weight,'04x')}")
            print(f"Packed bin capacity:\t{format(data['bin_capacities'][b],'04x')}")
            print(f"Capacity wasted:\t{format(data['bin_capacities'][b]-bin_weight,'04x')}")
            total_weight += bin_weight
        total_cap = sum(data['bin_capacities'])
        print(f"Total packed weight:\t{format(total_weight,'04x')}")
        print(f"Total bin capacity:\t{format(total_cap,'04x')}")
        print(f"Capacity remaining:\t{format(total_cap-total_weight,'04x')}")
    else:
        print('The problem does not have an optimal solution.')


if __name__ == '__main__':
    main()
