#!/usr/bin/python3

import sys
import binascii

dna = {'A': '00', 'C': '01', 'G': '10', 'T': '11'}

binary = ''
for letter in sys.argv[1]:
    binary += dna[letter]

print('binary:', binary)
print('decimal:', int(binary, 2))
print('hex:', hex(int(binary, 2))[2:])
