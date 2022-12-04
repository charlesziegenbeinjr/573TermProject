import numpy as np
import pandas as pd

from ExKMC.Tree import Tree
from IPython.display import Image
from sklearn.cluster import KMeans


# from subprocess import PIPE, Popen

# import pyRAPL

# pyRAPL.setup(devices=[pyRAPL.Device.PKG])

# Convert to binary
# each portion of after each data point add new line, < 15, < 6

# @pyRAPL.measureit
def main():
    # frame = pd.read_csv(r"iris.csv")
    frame = pd.read_csv(r"Mental_Health_Cleaned.csv.csv")

    X = frame.drop('variety', axis=1)

    for cols in X.columns:
        X[cols] = X[cols].astype(float)
        k1 = X[cols].mean()
        k2 = np.std(X[cols])
        X[cols] = (X[cols] - k1) / k2
    k = 3
    kmeans = KMeans(k, random_state=43)
    kmeans.fit(X)
    p = kmeans.predict(X)
    class_names = np.array(['AGE', 'EDUC', 'ETHNIC'])

    tree = Tree(k=k)
    tree.fit(X, kmeans)
    tree.plot(filename="test3", feature_names=X.columns)
    Image(filename='test3.gv.png')

    tree = Tree(k=k, max_leaves=6)
    tree.fit(X, kmeans)
    tree.plot(filename="test4", feature_names=X.columns)
    Image(filename='test4.gv.png')


if __name__ == "__main__":
    main()
