import openai
import json
import os
import re
import time

openai.api_type = "azure"
openai.api_key = "b303151e6bc549528fa7f0d2b34a271a"
openai.api_base =  "https://api.hku.hk"
openai.api_version = "2023-03-15-preview"

class ChatGPT:
    
    def __init__(self):
        self.clear_context()
    
    def clear_context(self):
        self.context_messages = None
        self.num_of_contexts = 0
        
    def get_response(self, prompt, is_trivial = False):
        def get_response_inner(prompt, context_messages = None):
            d = {"role": "user", "content": prompt}
            if context_messages is None:
                new_context_messages = [d]
            else:
                new_context_messages = context_messages + [d]
            completion = openai.ChatCompletion.create(engine="chatgpt-4", messages=new_context_messages)
            gpt_response = completion.choices[0].message.content

            response_d = {"role": "system", "content": gpt_response}
            new_context_messages = new_context_messages + [response_d]

            return gpt_response, new_context_messages
        
        gpt_response, context_messages = get_response_inner(prompt, context_messages = self.context_messages)
        
        print("num_of_contexts: ", self.num_of_contexts)
        
        if not is_trivial:
            self.context_messages = context_messages
            self.num_of_contexts += 1
        
        return gpt_response
    
    def saves_dialogues(self, filename):
        with open('saved_dialogues/' + filename + '.json', 'w') as f:
            json.dump(self.context_messages, f)
        
    
def write_to_file(contents, path):
    with open(path, 'w') as f:
        f.write(contents)
    
def read_from_file(path):
    with open(path) as f:
        return ''.join(f.readlines())
    
def get_filename_from_path(path):
    n = path.split('/')[-1]
    assert '.txt' in n
    return n

def extract_tokens(deliminator, string):
    starting_token = '<START_' + deliminator + '>'
    ending_token = '<END_' + deliminator + '>'
    
    pattern = starting_token
    matches = re.finditer(pattern,string)
    indexes = [(m.start(0), m.end(0)) for m in matches]
    assert len(indexes) == 1
    starting_index = indexes[0][1]
    
    pattern = ending_token
    matches = re.finditer(pattern,string)
    indexes = [(m.start(0), m.end(0)) for m in matches]
    assert len(indexes) == 1
    ending_index = indexes[0][0]
    
    return string[starting_index : ending_index]
    
    
def get_prompt_text_from_file(file_path):
    prompt = read_from_file(file_path)
    return prompt

class GPT_string:
    def __init__(self, s):
        self.string = s
        
        
def do_pipeline(source_files_lst, output_file_path = None, do_print = False):
    if do_print:
        cur_print = print
    else:
        cur_print = lambda x:None
        
    gpt = ChatGPT()
    all_responses_lst = []
    
    for cur_lst in source_files_lst:
        cur_prompt = ''
        for cur_file in cur_lst:
            if type(cur_file) == GPT_string:
                cur_prompt += cur_file.string
            else:
                cur_prompt += get_prompt_text_from_file(cur_file)
        r = gpt.get_response(cur_prompt)
        all_responses_lst.append(r)
        
        cur_print('\n***PROMPT:', cur_prompt)
        cur_print('\n***RESPONSE:', r)
        
    if output_file_path:
        gpt.saves_dialogues(output_file_path)
        
    return gpt, all_responses_lst






































def extract_relevant_contract(summary_of_all_contracts_parts, task_name, use_cache = False, save_dialogue = False, cache_prefix = 'cache/'):
    cache_path = cache_prefix + 'relevant_contracts_cache.txt'
    
    if use_cache:
        if os.path.exists(cache_path):
            return read_from_file(cache_path)
        
    source_files_lst = []
    
    l = []
    # source_files_lst.append(['prompts_folder/summarize_contracts.txt', "ERC20.sol"])
    l.extend(['prompts_folder/find_relevant_contracts_part1.txt', GPT_string(summary_of_all_contracts_parts)])
    l.extend(['prompts_folder/find_relevant_contracts_part2.txt', 'prompts_folder/task_descriptions/task_' + task_name + '.txt'])
    
    source_files_lst.append(l)

    if save_dialogue:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = get_filename_from_path(contract_file_name) + '_relevant_contracts', do_print = True)
    else:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = None, do_print = True)

    assert len(all_responses_lst) == 1
    
    if use_cache:
        assert not os.path.exists(cache_path)
        content = all_responses_lst[0]
        write_to_file(content, cache_path)
        
    return all_responses_lst[0]



