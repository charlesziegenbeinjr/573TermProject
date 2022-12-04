


import numpy as np
import pandas as pd

from ExKMC.Tree import Tree
from IPython.display import Image
from sklearn.cluster import KMeans

from pyJoules.energy_meter import measure_energy


@measure_energy
def main():
    frame = pd.read_csv(r"iris.csv")

    X = frame.drop('variety', axis=1)

    for cols in X.columns:
        X[cols] = X[cols].astype(float)
        k1 = X[cols].mean()
        k2 = np.std(X[cols])
        X[cols] = (X[cols] - k1)/k2
    k = 3
    kmeans = KMeans(k, random_state=43)
    kmeans.fit(X)
    p = kmeans.predict(X)
    class_names = np.array(['Setosa', 'Versicolor', 'Virginica'])


    tree = Tree(k=k)
    tree.fit(X, kmeans)
    tree.plot(filename="test", feature_names=X.columns)
    Image(filename='test.gv.png')

    tree = Tree(k=k, max_leaves=6)
    tree.fit(X, kmeans)
    tree.plot(filename="test1", feature_names=X.columns)
    Image(filename='test1.gv.png')


if __name__ == "__main__":
    main()
