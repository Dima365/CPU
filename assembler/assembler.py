mnem_opcode = [ 'addi',   'or',     'and',    'add',    'beq',    'slt',
                'sub',    'sw',     'lw',     'j',      'jr',     'jrek',
                'movc0',  'movrf',  'nop'] 
opcode      = [ '001000', '000000', '000000', '000000', '000100', '000000',
                '000000', '101011', '100011', '000010', '110000', '111000',
                '111100', '010000', '110001']

mnem_Rcom = ['or',     'and',    'add',    'slt',    'sub'   ]
funct     = ['100101', '100100', '100000', '101010', '100010']


list_reg = ['$0',  '$at', 
            '$v0', '$v1', 
            '$a0', '$a1', '$a2', '$a3',
            '$t0', '$t1', '$t2', '$t3', '$t4', '$t5', '$t6', '$t7'
            '$s0', '$s1', '$s2', '$s3', '$s4', '$s5', '$s6', '$s7'
            '$t8', '$t9',
            '$k0', '$k1',
            'gp',  'sp',  'fp',  'ra']

list_reg_c0 = ['km', 'cr', 'epc', 'pt']

def Rtype(line): # для команд R типа 
    com_list = []
    for reg in [line[2], line[3], line[1]]:        
        for i in range(0,len(list_reg)):
            if reg == list_reg[i]:
                com_list.append(format(i, '05b'))
    com_list.append('00000')
    for i in range(0,len(mnem_Rcom)):
        if line[0] == mnem_Rcom[i]:
            com_list.append(funct[i])
    return com_list    

def Itype(line): # для команд I типа, но не для beq
    com_list = []
    for reg in [line[2], line[1]]:        
        for i in range(0,len(list_reg)):
            if reg == list_reg[i]:
                com_list.append(format(i, '05b'))
    if line[3].find('-') != -1:
        str = ''
        var = line[3][1:]
        var = format(int(var), '016b')
        for i in range(0, 16):
            str += '0' if int(var[i]) else '1'
        var = int(str, 2) + 1
        com_list.append(format(var, '016b'))            
    else:
        com_list.append(format(int(line[3]), '016b')) 
    return com_list

def beq_com(line): # только для beq
    com_list = []
    for reg in [line[1], line[2]]:        
        for i in range(0,len(list_reg)):
            if reg == list_reg[i]:
                com_list.append(format(i, '05b'))

    for i in range (0, len(mark_list)):
        if (line[3]+':') == mark_list[i]:
            str = ''
            shamt = addr_com[i] - current_line_number
            if shamt < 0:
                shamt = shamt * -1
                shamt = format(int(shamt), '016b')
                for i in range(0, 16):
                    str += '0' if int(shamt[i]) else '1'
                shamt = int(str, 2) + 1
                com_list.append(format(shamt,'016b'))                
            else:
                com_list.append(format(shamt, '016b')) 
    return com_list

def lw_sw_com(line): # для работы с памятью (lw и sw)
    com_list = []
    reg = line[2][line[2].find('(')+1 : line[2].find(')')]
    for i in range (0, len(list_reg)):
        if reg == list_reg[i]:
            com_list.append(format(i, '05b'))
    reg = line[1]
    for i in range (0, len(list_reg)):
        if reg == list_reg[i]:
            com_list.append(format(i, '05b'))                
    if line[2][:line[2].find('(')].find('-') != -1:
        str = ''
        var = line[2][1:line[2].find('(')]
        var = format(int(var), '016b')
        for i in range(0, 16):
            str += '0' if int(var[i]) else '1'
        var = int(str, 2) + 1
        com_list.append(format(var,'016b'))            
    else:
        com_list.append(format(int(line[2][:line[2].find('(')]), '016b')) 
    return com_list


def Jtype(line): # j команда 
    com_list = []
    for i in range (0, len(mark_list)):
        if (line[1]+':') == mark_list[i]:
            addr_jump = addr_com[i] << 2
            addr_jump = format(int(addr_jump), '032b')        
            addr_jump = addr_jump[4:30]
            com_list.append(addr_jump)
    return com_list

def jrCom(line):   # jr прыжок по регистру, 
    com_list = []  # а также для прыжка с выходом из реж.ядра 
    reg = line[1]     
    for i in range(0,len(list_reg)):
        if reg == list_reg[i]:
            com_list.append(format(i, '05b'))
    com_list.append(format(0, '021b'))
    return com_list

