rm(list = ls())

here::i_am("src/igraph/stat_testing.r")

library(here)
library(readr)
library(dplyr)
library(ggplot2)

output_path <- here("output")
csv_file <- file.path(output_path, "RG_centrality_results.csv")
data <- read.csv(csv_file)


# # ---------- TEST CENTRAL TENDENCY ----------



# Ensure factor conversion by binning
data <- data %>%
  mutate(bin = cut(efficiency_based, breaks = 8, labels = FALSE))

# Perform Welch's ANOVA
anova_result <- oneway.test(demand ~ factor(bin), data = data, var.equal = FALSE)
print(anova_result)

# Perform Games-Howell post-hoc test
games_howell_test <- function(data, group_col, value_col) {
  library(multcomp)
  # Create a model using aov
  aov_model <- aov(as.formula(paste(value_col, "~", group_col)), data = data)
  # Extract group means and apply Games-Howell
  pairwise_results <- glht(aov_model, linfct = mcp(factor(bin) = "Tukey"))
  summary(pairwise_results, test = adjusted("none"))
}

if (anova_result$p.value < 0.05) {
  cat("\nWelch's ANOVA is significant. Performing Games-Howell post-hoc test.\n\n")
} else {
  cat("\nWelch's ANOVA is not significant. No post-hoc tests needed.\n")
}

ggplot(data, aes(x = factor(bin), y = demand)) +
  geom_boxplot() +
  labs(title = "Demand by Efficiency-Based Bins",
       x = "Efficiency-Based Bins",
       y = "Demand") +
  theme_minimal()
ggsave("demand_by_efficiency.png", plot = plot_trans, width = 6, height = 4)

# ---------- TRANSFORM AND FIT ----------


# data$transformed_demand <- (data$demand+1)**(-1/2) 
# data$transformed_efficiency <- (data$efficiency_based+1)**(-1/2)

# # Fit linear regression models
# model_original <- lm(efficiency_based ~ demand, data = data)
# model_transformed_demand <- lm(efficiency_based ~ transformed_demand, data = data)
# model_transformed_efficiency <- lm(transformed_efficiency ~ demand, data = data)
# model_transformed_both <- lm(transformed_efficiency ~ transformed_demand, data = data)

# # Summarize the models
# summary(model_original)
# summary(model_transformed_demand)
# summary(model_transformed_efficiency)
# summary(model_transformed_both)

# # Visualize the data and regression lines
# plot_original <- ggplot(data, aes(x = demand, y = efficiency_based)) +
#   geom_point() +
#   geom_smooth(method = "lm", color = "blue", se = FALSE) +
#   ggtitle("Original Data with Linear Regression")
# ggsave("original_plot.png", plot = plot_original, width = 6, height = 4)

# plot_trans <- ggplot(data, aes(x = transformed_demand, y = transformed_efficiency)) +
#   geom_point() +
#   geom_smooth(method = "lm", color = "red", se = FALSE) +
#   ggtitle("Transformed Data with Linear Regression")
# ggsave("transformed_plot.png", plot = plot_trans, width = 6, height = 4)
