import numpy as np
import pandas as pd

from ExplainableKMC import Tree
# from ExKMC.Tree import Tree
from IPython.display import Image
from sklearn.cluster import KMeans
import time
import matplotlib.pyplot as plt
import statistics
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)



def main():
    
    total_times = []
    k_means_times = []
    exkmc_times = []
    
    for i in range(50):
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
        
        total_times.append(finish)
        k_means_times.append(k_means_finish)
        exkmc_times.append(finish_ExKMC)
        Image(filename="software_implementation.gv.png")
    
    # tot = {
    #     "title": 'Time to Execute Script Over 50 Iterations', 
    #     "data": total_times,
    # }
    # km = {
    #     "title": 'Time to Execute KMeans Algorithm Over 50 Iterations',
    #     "data": k_means_times,
    # }
    # ekmc = {
    #     "title": 'Time to Execute ExKMC Algorithm Over 50 Iterations',
    #     "data": exkmc_times,
    # }
    
    plot(total_times,k_means_times,exkmc_times)
    
def plot(total, kmeans, exkmc):
    fig, ax = plt.subplots()

    ax.plot(np.arange(0, 50, 1), total)

    ax.set(xlabel='Iteration', ylabel='Time (s)',
        title=)
    ax.grid()

    fig.savefig("total_time.png")
    plt.show()
    print(statistics.mean(total))
    print(statistics.stdev(total))
    
    fig, ax = plt.subplots()

    ax.plot(np.arange(0, 50, 1), kmeans)

    ax.set(xlabel='Iteration', ylabel='Time (s)',
           title='Time to Execute KMeans Subprocess Over 50 Iterations')
    ax.grid()

    fig.savefig("kmeans.png")
    plt.show()
    print(statistics.mean(kmeans))
    print(statistics.stdev(kmeans))
    
    fig, ax = plt.subplots()

    ax.plot(np.arange(0, 50, 1), exkmc)

    ax.set(xlabel='Iteration',ylabel='IterationTime (s)', 
           title='Time to Execute ExKMC Subprocess Over 50 Iterations')
    ax.grid()

    fig.savefig("exkmc.png")
    plt.show()
    print(statistics.mean(exkmc))
    print(statistics.stdev(exkmc))

    
        
if __name__ == "__main__":
    main()