def movrfCom(line): # переместить в рег.файл
    com_list = []  
    reg = line[1]     
    for i in range(0,len(list_reg_c0)):
        if reg == list_reg_c0[i]:
            com_list.append(format(i, '05b'))
    reg = line[2]
    for i in range(0,len(list_reg)):
        if reg == list_reg[i]:
            com_list.append(format(i, '05b'))
    com_list.append(format(0, '016b'))
    return com_list

def movc0fCom(line): # переместить в c0
    com_list = []  
    reg = line[1]     
    for i in range(0,len(list_reg)):
        if reg == list_reg[i]:
            com_list.append(format(i, '05b'))
    reg = line[2]
    for i in range(0,len(list_reg_c0)):
        if reg == list_reg_c0[i]:
            com_list.append(format(i, '05b'))
    com_list.append(format(0, '016b'))
    return com_list         

def nopCom(line):   # nop ничего не делать 
    com_list = []       
    com_list.append(format(0, '026b'))
    return com_list

def prepare_line(line):  # читает строку из файла и разбивает на элементы
    line = line.rstrip() # пример: add $s2 $t1 $t2 - строка в файле
    line = line.lstrip() # функция возращает список ['add','$s2','$t1','$t2']
    i = 0 
    while line[i] == ' ':
        line = line[1:]
    while line[len(line)-1] == ' ':
        line = line[:-1]
    i = 1
    while i < len(line)-1:
        if line[i] == ' ' and line[i+1] == ' ':
            line = line[:i+1] + line[i+2:]
        else:
            i += 1
    line = line.split(' ')
    return line    


# первый проход текста для поиска меток перехода 
# записываем метки в список mark_list
# addr_com список адресов переходов

file_read  = input()
#file_read  = 'cod.txt' # времено 
f_read     = open(file_read)
file_write = input()
#file_write  = 'memfile.dat'
f_write    = open(file_write, 'wt')

i = 0
mark_list = []
addr_com  = [] 
for line in f_read:
    if line.find(':') != -1:
        line = prepare_line(line)
        mark_list.append(line[0])
        addr_com.append(i)
    else:
        i = i + 1
f_read.close()

# второй проход текста для ассемблирования
f_read     = open(file_read)
current_line_number = 0
for line in f_read:
    com_list = []
    check = 0
    line = prepare_line(line)
    
    if line[0].find(':') != -1:
        continue    
    

    for i in range(0, len(mnem_opcode)):
        if line[0] == mnem_opcode[i]:
            com_list.append(opcode[i])
            check = 1
            break            
    if check == 0:
        f_write.write('error: unidentified command' + '\n')
        exit(0)        
    
    current_line_number = current_line_number + 1
    if com_list[0] == '000000':
        com_list = com_list + Rtype(line)
        command  = ''.join(com_list)
        f_write.write(format(int(command, 2), '08x') + '\n')        
    elif com_list[0] == '001000':
        com_list = com_list + Itype(line)
        command  = ''.join(com_list)
        f_write.write(format(int(command, 2), '08x') + '\n')    
    elif com_list[0] == '000100':
        com_list = com_list + beq_com(line)
        command  = ''.join(com_list)
        f_write.write(format(int(command, 2), '08x') + '\n')
    elif com_list[0] == '101011' or com_list[0] == '100011':
        com_list = com_list + lw_sw_com(line)
        command  = ''.join(com_list)
        f_write.write(format(int(command, 2), '08x') + '\n')
    elif com_list[0] == '000010':
        com_list = com_list + Jtype(line)
        command  = ''.join(com_list)
        f_write.write(format(int(command, 2), '08x') + '\n')
    elif com_list[0] == '110000':# различие в opcode
        com_list = com_list + jrCom(line)
        command  = ''.join(com_list)
        f_write.write(format(int(command, 2), '08x') + '\n')
    elif com_list[0] == '111000': # различие в opcode 
        com_list = com_list + jrCom(line)
        command  = ''.join(com_list)
        f_write.write(format(int(command, 2), '08x') + '\n')
    elif com_list[0] == '010000':
        com_list = com_list + movrfCom(line)
        command  = ''.join(com_list)
        f_write.write(format(int(command, 2), '08x') + '\n')
    elif com_list[0] == '111100':
        com_list = com_list + movc0fCom(line)
        command  = ''.join(com_list)
        f_write.write(format(int(command, 2), '08x') + '\n')
    elif com_list[0] == '110001':
        com_list = com_list + nopCom(line)
        command  = ''.join(com_list)    
        f_write.write(format(int(command, 2), '08x') + '\n')

    
    