def extract_relevant_function(summary_of_all_functions_parts, task_name, use_cache = False, save_dialogue = False, cache_prefix = 'cache/'):
    cache_path = cache_prefix + 'relevant_functions_cache.txt'
    
    if use_cache:
        if os.path.exists(cache_path):
            return read_from_file(cache_path)
        
    source_files_lst = []
    
    l = []
    # source_files_lst.append(['prompts_folder/summarize_contracts.txt', "ERC20.sol"])
    l.extend(['prompts_folder/find_relevant_functions_part1.txt', GPT_string(summary_of_all_functions_parts)])
    l.extend(['prompts_folder/find_relevant_functions_part2.txt', 'prompts_folder/task_descriptions/task_' + task_name + '.txt'])
    
    source_files_lst.append(l)

    if save_dialogue:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = get_filename_from_path(contract_file_name) + '_relevant_contracts', do_print = True)
    else:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = None, do_print = True)

    assert len(all_responses_lst) == 1
    
    if use_cache:
        assert not os.path.exists(cache_path)
        content = all_responses_lst[0]
        write_to_file(content, cache_path)
        
    return all_responses_lst[0]




def extract_few_shot_example(summary_of_all_functions_parts, task_name, use_cache = False, save_dialogue = False, cache_prefix = 'cache/'):
    cache_path = cache_prefix  + 'few_shot_example_cache.txt'
    
    if use_cache:
        if os.path.exists(cache_path):
            return read_from_file(cache_path)
        
    source_files_lst = []
    
    l = []
    # source_files_lst.append(['prompts_folder/summarize_contracts.txt', "ERC20.sol"])
    l.extend(['prompts_folder/find_few_shot_example_function_part1.txt', 'prompts_folder/task_descriptions/task_' + task_name + '.txt'])
    l.extend(['prompts_folder/find_few_shot_example_function_part2.txt', GPT_string(summary_of_all_functions_parts)])
    
    source_files_lst.append(l)

    if save_dialogue:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = get_filename_from_path(contract_file_name) + '_relevant_contracts', do_print = True)
    else:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = None, do_print = True)

    assert len(all_responses_lst) == 1
    
    if use_cache:
        assert not os.path.exists(cache_path)
        content = all_responses_lst[0]
        write_to_file(content, cache_path)
        
    return all_responses_lst[0]





def generate_codes(few_shot_example, relevant_function_lst, task_name, use_cache = False, save_dialogue = False, cache_prefix = 'cache/'):
    cache_path = cache_prefix + 'generated_codes.txt'
    
    if use_cache:
        if os.path.exists(cache_path):
            return read_from_file(cache_path)
        
    source_files_lst = []
    
    l = []
    # source_files_lst.append(['prompts_folder/summarize_contracts.txt', "ERC20.sol"])
    l.extend(['prompts_folder/code_gen_part1.txt', 'prompts_folder/task_descriptions/task_' + task_name + '.txt'])
    l.extend(['prompts_folder/code_gen_part2.txt', GPT_string(few_shot_example)])
    l.extend(['prompts_folder/code_gen_part3.txt', GPT_string(relevant_function_lst)])
    
    source_files_lst.append(l)

    if save_dialogue:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = get_filename_from_path(contract_file_name) + '_relevant_contracts', do_print = True)
    else:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = None, do_print = True)

    assert len(all_responses_lst) == 1
    
    if use_cache:
        assert not os.path.exists(cache_path)
        content = all_responses_lst[0]
        write_to_file(content, cache_path)
        
    return all_responses_lst[0]














def find_previous_close(broken_down_codes_with_index, starting_line_num):
    cur_line_num = starting_line_num - 1
    
    while True:
        if cur_line_num < 0:
            return 0
        cur_ln_text = broken_down_codes_with_index[cur_line_num][0]
        if '}' in cur_ln_text or cur_ln_text.strip().startswith('function '):
            assert cur_line_num >= 0
            return cur_line_num + 1
        else:
            cur_line_num -= 1
 
def find_is_signature(broken_down_codes_with_index, starting_line_num):
    cur_line_num = starting_line_num
    
    while True:
        if cur_line_num == len(broken_down_codes_with_index):
            # reached an impossible line, no } seen yet
            return True
        
        # print('*****', broken_down_codes_with_index[cur_line_num][0])
        cur_ln_text = broken_down_codes_with_index[cur_line_num][0]
        if '}' in cur_ln_text:
            return False
        elif cur_ln_text.strip().startswith('function ') and cur_line_num != starting_line_num:
            # no } seen at all
            return True
        
        else:
            cur_line_num += 1
            
            
