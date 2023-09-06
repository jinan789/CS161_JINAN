import os

def read_from_file(path):
    with open(path) as f:
        return ''.join(f.readlines())
    
    
def lines_to_str(lines):
    return ''.join([i+'\n' for i in lines])

# TODO: be careful with that the signature range could span multiple lines
# TODO: be careful with that the signature range could span multiple lines
class Code_File:
    
    def __init__(self, code_file_path, address):
        def find_contract_closing_line_ind(s_line_ind, code_lines):
            e_line_ind = s_line_ind
            if code_lines[s_line_ind].endswith('{}'):
                return e_line_ind
            
            
            while True:
                if e_line_ind == len(code_lines):
                    return len(code_lines) - 1
                if code_lines[e_line_ind].startswith('}') and code_lines[e_line_ind].strip() == '}':
                    break
                if code_lines[e_line_ind].strip().startswith('interface ') and e_line_ind > s_line_ind:
                    e_line_ind -= 1
                    break
                if code_lines[e_line_ind].strip().startswith('abstract contract ') and e_line_ind > s_line_ind:
                    e_line_ind -= 1
                    break
                if code_lines[e_line_ind].strip().startswith('library ') and e_line_ind > s_line_ind:
                    e_line_ind -= 1
                    break
                else:
                    e_line_ind += 1
            return e_line_ind

        def find_signature_closing_line_ind(s_line_ind, code_lines):
            e_line_ind = s_line_ind
            while True:
                if e_line_ind == len(code_lines):
                    raise Error('11111')
                if '{' in code_lines[e_line_ind].strip(): 
                    is_pure_sig_backup = False
                    return e_line_ind, is_pure_sig_backup
                elif code_lines[e_line_ind].strip().endswith(';'):
                    is_pure_sig_backup = True
                    return e_line_ind, is_pure_sig_backup
                else:
                    e_line_ind += 1
            


        # note: code_lines is the raw lines
        self.code_lines = read_from_file(code_file_path).split('\n')
        
        self.abstract_contract_line_inds = [ind for ind in range(len(self.code_lines)) if self.code_lines[ind].strip().startswith('abstract contract ')]
        self.contract_line_inds = [ind for ind in range(len(self.code_lines)) if self.code_lines[ind].strip().startswith('contract ')]
        self.function_line_inds = [ind for ind in range(len(self.code_lines)) if self.code_lines[ind].strip().startswith('function ')]
        self.interface_line_inds = [ind for ind in range(len(self.code_lines)) if self.code_lines[ind].strip().startswith('interface ')]
        self.library_line_inds = [ind for ind in range(len(self.code_lines)) if self.code_lines[ind].strip().startswith('library ')]
        self.comment_line_inds = [ind for ind in range(len(self.code_lines)) if self.code_lines[ind].strip().startswith('/*') or self.code_lines[ind].strip().startswith('*')]
        self.empty_line_inds = [ind for ind in range(len(self.code_lines)) if self.code_lines[ind].strip() == '']

        self.all_inds = self.contract_line_inds + self.function_line_inds + self.comment_line_inds + self.empty_line_inds + self.interface_line_inds + self.library_line_inds
        self.non_specified_inds = [ind for ind in range(len(self.code_lines)) if ind not in self.all_inds]
        
        
        self.processed_ranges = dict()
        
        # including abstract contracts, contracts, libraries, and interfaces
        self.contract_lst = []
        for i in self.contract_line_inds:
            e_line_ind = find_contract_closing_line_ind(i, self.code_lines)
            cur_c = Contract(i, e_line_ind, self.code_lines, address)
            self.contract_lst.append(cur_c)
            assert (i, e_line_ind) not in self.processed_ranges
            self.processed_ranges[(i, e_line_ind)] = cur_c
            
        self.abstract_contract_lst = []
        for i in self.abstract_contract_line_inds:
            e_line_ind = find_contract_closing_line_ind(i, self.code_lines)
            cur_c = Contract(i, e_line_ind, self.code_lines, address)
            self.abstract_contract_lst.append(cur_c)
            assert (i, e_line_ind) not in self.processed_ranges
            self.processed_ranges[(i, e_line_ind)] = cur_c
        
        self.interface_lst = []
        for i in self.interface_line_inds:
            e_line_ind = find_contract_closing_line_ind(i, self.code_lines)
            cur_c = Contract(i, e_line_ind, self.code_lines, address)
            self.interface_lst.append(cur_c)
            assert (i, e_line_ind) not in self.processed_ranges
            self.processed_ranges[(i, e_line_ind)] = cur_c
            
        self.library_lst = []
        for i in self.library_line_inds:
            e_line_ind = find_contract_closing_line_ind(i, self.code_lines)
            cur_c = Contract(i, e_line_ind, self.code_lines, address)
            self.library_lst.append(cur_c)
            assert (i, e_line_ind) not in self.processed_ranges
            self.processed_ranges[(i, e_line_ind)] = cur_c
            
        
        
        sorted_items = sorted(list(self.processed_ranges.items()), key = lambda x:x[0])
