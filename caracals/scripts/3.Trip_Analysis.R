# This script takes the output of Cluster_Locations.R and analyzes some trip information
# Potential parameter sensitivity in the distance away from centroid a track is considered
# a 'trip'

# Set basic stuff we need on the cluster rstudio
setwd('C:/Users/herit/My Drive/Research/Caracal/Denning/2023JUNE')
#setwd('~/merondun/misc_research/caracals/')
#.libPaths('~/mambaforge/envs/caracals/lib/R/library')
set.seed(111)

library(tidyverse)
library(geosphere)
library(viridis)
library(sf)
library(ggmap)

full_trip = read.table('Caracal_Denning_Data_Trips-250m_2023JUNE25.txt',header=TRUE,comment.char='',sep='\t') %>% 
  as_tibble %>% 
  group_by(ID,trip_ID) %>% 
  mutate(Date_time = ymd_hms(Date_time), #ensure date in interpreted correctly
         trip_start = min(Date_time)) %>% #add the beginning of the trip 
  ungroup

##### Trip Analysis ##### 

# First explore raw trip data 
trip_data = full_trip %>% select(ID,trip_start,trip_ID,max_dist,total_dist,total_hours) %>% unique %>%
  drop_na(trip_ID)
trip_data %>% 
  pivot_longer(!c(ID,trip_start,trip_ID)) %>% 
  ggplot(aes(x=trip_start,col=ID,y=value))+
  geom_point()+
  #geom_bar(stat='identity',position=position_dodge())+
  scale_color_viridis(discrete=TRUE)+
  facet_grid(name~ID,scales='free')+
  ggtitle('Trip Duration & Distance')+
  xlab('Date')+
  theme_bw()

#Generates the table found on github
trip_data %>% group_by(ID) %>% slice_max(total_hours, n =2)

# Set the maximum trip to a week, probably still too high
trip_data = trip_data %>% filter(total_hours < 96)

# Plot Some Summaries of Trips 
tidy_trip <- trip_data %>%
  mutate(max_dist = max_dist/1000,  #conver to km from m 
         total_dist = total_dist/1000) %>% 
  #mutate(across(c(total_hours, max_dist, total_dist),  #this command will replace any observations above the 99% IQR with NA to deal with outliers
  #              ~if_else(.x > quantile(.x, 0.99), NA_real_, .x))) %>% 
  dplyr::rename('Max Distance (km)' = max_dist,'Total Distance (km)' = total_dist,'Total Hours (h)' = total_hours) %>% 
  pivot_longer(!c(ID,trip_ID,trip_start)) %>% drop_na(value)

# Plots 
tidy_trip %>% ggplot(aes(x=trip_start,col=ID,y=value,shape=name))+
  geom_point()+
  #geom_bar(stat='identity',position=position_dodge())+
  scale_color_viridis(discrete=TRUE)+
  facet_grid(name~ID,scales='free')+
  ggtitle('Trip Duration & Distance')+
  xlab('')+ylab('')+
  theme_bw()+
  theme(axis.text.x=element_text(angle=45,vjust=1,hjust=1))

tidy_trip %>% 
  group_by(ID) %>% 
  mutate(days_since_start = as.numeric(difftime(trip_start, min(trip_start), units = "days")))

# Do simple linear model to see the effects of variable ~ time since den starting
stats = tidy_trip %>% 
  group_by(ID, name) %>%
  summarize(rho = cor(as.numeric(trip_start),value,method='spearman'))
# We will add a simple x-axis label to the beginning date for each ID
dates = tidy_trip %>% group_by(ID) %>% slice_min(trip_start,n=1) %>% ungroup %>% select(-c(value,trip_ID,name))
stats = left_join(stats,dates,relationship='many-to-many')

# Plot the points and the labels 
trip_stats = tidy_trip %>% ggplot(aes(x=trip_start,col=ID,y=value,shape=name))+
  geom_point()+
  geom_text(data=stats,aes(x=trip_start,y=Inf,label=paste("rho: ", signif(rho, 2))),
            size=2.5,vjust=1.25,hjust=-.1,col='black',parse=TRUE)+
  scale_color_viridis('Caracal',discrete=TRUE)+
  scale_shape_manual('Variable',values=c(16,17,15))+
  facet_grid(name~ID,scales='free')+
  ggtitle('Trip Duration & Distance')+
  xlab('')+ylab('')+
  theme_bw()+
  theme(axis.text.x=element_text(angle=45,vjust=1,hjust=1))
trip_stats

pdf('Caracal_Trip_Stats_250m-2023JUNE25.pdf',height=6,width=9)
trip_stats
dev.off()

write.table(stats,file='Caracal_Trip_Stats_250m-2023JUNE25.txt',quote=F,sep='\t',row.names=F)


