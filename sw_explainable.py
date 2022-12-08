import numpy as np
import pandas as pd

from ExplainableKMC import Tree
# from ExKMC.Tree import Tree
from IPython.display import Image
from sklearn.cluster import KMeans
import time

def main():
    start = time.time()
    frame = pd.read_csv(r"Data/Mental_Health_Cleaned.csv")

    X = frame.drop('MH1', axis=1)

    kmeans_start = time.time()
    k = 14
    kmeans = KMeans(k, random_state=43, max_iter=500)
    kmeans.fit(X)
    k_means_finish = time.time() - kmeans_start
    print("KMeans Execution Time: %f" % k_means_finish)
    
    clusters = kmeans.cluster_centers_
    

    start_ExKMC = time.time()
    tree = Tree.Tree(k=k)
    tree.fit(X, clusters, kmeans)
    tree.plot(filename="software_implementation", feature_names=X.columns)
    finish_ExKMC = time.time() - start_ExKMC
    print("ExKMC Execution Time: %f" % finish_ExKMC)
    
    finish = time.time() - start
    print("Total Execution Time: %f " % finish)
    Image(filename="software_implementation.gv.png")

if __name__ == "__main__":
    main()