def get_splitted_codes(codes):
    
    broken_down_codes = [c for c in codes.split('\n')]
    broken_down_codes_with_index = [(broken_down_codes[n], n) for n in range(len(broken_down_codes))]
    broken_down_codes_with_index_and_close = [c for c in broken_down_codes_with_index if c[0].strip().startswith('function ')]

    contract_name = [c for c in broken_down_codes_with_index if c[0].strip().startswith('contract ')]
    assert len(contract_name) == 1
    contract_name = contract_name[0][0].strip('{} ')
    
    previous_d = None
    for ind in range(len(broken_down_codes_with_index_and_close)):
        original_codes_ind = broken_down_codes_with_index_and_close[ind][1]
        cur_fn_d = dict()

        c = broken_down_codes_with_index[original_codes_ind]
        if ind == len(broken_down_codes_with_index_and_close) - 1:
            closing_ind = len(broken_down_codes_with_index) - 1
        else:
            c_add_1 = broken_down_codes_with_index_and_close[ind + 1]
            next_fn_original_codes_ind = c_add_1[1]
            closing_ind = find_previous_close(broken_down_codes_with_index, next_fn_original_codes_ind)

            
        
        cur_fn_d['function_signature'] = c[0]
        cur_fn_d['located_at'] = c[1]
        cur_fn_d['ends_at'] = closing_ind
        
        cur_fn_d['is_signature'] = find_is_signature(broken_down_codes_with_index, original_codes_ind)

        # TODO

        if previous_d is None:
            cur_fn_d['starts_at'] = 0
        else:
            cur_fn_d['starts_at'] = previous_d['ends_at']
            
        in_range_codes = broken_down_codes_with_index[cur_fn_d['starts_at']: cur_fn_d['ends_at']]
        in_range_codes = ''.join([c[0] + '\n' for c in in_range_codes])
        cur_fn_d['codes_text'] = in_range_codes
        cur_fn_d['codes_text_length'] = len(in_range_codes)

        if cur_fn_d['is_signature']:
            cur_fn_d['codes_text_FILTERED_sig'] = ''
            cur_fn_d['codes_text_length_FILTERED_sig'] = 0
        else:
            cur_fn_d['codes_text_FILTERED_sig'] = cur_fn_d['codes_text']
            cur_fn_d['codes_text_length_FILTERED_sig'] = cur_fn_d['codes_text_length']


        previous_d = cur_fn_d
        broken_down_codes_with_index_and_close[ind] = cur_fn_d
        
    return broken_down_codes_with_index_and_close, contract_name


def split_codes_with_max_length(broken_down_codes_with_index_and_close, max_length):
    code_txt_lst = []
    cur_codes_txt = ''
    for d in broken_down_codes_with_index_and_close:
        #assert d['codes_text_length_FILTERED_sig'] < max_length
        if len(cur_codes_txt) + len(d['codes_text_FILTERED_sig']) > max_length:
            code_txt_lst.append(cur_codes_txt)
            cur_codes_txt = d['codes_text_FILTERED_sig']
        else:
            cur_codes_txt += d['codes_text_FILTERED_sig']
    if len(cur_codes_txt) > 0:
        code_txt_lst.append(cur_codes_txt)
    
    print([len(i) for i in code_txt_lst])
    return code_txt_lst



