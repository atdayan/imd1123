#!/usr/bin/env python3

import pandas as pd

df = pd.read_csv('all_month.csv', usecols=[0, 3, 4, 13, 14])
print(df.head(10))

max_depth = df['depth'].nlargest(1)
print(max_depth)

print('-'*10)

min_depth = df['depth'].nsmallest(1)
print(min_depth)

print('='*20)

max_mag = df['mag'].nlargest(1)
print(max_mag)

print('-'*10)

min_mag = df['mag'].nsmallest(1)
print(min_mag)