#         print(sorted_items)
#         print(self.code_lines[104:125])
        for i in range(len(sorted_items) - 1):
#             print(sorted_items[i], sorted_items[i+1])
            assert sorted_items[i][0][1] <= sorted_items[i+1][0][0]

        cur_contract_ind_from_sorted_items = 0
        for i in self.function_line_inds:
#             print(self.code_lines[i])
            e_line_ind, is_pure_sig_backup = find_signature_closing_line_ind(i, self.code_lines)
            
            while True:
#                 print(sorted_items)
#                 print(i, e_line_ind)
#                 print(self.code_lines[i:e_line_ind])
#                 print(sorted_items)
#                 print(self.code_lines[457:470])
                if cur_contract_ind_from_sorted_items == len(sorted_items):
                    raise Exception('111')
                cur_item = sorted_items[cur_contract_ind_from_sorted_items]
                
                
                if i >= cur_item[0][0] and i <= cur_item[0][1]:
                    if e_line_ind > cur_item[0][1]:
                        e_line_ind = cur_item[0][1]
                    break
                else:
                    cur_contract_ind_from_sorted_items += 1
            # note: cur_item is now the item that the function is in range
            is_pure_sig = any([oopp for oopp in self.code_lines[i:e_line_ind+1] if oopp.strip().endswith(';')])
#             print(is_pure_sig)
            if is_pure_sig:
                assert all([not '{' in oopp.strip() for oopp in self.code_lines[i:e_line_ind+1]])
            else:
#                 print(self.code_lines[i:e_line_ind+1])
                assert any(['{' in oopp.strip() for oopp in self.code_lines[i:e_line_ind+1]])
            #print(self.code_lines[i-10:e_line_ind+10])
            assert is_pure_sig_backup == is_pure_sig
            
            new_func = Function_Signature(i, e_line_ind, self.code_lines, is_pure_sig, cur_item[1])
            cur_item[1].function_lst.append(new_func)
#         print([i[0] for i in sorted_items])
        self.sorted_ranges = [i[0] for i in sorted_items]
        self.missed_out_codes_from_contracts_etc_ranges = []
        prev_close = 0
        for r in self.sorted_ranges:
            self.missed_out_codes_from_contracts_etc_ranges.append((prev_close, r[0]-1))
            prev_close = r[1]+1
        self.missed_out_codes_from_contracts_etc_ranges.append((prev_close, len(self.code_lines)-1))
        self.missed_out_codes_from_contracts_etc_ranges = [r for r in self.missed_out_codes_from_contracts_etc_ranges if r[0] <= r[1]]
        
 

