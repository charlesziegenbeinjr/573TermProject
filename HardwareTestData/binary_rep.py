import numpy as np
import pandas as pd


def array_to_binary(inc_list):
    # byte_list = [4, 3, 3, 3, 2, 1, 1, 1, 1, 1, 4, 3, 2, 3, 3, 2, 2]
    byte_list = [2,2,3,3,2,3,4,1,1,1,1,1,2,3,3,3,4]
    inc_list = inc_list[::-1]
    byte_rep = []
    for i in range(len(inc_list)):
        byte_rep.append(np.binary_repr(inc_list[i], width=byte_list[i]))
        if i+1 is len(inc_list):
            print(byte_rep)
    return byte_rep


df = pd.read_csv(r"../Data/Mental_Health_Cleaned_524288.csv")
# df = np.array([[5,0,1,0,1,0,0,0,0,0,0,1,4,2,1,0],[8,0,3,4,1,0,0,0,0,0,0,1,0,0,0,0],[2,2,3,4,1,0,0,0,0,0,1,1,0,0,1,1],[12,0,3,4,1,0,0,0,0,0,0,1,0,0,0,0],[1,0,3,1,1,0,0,0,0,0,0,1,0,0,0,0],[6,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0],[1,0,3,5,1,0,0,0,0,0,0,1,0,0,0,0],[9,3,3,4,1,0,0,0,0,0,2,1,3,0,1,1],[8,0,3,4,1,0,0,0,0,0,0,1,3,0,0,1],[1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0],[4,0,3,4,1,0,0,0,0,0,0,1,4,2,0,1],[12,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0],[5,0,3,4,1,0,0,0,0,0,0,1,0,0,0,0],[11,0,3,3,1,0,0,0,0,0,0,1,5,4,0,1]])
df = df.to_numpy()

for j in range(len(df)):
    array_to_binary(df[j])
