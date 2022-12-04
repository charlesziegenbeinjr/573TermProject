import numpy as np
import pandas as pd


def array_to_binary(inc_list):
    byte_list = [4, 3, 3, 3, 2, 1, 1, 1, 1, 1, 4, 3, 2, 3, 3, 2, 2]
    byte_rep = []
    for i in range(len(inc_list)):
        print(byte_list[i])
        byte_rep.append(np.binary_repr(inc_list[i], width=byte_list[i]))
    return byte_rep


df = pd.read_csv(r"Mental_Health_Cleaned.csv")
print(array_to_binary(df.iloc[:1]))
# final_list = []
# for i in range(len(df)):
#     final_list.append(array_to_binary(df.iloc[i]))
# print(final_list)
#
# print("first element", final_list[0])


def flatten_list(_2d_list):
    flat_list = []
    # Iterate through the outer list
    for element in _2d_list:
        if type(element) is list:
            # If the element is of type list, iterate through the sublist
            for item in element:
                flat_list.append(item)
        else:
            flat_list.append(element)
    return flat_list

# unflatten = flatten_list(final_list)
# print(unflatten[0])
# byte_list = [4, 3, 3, 3, 2, 1, 1, 1, 1, 1, 4, 3, 2, 3, 3, 2, 2]
# byte_rep = []
# for i in range(len(df)):
#     for j in range(len(df.columns)):
#         byte_rep.append(np.binary_repr(df.iloc[i], width=byte_list[j]))
#
#
# def val_to_arry(value):
#     byte_list = [4, 3, 3, 3, 2, 1, 1, 1, 1, 1, 4, 3, 2, 3, 3, 2, 2]
#     converted_list = []
#     for i in range()
#     pass

# if __name__ == "__main__":
#     main()
