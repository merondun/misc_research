library(dplyr)
library(lubridate)
library(ggmap)
library(ggplot2)
library(sf)
library(viridis)
library(ggpubr)
library(OpenStreetMap)
library(fpc)
library(purrr)
library(geosphere)
library(tidyverse)

#read in caracal data
files = list.files('C:/Users/herit/My Drive/Research/Caracal/Denning/2023JUNE',pattern='csv',full.names = TRUE)
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


##### Plotting #####

# Define bounding box for the map
upperleft = c(max(df$Latitude)+0.05,min(df$Longitude)-0.02)
lowerright = c(min(df$Latitude)-0.05,max(df$Longitude)+0.02)

# Boundary
sa_map <- openmap(upperLeft = upperleft,lowerRight = lowerright, type = "stamen-terrain")

# reproject onto WGS84
sa_map2 <- openproj(sa_map)

# use instead of 'ggplot()'
fullmap = OpenStreetMap::autoplot.OpenStreetMap(sa_map2) +
  geom_point(data = df, aes(x=Longitude, y=Latitude, col=ID),size=1,alpha=0.5) +
  geom_point(data = df_centroid, aes(x=Longitude, y=Latitude, fill=ID),shape=25,size=2)+
  xlab('Longitude')+ylab('Latitude')+
  theme_bw()+
  scale_color_viridis(discrete=TRUE)+
  scale_fill_viridis(discrete=TRUE)

#and also plot individuals separately
cols = viridis(4) ; counter = 0
for (caracal in unique(df$ID)) { 
  
  cat('Plotting caracal: ',caracal,'\n')
  counter = counter + 1 
  sampdat = df %>% filter(ID == caracal)
  centroid = centroids %>% filter(ID == caracal & cluster != 0)
  
  # Define bounding box for the map, extract the map, project it
  upperleft = c(max(sampdat$Latitude)+0.01,min(sampdat$Longitude)-0.01)
  lowerright = c(min(sampdat$Latitude)-0.01,max(sampdat$Longitude)+0.01)
  sa_map <- openmap(upperLeft = upperleft,lowerRight = lowerright, type = "stamen-terrain")
  sa_map2 <- openproj(sa_map)
  
  # Plot 
  map = OpenStreetMap::autoplot.OpenStreetMap(sa_map2) +
    geom_point(data = sampdat, aes(x=Longitude, y=Latitude),col=cols[counter],size=2,alpha=0.5) +
    geom_point(data = centroid, aes(x=centroid_long, y=centroid_lat,fill=as.factor(cluster)),shape=25,size=4)+
    scale_fill_brewer('Cluster',palette='Dark2')+
    xlab('Longitude')+ylab('Latitude')+
    theme_bw()
  assign(paste0('p',counter),map)
}

ggarrange(p1,p2,p3,p4,nrow=2,ncol=2)

##### Calculate some metrics #####

# We will base all these analyses on a 'trip'
library(geosphere)

# Compute the distance to the centroid for each point and each cluster
df_full <- df %>%
  full_join(centroids, by = c("ID"),relationship = 'many-to-many') %>%
  filter(cluster != 0) %>% 
  rowwise() %>%
  mutate(dist_to_centroid = distm(cbind(Longitude, Latitude), 
                                  cbind(centroid_long, centroid_lat), 
                                  fun = distHaversine)) # distance in meters 

# Define the start and end of a trip. A trip starts when the individual is 
# more than 50m from the cluster centroid, and ends when the individual 
# returns within 50m of the centroid
df_full <- df_full %>%
  group_by(ID, cluster) %>%
  arrange(Date_time) %>%
  mutate(trip_start = ifelse(dist_to_centroid > 50 & lag(dist_to_centroid) <= 50, 1, 0),
         trip_end = ifelse(dist_to_centroid <= 50 & lag(dist_to_centroid) > 50, 1, 0)) %>% 
  replace_na(list(trip_start = 0, trip_end = 0)) %>%
  mutate(trip = cumsum(trip_start)) %>% 
  ungroup()

# How many trips for each caracal
df_full %>% count(ID,trip,cluster) %>%
  ggplot(aes(x=ID,y=trip,fill=ID))+
  geom_bar(stat='identity',position=position_dodge())+
  scale_fill_viridis(discrete=TRUE)+
  facet_grid(.~cluster)+
  ggtitle('Total Number of Trips, Facets Correspond to Putative Cluster')+
  xlab('')+ylab('Number of Trips')+
  theme_bw()

# Summarize those trips! 
trip_summaries <- df_full %>%
  group_by(ID, cluster, trip) %>%
  summarise(trip_start = min(Date_time),
            max_dist = max(dist_to_centroid, na.rm = TRUE),
            total_dist = sum(dist_to_centroid, na.rm = TRUE),
            duration = max(Date_time) - min(Date_time) ,
            duration_min = as.numeric(duration/60),
            .groups = "drop")

# Drop extreme outliers
tidy_trip <- trip_summaries %>%
  mutate(across(c(duration_min, max_dist, total_dist),
                ~if_else(.x > quantile(.x, 0.975), NA_real_, .x))) %>% 
  select(-duration) %>% 
  pivot_longer(!c(ID,cluster,trip,trip_start)) %>% 
  mutate(ID_cluster = paste0(ID,'_',cluster))  

#Plots 
tidy_trip %>% ggplot(aes(x=trip_start,col=ID,y=value))+
  geom_point()+
  #geom_bar(stat='identity',position=position_dodge())+
  scale_color_viridis(discrete=TRUE)+
  facet_grid(name~ID_cluster,scales='free')+
  ggtitle('Trip Duration & Distance, Facets Correspond to Putative Cluster+ID')+
  xlab('Date')+
  theme_bw()

tidy_trip %>% 
  mutate(days_since_start = as.numeric(difftime(trip_start, min(trip_start), units = "days")))

