import secrets, random, os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import hashes, hmac, padding

"""
By Jinan Jiang, jinan@berkeley.edu
"""

IV_LENGTH = 16
AES_KEY_LENGTH = 32


def random_bytes(i = 16):
    return secrets.token_bytes(i)

def random_bits(i = 16):
    return secrets.randbits(i)

def gen_enc_message(data, key, iv, mode):
    if key is None:
        key = random_bytes(AES_KEY_LENGTH)
    if iv is None:
        iv = random_bytes(IV_LENGTH)
        
    if mode is modes.ECB:
        cipher = Cipher(algorithms.AES(key), mode())
    else:
        cipher = Cipher(algorithms.AES(key), mode(iv))
        
    encryptor = cipher.encryptor()
    cipher_text = encryptor.update(data) + encryptor.finalize()
    return cipher_text
    
def AES_CBC_enc(data, key = None, iv = None):
    return gen_enc_message(data, key, iv, modes.CBC)

def AES_CFB_enc(data, key = None, iv = None):
    return gen_enc_message(data, key, iv, modes.CFB)

def AES_ECB_enc(data, key = None, iv = None):
    return gen_enc_message(data, key, iv, modes.ECB)

def AES_CTR_enc(data, key = None, iv = None):
    return gen_enc_message(data, key, iv, modes.CTR)

def SHA_256_hash(data):
    digest = hashes.Hash(hashes.SHA256())
    digest.update(data)
    return digest.finalize()


def hack_url_for_passwords(url, pwd_type = "plain passwords"):
    if url == "https://cs161.org/":
        pwd_dict = {"Jinan": b"jinan_password", 
                "EvanBot": b"apassword", 
                "Alice" : b"123456",
                "Bob" : b"IamBob",
                "Eve": b"hello",
                "Mallory": b"qwerty"}
    else:
        raise Exception("Sorry, this URL is not supported...")
        
    if pwd_type == "plain passwords":
        return pwd_dict
    elif pwd_type == "hashed passwords":
        return {k:SHA_256_hash(v).hex() for (k, v) in pwd_dict.items()}
    elif pwd_type == "hashed passwords with salt": 
        temp_salt = {k:random_bytes(16) for (k, v) in pwd_dict.items()}
        return {k:{"password":SHA_256_hash(v + temp_salt[k]).hex(), 
                   "salt": temp_salt[k].hex()}
                for (k, v) in pwd_dict.items()}
    else:
        raise Exception("pwd_type is not recognized...")

def hmac_gen(key, data):
    h = hmac.HMAC(key, hashes.SHA256())
    h.update(data)
    return h.finalize()
    
def hmac_verify(key, data, mac):
    h = hmac.HMAC(key, hashes.SHA256())
    h.update(data)
    try:
        h.verify(mac)
        return True
    except:
        return False #verify failed
    
def add_padding(data):
    padder = padding.PKCS7(128).padder()
    padded_data = padder.update(data) + padder.finalize()
    return padded_data

def remove_padding(padded_data):
    unpadder = padding.PKCS7(128).unpadder()
    data = unpadder.update(padded_data) + unpadder.finalize()
    return data


class ind_cpa_game:
    def __init__(self, mode):
        self.mode = mode
        self.key = random_bytes(AES_KEY_LENGTH)
        
    def send_messages(self, m0, m1):
        if m0 == m1:
            raise Exception("Please enter different messages")
            
        self.m0 = m0
        self.m1 = m1
        self.b = random.randint(0, 1)
        data = [m0, m1][self.b]
        
        return gen_enc_message(data, self.key, iv = random_bytes(IV_LENGTH), mode = self.mode)
    
    def query_message(self, m):
        return gen_enc_message(m, self.key, iv = random_bytes(IV_LENGTH), mode = self.mode)
        
        
    def is_guess_correct(self, m):
        return m == [self.m0, self.m1][self.b]
    
