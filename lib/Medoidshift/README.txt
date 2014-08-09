These files implement the medoidshift algorithm described in:
Yaser Ajmal Sheikh, Erum Arif Khan, Takeo Kanade, "Mode-seeking via Medoidshifts", IEEE International Conference on Computer Vision, 2007.

For further information contact: yaser@cs.cmu.edu

They have been tested on MATLAB Version 7.0.0.19920 (R14).

**
Examples are included:

Example_TwoBivariateGaussians.m: Clustering two bivariate Gaussian distributions
Example_TwoSpirals.m: Clustering using the ISOMAP distance matrix on 3D data

**
Code producing figures in the paper:

Figure1_MeanshiftVsMedoidshift.m
Figure7a_FiveCrescents.m
Figure8_FourSpirals.m

**
The basic code:

medoidshift.m: Code that takes in a distance matrix and a bandwidth parameter and returns the modes for each index
medoidshiftIterative.m: Implements one iteration of medoidshift
IsomapIID.m: Modified ISOMAP code from http://isomap.stanford.edu
dijkstra.m: For IsomapIID.m from http://isomap.stanford.edu
classify.m: Tree traversal algorithm (Step 2 in paper)
classify_slow.m: Slower version