class Function_Signature:
    def __init__(self, s_line_num, e_line_num, code_lines, is_pure_sig, within_contract):
        assert e_line_num >= s_line_num
        self.code_lines = code_lines
        self.s_line_num = s_line_num
        self.e_line_num = e_line_num
        self.num_lines = e_line_num - s_line_num + 1
        self.is_pure_sig = is_pure_sig
        self.within_contract = within_contract
        
        if not is_pure_sig:
            self.body_s_ind = e_line_num + 1
            self.body_e_ind = e_line_num + 1
            contract_ending_boundary = within_contract.e_line_num
            seen_opening_bracket_yet = False
            while True:
                if '{' in code_lines[self.body_e_ind]:
                    seen_opening_bracket_yet = True
                if code_lines[self.body_e_ind].strip() == '}' and not seen_opening_bracket_yet:
                    break
                if self.body_e_ind == within_contract.e_line_num:
                    break
                if self.body_e_ind == len(code_lines):
                    self.body_e_ind -= 1
                    break
                if code_lines[self.body_e_ind].strip().startswith('function '):
                    self.body_e_ind -= 1
                    break
                elif code_lines[self.body_e_ind].strip().startswith('contract '):
                    self.body_e_ind -= 1
                    break
                elif code_lines[self.body_e_ind].strip().startswith('abstract contract '):
                    self.body_e_ind -= 1
                    break
                elif code_lines[self.body_e_ind].strip().startswith('interface '):
                    self.body_e_ind -= 1
                    break
                elif code_lines[self.body_e_ind].strip().startswith('library '):
                    self.body_e_ind -= 1
                    break

                else:
                    self.body_e_ind += 1

            self.num_body_char = len(''.join(self.get_body_code_lines()))
        else:
            self.body_s_ind = None
            self.body_e_ind = None
            self.num_body_char = None
        self.num_sig_char = len(''.join(self.get_sig_code_lines()))
        
    def get_sig_code_lines(self):
        return self.code_lines[self.s_line_num:self.e_line_num+1]
    
    def get_body_code_lines(self):
        return self.code_lines[self.body_s_ind:self.body_e_ind+1]
    
    def get_full_code_lines(self):
        return self.get_sig_code_lines() + self.get_body_code_lines()
    
        
class Contract:
    def __init__(self, s_line_num, e_line_num, code_lines, address):
        assert e_line_num >= s_line_num
        self.code_lines = code_lines
        self.s_line_num = s_line_num
        self.e_line_num = e_line_num
        self.num_lines = e_line_num - s_line_num + 1
        self.function_lst = []
        
        self.num_char = len(''.join(self.get_code_lines()))
        
        self.address = address
        
    def get_code_lines(self):
        return self.code_lines[self.s_line_num:self.e_line_num+1]
   
    def get_contract_name(self):
        return self.code_lines[self.s_line_num].strip().split(' ')[1].split('{')[0].strip()
    
    def get_prefix_for_functions(self):
        starting_inds = []
        if len(self.function_lst) == 0:
            return [self.code_lines]
        for f in self.function_lst:
            starting_inds.append(f.s_line_num)
            
        return [self.code_lines[self.s_line_num]]
#         return self.code_lines[self.s_line_num:min(starting_inds)]

    
    def get_postfix_for_functions(self):
        ending_inds = []
        if len(self.function_lst) == 0:
            return [""]
        for f in self.function_lst:
            if f.body_e_ind is not None:
                ending_inds.append(f.body_e_ind)
            else:
                ending_inds.append(f.e_line_num)
            
        return self.code_lines[max(ending_inds):self.e_line_num]
    
    
    def get_code_with_max_m_chars(self, m):
        prefix = self.get_prefix_for_functions()
        postfix = self.get_postfix_for_functions()
                               
        
        length_of_boundaries = len(prefix) + len(postfix)
        s = ''
        saturated = False
        for f in self.function_lst:
                               
            if f.is_pure_sig:
                continue
                
            if len(f.get_body_code_lines()) <= 3:
                continue
            else:
                new_f = ''.join(f.get_code_lines()) + ''.join(f.get_body_code_lines())
                if len(s) + len(new_f) + length_of_boundaries > m:
                    saturated = True
                    break
                else:
                    s += new_f
                               
        return prefix + s + postfix, saturated
    
                               
    def split_code_with_max_m_chars(self, m):
        prefix = lines_to_str(self.get_prefix_for_functions())
        postfix = lines_to_str(self.get_postfix_for_functions())
        
        length_of_boundaries = len(prefix) + len(postfix)
        list_of_s = []
        cur_s = ''
        
        for f in self.function_lst:
            if f.is_pure_sig:
                continue
                
            if len(f.get_body_code_lines()) <= 4:
                continue
            else:
                new_f = lines_to_str(f.get_full_code_lines())
                if len(cur_s) + len(new_f) + length_of_boundaries > m:
                    list_of_s.append(prefix + cur_s + new_f + postfix)
                    cur_s = ''
                else:
                    cur_s += new_f
        if cur_s != '':
            list_of_s.append(prefix + cur_s + postfix)
        print('post', postfix)
        return list_of_s
                               

    def get_code_with_first_k_funcs(self, k):
        assert k <= len(self.function_lst) - 1
        s = ''
        
        for f in self.function_lst[:k]:
            if f.is_pure_sig:
                continue
            else:
                s += ''.join(f.get_code_lines()) + ''.join(f.get_body_code_lines())
        return s