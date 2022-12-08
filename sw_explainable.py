import os
import sys

import numpy as np
import pandas as pd

from ExplainableKMC import Tree
# from IPython.display import Image
from sklearn.cluster import KMeans
import time
import matplotlib.pyplot as plt
import statistics
os.environ["PATH"] += os.pathsep + 'C:/Program Files/Graphviz/bin'




def main():
    
    total_times = []
    k_means_times = []
    exkmc_times = []

    if sys.argv[1] is True:
        for i in range(50):
            total, kmeans, exkmc = run()
            total_times.append(total)
            k_means_times.append(kmeans)
            exkmc_times.append(exkmc)
        plot(total_times,k_means_times,exkmc_times, 50)
    
    else:
        total, kmeans, exkmc = run()
    
    # plot_power()
    

def run():
    start = time.time()
    frame = pd.read_csv(r"Data/Mental_Health_Cleaned.csv")

    X = frame.drop('MH1', axis=1)
    # X = frame

    kmeans_start = time.time()
    k = 14
    kmeans = KMeans(k, random_state=43, max_iter=500)
    kmeans.fit(X)
    k_means_finish = time.time() - kmeans_start
    print("KMeans Execution Time: %f" % k_means_finish)
    
    clusters = kmeans.cluster_centers_
    clusters = clusters.astype('int16')
    print(clusters.astype('int16'))

    start_ExKMC = time.time()
    tree = Tree.Tree(k=k)
    tree.fit(X, clusters, kmeans)
    tree.plot(filename="software_implementation", feature_names=X.columns)
    finish_ExKMC = time.time() - start_ExKMC
    print("ExKMC Execution Time: %f" % finish_ExKMC)
    
    finish = time.time() - start
    print("Total Execution Time: %f " % finish)
    
    
    # Image(filename="software_implementation.gv.png")
    
    return finish, k_means_finish, finish_ExKMC    

def plot(total, kmeans, exkmc, steps):
    fig, ax = plt.subplots()

    ax.plot(np.arange(0, steps, 1), total)

    ax.set(xlabel='Iteration', ylabel='Time (s)',
        title="Time to Execute Explainable ML Over %s Iterations" % steps)
    ax.grid()

    fig.savefig("total_time.png")
    plt.show()
    print(statistics.mean(total))
    print(statistics.stdev(total))
    
    fig, ax = plt.subplots()

    ax.plot(np.arange(0, steps, 1), kmeans)

    ax.set(xlabel='Iteration', ylabel='Time (s)',
           title='Time to Execute KMeans Subprocess Over %s Iterations' % steps)
    ax.grid()

    fig.savefig("kmeans.png")
    plt.show()
    print(statistics.mean(kmeans))
    print(statistics.stdev(kmeans))
    
    fig, ax = plt.subplots()

    ax.plot(np.arange(0, steps, 1), exkmc)

    ax.set(xlabel='Iteration',ylabel='IterationTime (s)', 
           title='Time to Execute ExKMC Subprocess Over %s Iterations' % steps)
    ax.grid()

    fig.savefig("exkmc.png")
    plt.show()
    print(statistics.mean(exkmc))
    print(statistics.stdev(exkmc))

def plot_power():
    frame = pd.read_csv(r"PowerData/PwrData.csv")
    fig, ax = plt.subplots()

    ax.plot(frame["System Time"], frame["Processor Power_0(Watt)"])

    ax.set(xlabel='Time', ylabel='Power (W)',
        title="Power Required to Execute Explainable ML Over %s Measurements" % len(frame["System Time"]))
    start, end = ax.get_xlim()
    ax.xaxis.set_ticks(np.arange(start, end, 50))
    # ax.grid()

    fig.savefig("total_time.png")
    plt.show()


        
if __name__ == "__main__":
    main()
