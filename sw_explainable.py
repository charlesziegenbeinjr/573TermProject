import numpy as np
import pandas as pd

from ExplainableKMC import Tree
# from ExKMC.Tree import Tree
from IPython.display import Image
from sklearn.cluster import KMeans
import time

from pyJoules.energy_meter import measure_energy


# @measure_energy
def main():
    start = time.time()
    frame = pd.read_csv(r"Data/Mental_Health_Cleaned.csv")

    X = frame.drop('MH1', axis=1)

    kmeans_start = time.time()
    k = 14
    kmeans = KMeans(k, random_state=43)
    kmeans.fit(X)
    k_means_finish = time.time() - kmeans_start
    print("KMeans Execution Time: %f" % k_means_finish)
    
    clusters = kmeans.cluster_centers_
    

    start_ExKMC = time.time()
    tree = Tree.Tree(k=k)
    tree.fit(X, clusters, kmeans)
    tree.plot(filename="test", feature_names=X.columns)
    finish_ExKMC = time.time() - start_ExKMC
    print("ExKMC Execution Time: %f" % finish_ExKMC)
    
    finish = time.time() - start
    print("Total Execution Time: %f " % finish)
    Image(filename='test.gv.png')

if __name__ == "__main__":
    main()
