import matplotlib.pyplot as plt
import numpy as np
 


def deviation_plot(filename,delta_t = 1000):
    arr = np.loadtxt(filename)
    #arr = arr[1:-1]
    # start time as initial time
    arr = arr - arr[0]
    #arr = arr[1:-1]
    # convert to microseconds
    delta_arr = (np.diff(arr)) * 1e6 - delta_t # sec to usec
    # get deviation in consecutive readigs
    # delta_arr = delta_arr - delta_arr[0] # sec to usec
    # remove first and last 10 rows
    delta_arr = delta_arr[10:-10]
    #np.set_printoptions(precision=8)
    #with np.printoptions(precision=3, suppress=False):
    #    print(arr)
    x = range(1,len(delta_arr)+1)
    
    fig, axes  = plt.subplots(nrows=2, ncols=1, sharey=False)
    axes[0].plot(x,delta_arr,'k.')
    axes[0].set_ylim(ymax=max(delta_arr)*1.2,ymin=min(delta_arr)*1.2)
    axes[0].set_ylabel("$\Delta T ( \mu sec )$")
    # statistics
    sigma = np.std(delta_arr)
    mu = np.mean(delta_arr)
    # An "interface" to matplotlib.axes.Axes.hist() method
    n, bins, patches = axes[1].hist(x=delta_arr, bins='auto', color='#0504aa', alpha=0.7)
    axes[1].grid(axis='y', alpha=0.75)
    axes[1].set_xlabel("$deviation ( \mu sec )$")
    axes[1].set_ylabel('Frequency')
    pdfunc = ((1 / (np.sqrt(2 * np.pi) * sigma)) * np.exp(-0.5 * (1 / sigma * (bins - mu))**2))
    axes[1].plot(bins, pdfunc, '--')
    #plt.title('Histogram')
    #axes[1].set_text(0, 0, r'$\mu=, b= $')
    maxfreq = n.max()
    # Set a clean upper y-axis limit.
    axes[1].set_ylim(ymax=np.ceil(maxfreq / 10) * 10 if maxfreq % 10 else maxfreq + 10)
    plt.tight_layout()
    plt.show()

def jitter_plot(filename1,filename2):
    arr = np.loadtxt(filename1)
    arr2 = np.loadtxt(filename2)

    sigma = np.std(arr)
    mu = np.mean(arr)
    n, bins, patches = plt.hist(x=arr, bins='auto', color='#0504aa', alpha=0.7,log=True)
    n, bins, patches = plt.hist(x=arr2, bins='auto', color='#ff04aa', alpha=0.7,log=True)
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    try:
        # periodic deviation plots
        deviation_plot('logs/rt1k.txt',delta_t=1000)
        deviation_plot('logs/rt5k.txt',delta_t=200)
        
    finally:
        pass
