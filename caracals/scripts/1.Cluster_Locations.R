# This script takes in the individual .csv data and calculates centroids for each based on 
# Harversine distance between lat/long pairs. Potential sensitivity in parameters:
# eps = reachability, in km; and minpts = reachability min. points, see Ester et al 1996
# for more details and ?dbscan for details on the function 

# Set basic stuff we need on the cluster rstudio
setwd('~/merondun/misc_research/caracals/')
.libPaths('~/mambaforge/envs/caracals/lib/R/library')

library(tidyverse)
library(geosphere)
library(fpc)

#read in caracal data
files = list.files('data',pattern='csv',full.names = TRUE)
df = NULL
for (file in files) {
  d =  read.csv(file,header=TRUE) %>% as_tibble
  df = rbind(df,d)
}

##### Data Prep ##### 

# Transform Date_time and calculate time differences
df = df %>%
  mutate(Date_time = paste0(Date,' ',Time),
         Date_time = mdy_hms(Date_time)) %>% 
  arrange(ID, Date_time) %>%
  group_by(ID) %>%
  mutate(Time_diff = c(0, diff(Date_time))/3600)

# Weighted centroids across the whole dataset is pretty meh because 
# this is a lot of data points and points outside of the core region could 
# place centroid in a region a caracal never actually visits, hence I will calculate a cluster
# We'll use the Haversine (great-circle) distance to calculate distance between lat-lon pairs (geosphere)

# Define a function to compute the distance matrix for each individual
compute_dist_mat <- function(data) {
  coords <- cbind(data$Longitude, data$Latitude)
  dist_mat <- distm(coords, fun = distHaversine)/1000  # Get the distance in km
  return(dist_mat)
}

# Set DBSCAN parameters: eps in km, minPts as the minimum number of points in a cluster
eps <- 0.5
minPts <- 20

# Compute the clusters for each individual and calculate centroid of each cluster
centroids <- df %>%
  group_by(ID) %>%
  do({
    data = .
    dist_mat = compute_dist_mat(data)
    data$cluster = dbscan(dist_mat, eps = eps, MinPts = minPts)$cluster
    data
  }) %>%
  group_by(ID, cluster) %>%
  summarise(centroid_lat = mean(Latitude, na.rm = TRUE), 
            centroid_long = mean(Longitude, na.rm = TRUE), .groups = "drop")

# Join these clusters back with the data frame so that we have a single data frame 
# Cluster as '0' is noise from dbscan so remove these. 
df_full <- df %>%
  full_join(centroids, by = c("ID"),relationship = 'many-to-many') %>%
  filter(cluster != 0) %>% 
  rowwise() %>%
  mutate(dist_to_centroid = distm(cbind(Longitude, Latitude), 
                                  cbind(centroid_long, centroid_lat), 
                                  fun = distHaversine)) # distance in meters 
write.table(df_full,file='data/Caracal_Denning_Data_2023JUNE25.txt',quote=F,sep='\t',row.names=F)

