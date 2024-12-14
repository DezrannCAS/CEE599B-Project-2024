rm(list = ls())

here::i_am("src/igraph/stat_testing.r")

library(here)
library(readr)
library(dplyr)
library(ggplot2)

output_path <- here("output")
csv_file <- file.path(output_path, "RG_centrality_results.csv")
data <- read.csv(csv_file)

# data$efficiency_based <- as.factor(data$efficiency_based)
# print(table(data$efficiency_based))


# # ---------- TEST CENTRAL TENDENCY ----------

# # Perform Welch's ANOVA
# welch_anova <- oneway.test(demand ~ efficiency_based, data = data, var.equal = FALSE)
# print(welch_anova)

# # Perform the Games-Howell test for unequal variances
# post_hoc <- posthocTGH(data$demand, data$efficiency_based, method = "games-howell")
# print(post_hoc)

# # Visualize
# ggplot(data, aes(x = efficiency_based, y = demand)) +
#   geom_boxplot() +
#   theme_minimal() +
#   labs(title = "Group Differences in Demand")
# ggsave("group_differences_plot.png", plot = my_plot, width = 8, height = 6, dpi = 300)


# ---------- TRANSFORM AND FIT ----------


data$log_demand <- (data$demand)
data$log_efficiency <- (data$efficiency_based)**2


# Fit linear regression models
model_original <- lm(efficiency_based ~ demand, data = data)
model_log_demand <- lm(efficiency_based ~ log_demand, data = data)
model_log_efficiency <- lm(log_efficiency ~ demand, data = data)
model_log_both <- lm(log_efficiency ~ log_demand, data = data)

# Summarize the models
summary(model_original)
summary(model_log_demand)
summary(model_log_efficiency)
summary(model_log_both)

# Visualize the data and regression lines
ggplot(data, aes(x = demand, y = efficiency_based)) +
  geom_point() +
  geom_smooth(method = "lm", color = "blue", se = FALSE) +
  ggtitle("Original Data with Linear Regression")
ggsave("original_plot.png", plot = plot_original, width = 6, height = 4)

ggplot(data, aes(x = log_demand, y = log_efficiency)) +
  geom_point() +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  ggtitle("Log-Transformed Data with Linear Regression")
ggsave("log_transformed_plot.png", plot = plot_log, width = 6, height = 4)