def summarize_contract(contract_file_name, use_cache = False, save_dialogue = False, cache_prefix = 'cache/'):
    cache_path = cache_prefix + contract_file_name.strip('code_repository/') + '_summary_cache.txt'
    
    if use_cache:
        if os.path.exists(cache_path):
            return read_from_file(cache_path)
        
    
    
    codes_txt = read_from_file(contract_file_name)
    broken_down_codes_with_index_and_close, contract_name = get_splitted_codes(codes_txt)

    code_txt_lst = split_codes_with_max_length(broken_down_codes_with_index_and_close, 3000)

    
    FUNCTION_part_lst = ['']
    CONTRACT_part_lst = ['']
    all_responses_lst = ['']
    
    for code_piece in code_txt_lst:
        source_files_lst = []
        if len(code_piece) == 0:
            continue
        # source_files_lst.append(['prompts_folder/summarize_contracts.txt', "ERC20.sol"])
        source_files_lst.append(['prompts_folder/summarize_contracts.txt', GPT_string(code_piece)])

        if save_dialogue:
            gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = get_filename_from_path(contract_file_name) + '_summary', do_print = True)
        else:
            gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = None, do_print = True)

        assert len(all_responses_lst) == 1
        cur_code_summary = all_responses_lst[0]
        
        FUNCTION_part = extract_tokens('FUNCTIONS', cur_code_summary)
        CONTRACT_part = extract_tokens('CONTRACTS', cur_code_summary)
        
        FUNCTION_part_lst.append(FUNCTION_part)
        CONTRACT_part_lst.append(CONTRACT_part)
    
    
    final_result_str = ''
    final_result_str += '<START_FUNCTIONS>\n'
    final_result_str += ''.join(FUNCTION_part_lst)
    final_result_str += '<END_FUNCTIONS>\n'
    
    final_result_str += '<START_CONTRACTS>\n'
    final_result_str += ''.join(CONTRACT_part_lst)
    final_result_str += '<END_CONTRACTS>\n'
    
    
    all_responses_lst[0] = final_result_str
    
    if use_cache:
        assert not os.path.exists(cache_path)
        content = contract_file_name + '\n' + all_responses_lst[0]
        write_to_file(content, cache_path)
        
    return all_responses_lst[0]




def get_code_quality_feedback(generated_codes, task_name, cur_round, use_cache = False, save_dialogue = False, cache_prefix = 'cache/'):
    cache_path = cache_prefix + 'code_quality_feedback_round_' + str(cur_round) +'.txt'
    
    if use_cache:
        if os.path.exists(cache_path):
            return read_from_file(cache_path)
        
    source_files_lst = []
    
    l = []
    # source_files_lst.append(['prompts_folder/summarize_contracts.txt', "ERC20.sol"])
    l.extend(['prompts_folder/tester_feedback.txt', GPT_string(generated_codes)])
    
    source_files_lst.append(l)

    if save_dialogue:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = get_filename_from_path(contract_file_name) + '_relevant_contracts', do_print = True)
    else:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = None, do_print = True)

    assert len(all_responses_lst) == 1
    
    if use_cache:
        assert not os.path.exists(cache_path)
        content = all_responses_lst[0]
        write_to_file(content, cache_path)
        
    return all_responses_lst[0]




def fix_codes_based_on_feedback(generated_codes, code_quality_feedback, cur_round, use_cache = False, save_dialogue = False, cache_prefix = 'cache/'):
    cache_path = cache_prefix + 'fixed_codes_round_' + str(cur_round) +'.txt'
    
    if use_cache:
        if os.path.exists(cache_path):
            return read_from_file(cache_path)
        
    source_files_lst = []
    
    l = []
    # source_files_lst.append(['prompts_folder/summarize_contracts.txt', "ERC20.sol"])
    l.extend(['prompts_folder/fix_codes_part1.txt', GPT_string(generated_codes)])
    l.extend(['prompts_folder/fix_codes_part2.txt', GPT_string(code_quality_feedback)])
    
    source_files_lst.append(l)

    if save_dialogue:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = get_filename_from_path(contract_file_name) + '_relevant_contracts', do_print = True)
    else:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = None, do_print = True)

    assert len(all_responses_lst) == 1
    
    if use_cache:
        assert not os.path.exists(cache_path)
        content = all_responses_lst[0]
        write_to_file(content, cache_path)
        
    return all_responses_lst[0]




def check_stopping_criteria(fixed_codes, task_name, cur_round, use_cache = False, save_dialogue = False, cache_prefix = 'cache/'):
    cache_path = cache_prefix + 'check_stopping_criteria_round_' + str(cur_round) +'.txt'
    
    if use_cache:
        if os.path.exists(cache_path):
            return read_from_file(cache_path)
        
    source_files_lst = []
    
    l = []
    # source_files_lst.append(['prompts_folder/summarize_contracts.txt', "ERC20.sol"])
    l.extend(['prompts_folder/stopping_criteria.txt', GPT_string(fixed_codes)])
    
    source_files_lst.append(l)

    if save_dialogue:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = get_filename_from_path(contract_file_name) + '_relevant_contracts', do_print = True)
    else:
        gpt, all_responses_lst = do_pipeline(source_files_lst, output_file_path = None, do_print = True)

    assert len(all_responses_lst) == 1
    
    if use_cache:
        assert not os.path.exists(cache_path)
        content = all_responses_lst[0]
        write_to_file(content, cache_path)
        
    return all_responses_lst[0]
