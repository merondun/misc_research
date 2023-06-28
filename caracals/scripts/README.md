# Scripts

1. `Cluster_Locations.R`: This script is used for identifying clusters within the tracking data. It utilizes DBSCAN, a density-based clustering algorithm, to identify spatial clusters which represent significant locations in the tracked movement.

2. `Trip_Identification.R`: This script identifies 'trips' in the tracking data. A 'trip' begins when an animal moves more than a certain distance away from a cluster centroid, and ends once the animal returns within that distance.

3. `Trip_Analysis.R`: This script is used for performing statistical analyses on the identified trips. It filters for trips of certain durations and calculates various metrics, such as maximum distance traveled and total distance traveled.

4. `Plot_Trips.R`: This script generates visual plots of the identified trips on a map. It provides a spatial visual representation of the animal's movements, with each trip highlighted separately.


