###########################################################################################
## A python script to parse the generated transctip file and analyze the cache transactions 
###########################################################################################
import matplotlib.pyplot as plt

name = 'transcript'
file_name = '../{}'.format(name)
trgt_string = '[dut_driver]'
cycle_time = 10; 

def filter_lines(file_path, target_str):
    lines=[]
    with open (file_path, 'r') as file: 
        for line in file: 
            if target_str in line: 
                lines.append(line.strip())
    return lines

lines = filter_lines(file_name, trgt_string)
#for l in lines: 
#    print(l)

def parse_line(line):
    if '<<' not in line: 
        return None
    else: 
        info = {}
        if 'Received' in line: 
            info['waiting'] = True
        else: 
            info['waiting'] = False
        print(line)
        words = line.split('@')[1].split(':')
        info['time'] = int(words[0])
        info['cycle'] = int(info['time']/cycle_time)
        line = line.split('<<')[1]
        line = line.split('>>')[0]
        words = line.split(',')
        for w in words:
            #print(w)
            k, v = w.split(':')
            k = k.lstrip()
            k = k.rstrip()
            v = v.lstrip()
            v = v.rstrip()
            info[k] = v; 
        return info

events = []     
for l in lines: 
    info = parse_line(l)
    if info: 
        events.append(info)


def color_map(e):
    if e['opcode'] in ['READ_SHARED', 'WRITE_BACK_FULL', 'READ_NO_SNP', 'WRITE_NO_SNP_FULL']: 
        return 'blue'
    elif e['opcode'] in ['COMP_ACK', 'DBID_RESP', 'COMP_DBID_RESP', 'SNP_RESP']:
        return 'green'
    elif e['opcode'] in ['SNP_CLEAN_INVALID']:
        return 'red'
    elif e['opcode'] in ['COMP_DATA', 'NON_COPY_BACK_WR_DATA', 'SNP_RSP_DATA', 'COPY_BACK_WR_DATA']: 
        return 'orange'
    else:
        return 'black'


def plot_events(events): 
    tmax = events[-1]['time']
    #fig, ax = plt.subplots(figsize=(15, 0.1*tmax))
    fig, ax = plt.subplots(figsize=(10, 0.06*tmax))
    xticks = []
    yticks=range(0,-tmax-10, -10)
    for e in events: 
        #print(e)
        if not e['waiting']: 
            print(e)
            y = -e['time']
            x0 = int(e['src id'])
            if x0 not in xticks: 
                xticks.append(x0)
            x1 = int(e['tgt id'])
            txt = 'C{}, {}, TXN:{}'.format(e['cycle'], e['opcode'], e['txn id'])
            if 'addr' in e.keys(): 
                txt += ', Addr: {}'.format(e['addr'])
            if 'data' in e.keys(): 
                txt += ', Data: ...{}'.format(e['data'][-5:-1])
            if x1>x0: 
                h_align = 'left'
            else: 
                h_align = 'right'
            clr = color_map(e)
            ax.text(x0, y, '   '+txt+'   ', ha=h_align, va='bottom', fontsize=12, color=clr)
            ax.arrow(x0, y, x1-x0, 0, head_width=2, head_length=2, width=0.3, length_includes_head=True, color=clr)
    
    
    ax.set_xticks(xticks)
    ax.set_yticks(yticks)
    ax.vlines(xticks, -tmax*1.1, 0, colors='black', lw = 2)
    ax.set_xlabel('node ids')
    ax.set_ylabel('time')
    ax.set_xlim(-1,70)
    ax.set_ylim(-tmax*1.02,0)
    ax.yaxis.grid()
    

    plt.show()
    #plt.savefig('generated_diagram_{}.png'.format(name))

plot_events(events)
