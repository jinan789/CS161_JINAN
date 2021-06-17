import secrets
import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

"""
author: Jinan Jiang, UC Berkeley
"""

IV_LENGTH = 16

def random_bytes(i = 16):
    return secrets.token_bytes(i)

def random_bits(i = 16):
    return secrets.randbits(i)

def CBC_enc(message, key, iv = None):
    if iv == None:
        iv = random_bytes(IV_LENGTH)
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv)) #makes an AES-CBC cipher
    encryptor = cipher.encryptor()
    cipher_text = encryptor.update(message) + encryptor.finalize()
    return cipher_text