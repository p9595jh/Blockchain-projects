import re
import config
import shutil
from node import Orderer

# first alphabet, then alphabet or number or underscore
pattern_default = '[a-zA-Z]+[a-zA-Z0-9\_]+'

def match_check(p, text):
    try:
        m = p.match(text)
        return len(text) == m.end()
    except:
        return False

def make_input(label: str, default=None):
    s = input(label + ': ') if default is None else input(label + ' (default is `{}`): '.format(default))
    return s.strip()

# string input
def sinput(label: str, pattern=pattern_default, default=None):
    p = re.compile(pattern)
    while True:
        text = make_input(label, default)
        if default is not None and text == '': return default
        if match_check(p, text): return text
        else: print('`%s` is not matched to the pattern `%s`' % (text, pattern))

# number input
def ninput(label: str, default=None):
    try:
        return int(sinput(label, '[0-9]+', default))
    except:
        return 0

# multiple input
def minput(label: str, seperator=' ', pattern=pattern_default, default=None):
    p = re.compile(pattern)
    while True:
        text = make_input(label, ' '.join(default) if default is not None else None)
        if default is not None and text == '': return default
        texts = text.split(seperator)
        flag = True
        arr = []
        for text in texts:
            t = text.strip()
            if not match_check(p, t):
                print('`%s` is not matched to the pattern `%s`' % (t, pattern))
                flag = False
                break
            else: arr.append(t)
        if flag: return arr

def copy_replace(src: str, dst: str, replace_dict: dict):
    if dst is None: dst = src
    with open(config.template_path + src, 'r') as f:
        content = f.read()
        for k, v in replace_dict.items():
            try:
                content = content.replace('{{%s}}' % k, v[0], v[1])
            except IndexError as e:
                content = content.replace('{{%s}}' % k, v[0])
    with open(config.path + dst, 'w+') as f:
        f.write(content)

def copy_file(src, dst=None):
    if dst is None: dst = src
    shutil.copy(config.template_path + src, config.path + dst)

def naming_var(addr: str, peer_num: int, channel_num: int):
    return '_%s_p%d_ch%d' % (addr, peer_num, channel_num)

orderer: Orderer = None
organs = []

