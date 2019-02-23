# Read the data
datas <- read.csv("C:/Users/Vanesa/Desktop/quant.csv", sep=";")
datas


# Package to do work with data frames easily and do summaries 
# fairly easy to compute


#install_packages('dplyr')

#Load the package 
library(dplyr)

# Group the data per Feature and environment
# You can also just group it by one variable if you 
# need summaries just per environment for example
#selection = c("Point landmark", "Linear landmark", "Aereal landmark")
selection = c("Administrative region", "Environmental region") 
datas %>% filter (Features %in% selection) %>% group_by(environment) %>% 
  # Summarize each group
  summarize(
    # compute the count
    count = n(),
    # compute the sum, 
    sum = sum(value),
    mean = mean(value),
    max = max(value),
    min = min(value),
    median = median(value),
    perc2 = quantile(value, 0.2),
    sd = sd(value)
  )

#Create boxplot
library(ggplot2)
boxplot <- ggplot(datas, aes(x=Features, y=value, group=Features)) + 
  geom_boxplot(aes(fill=Features))

boxplot

boxplot + facet_grid(. ~ environment) +
  ggtitle("Features included in each route") +
  theme(plot.title = element_text(hjust = 0.5)) + theme(axis.text.x=element_blank(), axis.ticks.x=element_blank())


