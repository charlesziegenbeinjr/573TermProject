# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# % How To Run This Script:                           %
# % 1.$ pip install -r requirements.txt               %
# % 2.$ python3 sw_explainable.py T/F T/F             %
# % First True/False is for graphing over 50 runs     %
# % Second True/False is for if we want to run with   %
# % hardware acceleration                             %
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# Import all necessary libraries 
import os
# Optional if running on Windows, graphviz didn't exactly play nice 
# os.environ["PATH"] += os.pathsep + 'C:/Program Files/Graphviz/bin'
import sys

import numpy as np
import pandas as pd

from ExplainableKMC import Tree
from sklearn.cluster import KMeans
import time
import matplotlib.pyplot as plt
import statistics


def main():
    '''
    Define the main() function for driving the script forward:
    - Establish arrays for timing if we choose to time over 50 runs
    - If 2nd argument is True, we are timing, else we just run once
    
    Optionally, we can plot our power consumption. We read the power csv
    fron Intel Power Gadget.
    '''
    total_times = []
    k_means_times = []
    exkmc_times = []

    # Loop for testing time over 50 Runs
    if sys.argv[1] is True:
        for i in range(50):
            total, kmeans, exkmc = run()
            total_times.append(total)
            k_means_times.append(kmeans)
            exkmc_times.append(exkmc)
        plot(total_times,k_means_times,exkmc_times, 50)
    
    else:
        total, kmeans, exkmc = run()
    
    # plot_power() # UNCOMMENT FOR POWER DATA PLOTTING, WHERE CSV IS IN POWERDATA
    
def run():
    '''
    Here, we actually run the K-Means to ExKMC pipeline, which can be done in two ways depending
    on whether or not we are running with output from the Hardware Acceleration
    
    To set whether we are running with hardware acceleration output, set the 3rd argument either
    True (We are) or False (We aren't) 

    Local timing is establish here, and we're interested in timing the entire execution of run(), 
    and the time it takes to do KMeans and ExKMC.
    '''
    start = time.time()
    frame = pd.read_csv(r"../Data/Mental_Health_Cleaned_524288.csv")

    X = frame.drop('MH1', axis=1)

    
    kmeans_start = time.time()
    k = 14
    
    kmeans = KMeans(k, random_state=43, max_iter=500)
    
    # We are not running based off of centroids from the ASIC
    if sys.argv[2] is False: 
        kmeans.fit(X)
        clusters = kmeans.cluster_centers_
        k_means_finish = time.time() - kmeans_start
        print("KMeans Execution Time: %f" % k_means_finish)
    # We are running based off of centroids from the ASIC
    else:
        clusters = np.array([[6, 3, 4, 3, 1, 0, 0, 0, 1, 0, 4, 2, 1, 1, 1, 0],
                            [7, 3, 3, 4, 1, 0, 0, 0, 1, 0, 0, 3, 1, 5, 1, 1],
                            [6, 0, 4, 4, 2, 0, 0, 0, 1, 0, 2, 2, 3, 1, 0, 0],
                            [4, 2, 4, 4, 1, 0, 0, 0, 1, 0, 4, 2, 1, 5, 0, 0],
                            [11, 4, 3, 3, 1, 0, 0, 0, 1, 1, 4, 0, 2, 1, 1, 0],
                            [11, 0, 4, 3, 2, 0, 1, 0, 1, 0, 3, 0, 0, 5, 2, 1],
                            [9, 3, 4, 4, 1, 0, 0, 0, 1, 0, 4, 1, 1, 2, 1, 0],
                            [5, 2, 4, 3, 1, 0, 0, 0, 1, 0, 2, 3, 1, 1, 1, 0], 
                            [7, 3, 3, 4, 1, 0, 0, 0, 1, 0, 0, 2, 2, 5, 1, 1],
                            [6, 3, 4, 4, 1, 0, 0, 0, 1, 0, 0, 1, 1, 5, 1, 1],
                            [6, 4, 4, 4, 1, 0, 0, 1, 0, 0, 6, 0, 3, 1, 1, 0],
                            [6, 3, 4, 3, 2, 0, 0, 1, 0, 1, 2, 2, 6, 0, 0, 0],
                            [8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1, 0, 0, 0, 0],
                            [7, 3, 3, 4, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0]], dtype=np.double)

    # Start timing ExKMC
    start_ExKMC = time.time()
    # Establish Tree with k clusters for leaves, the number of features
    tree = Tree.Tree(k=k)
    # Fit Tree, passing in input data, clusters, T/F for hardware, and either a full
    # or empty sklearn.kmeans object
    tree.fit(X, clusters, sys.argv[2], kmeans)
    # Plot the Tree
    tree.plot(filename="Output_Tree", feature_names=X.columns)
    
    # Finish timing the execution
    finish_ExKMC = time.time() - start_ExKMC
    print("ExKMC Execution Time: %f" % finish_ExKMC)

    
    # Finish Script timing
    finish = time.time() - start
    print("Total Execution Time: %f " % finish)
    
    
    
    return finish, k_means_finish, finish_ExKMC    


# The Functions Below Plot Data, Either Time or Power Output
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

# %%

