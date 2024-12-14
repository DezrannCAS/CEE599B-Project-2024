rm(list = ls())

here::i_am("src/igraph/centralities.r")

library(here)
library(patchwork)
library(readr)
library(dplyr)
library(ggplot2)

output_path <- here("output")
fig_path <- file.path(output_path, "fig")


# ------------ FUNCTIONS ------------

# Plot
plot_results <- function(data, measures, response_var = "demand") {
  data <- data %>% filter(!!sym(response_var) > 0)
  plots <- list()
  for (measure in measures) {
    p <- ggplot(data, aes(x = .data[[measure]], y = !!sym(response_var))) +
      geom_point(alpha = 0.5) +
    #   geom_smooth(method = "loess", se = FALSE, color = "red") +
      theme_minimal() +
      labs(x = measure,
           y = response_var)

    plots[[measure]] <- p
  }
  return(plots)
}

plot_boxplots_woutliers <- function(data, measures, categorical_vars = c("degree"), 
                          response_var = "demand") {
  data <- data %>% filter(!!sym(response_var) > 0)
  plots <- list()
  
  for (measure in measures) {
    if (measure %in% categorical_vars) {
      # Ensure the categorical variable is treated as a factor
      data[[measure]] <- as.factor(data[[measure]])
      bin <- data[[measure]]
    } else {
      # Create bins for the continuous measure
      data <- data %>%
        mutate(bin = factor(cut(!!sym(measure), breaks = 8, labels = FALSE)))
      bin <- data$bin  # Bin should be a factor
    }
    
    # Optionally add max and min points
    p <- ggplot(data, aes(x = bin, y = !!sym(response_var), group = bin)) +
         geom_boxplot(outlier.colour = "red", outlier.shape = 16, outlier.size = 2) +
         stat_summary(fun = mean, geom = "point", shape = 18, size = 3, color = "blue") +
         theme_minimal() +
         labs(x = ifelse(measure %in% categorical_vars, measure, paste("Binned", measure)),
              y = response_var)
    
    plots[[measure]] <- p
  }
  
  return(plots)
}

plot_boxplots <- function(data, measures, categorical_vars = c("degree"), response_var = "demand") {
  data <- data %>% filter(!!sym(response_var) > 0)
  plots <- list()
  
  for (measure in measures) {
    if (measure %in% categorical_vars) {
      # Treat categorical variables as factors
      data <- data %>%
        mutate(bin = as.factor(!!sym(measure)))
    } else {
      # Create bins for continuous variables
      data <- data %>%
        mutate(bin = cut(!!sym(measure), breaks = 8, labels = FALSE)) %>%
        mutate(bin = factor(bin))  # Convert bins to factors
    }
    
    # Compute IQR and filter out outliers for each bin
    data <- data %>%
    group_by(bin) %>%
    filter(
      !!sym(response_var) >= quantile(!!sym(response_var), 0.25, na.rm = TRUE) - 1.5 * IQR(!!sym(response_var), na.rm = TRUE) &
      !!sym(response_var) <= quantile(!!sym(response_var), 0.75, na.rm = TRUE) + 1.5 * IQR(!!sym(response_var), na.rm = TRUE)
    ) %>%
    ungroup()

    # Create the boxplot
    p <- ggplot(data, aes(x = bin, y = !!sym(response_var), group = bin)) +
         geom_boxplot(outlier.shape = NA) +
         stat_summary(fun = mean, geom = "point", shape = 18, size = 3, color = "blue") +
         theme_minimal() +
         labs(x = ifelse(measure %in% categorical_vars, measure, paste("Binned", measure)),
              y = response_var)

    plots[[measure]] <- p
  }
  
  return(plots)
}

final_plot <- function(plots, png_file, measures) {
  if ("tank_distance" %in% measures) {
    final_plot <- (plots$degree + plots$strength + plots$closeness) /
                  (plots$betweenness + plots$eccentricity + plots$tank_distance)
  } else {
    final_plot <- (plots$eccentricity + plots$closeness) /
                  (plots$degree + plots$betweenness + plots$efficiency_based)
  }
  
  ggsave(png_file, final_plot, width = 15, height = 10, dpi = 300)
}


# ------------ MAIN CODE ------------


csv_file1 <- file.path(output_path, "OG_centrality_results.csv")
csv_file2 <- file.path(output_path, "RG_centrality_results.csv")

og_centralities <- read_csv(csv_file1)
rg_centralities <- read_csv(csv_file2)

# Sort the data by demand
og_centralities <- og_centralities %>% arrange(demand)
rg_centralities <- rg_centralities %>% arrange(demand)

og_measures <- c("degree", "strength", "closeness", "betweenness", "eccentricity", "tank_distance")
rg_measures <- c("degree", "strength", "closeness", "betweenness", "eccentricity", "efficiency_based")

# Call the function for OG data
og_png_file1 <- file.path(fig_path, "og2_network_measures_vs_demand.png")
og_png_file2 <- file.path(fig_path, "og2_network_measures_vs_demand_boxplot_woutliers.png")
og_png_file3 <- file.path(fig_path, "og2_network_measures_vs_demand_boxplot.png")

# plots <- plot_results(og_centralities, og_measures)
# final_plot(plots, og_png_file1, og_measures)

# plots <- plot_boxplots_woutliers(og_centralities, og_measures)
# final_plot(plots, og_png_file2, og_measures)

# plots <- plot_boxplots(og_centralities, og_measures)
# final_plot(plots, og_png_file3, og_measures)

# Call the function for RG data
rg_png_file1 <- file.path(fig_path, "rg2_network_measures_vs_demand.png")
rg_png_file2 <- file.path(fig_path, "rg2_network_measures_vs_demand_boxplot_woutliers.png")
rg_png_file3 <- file.path(fig_path, "rg2_network_measures_vs_demand_boxplot.png")

plots <- plot_results(rg_centralities, rg_measures)
final_plot(plots, rg_png_file1, rg_measures)

plots <- plot_boxplots_woutliers(rg_centralities, rg_measures)
final_plot(plots, rg_png_file2, rg_measures)

plots <- plot_boxplots(rg_centralities, rg_measures)
final_plot(plots, rg_png_file3, rg_measures)


# # Compute correlations
# correlations <- sapply(centrality_df[, !(names(centrality_df) %in% c("name", "demand"))], 
#                        function(x) cor(centrality_df$demand, x))

# # Print correlations
# print(correlations)


# We can check the hypothesis that degree does show smt because of betweeness

# Calculate correlation
# degree_vs_betweenness <- function(data, png_file, coefficient = "pearson") {
#   correlation <- cor(data$degree, data$betweenness, method = coefficient)
#   print(paste("Correlation coefficient:", correlation))
  
#   # Perform correlation test
#   cor_test <- cor.test(data$degree, data$betweenness, method = coefficient)
#   print(cor_test)
  
#   # Visualize the relationship
#   final_plot <- ggplot(data, aes(x = degree, y = betweenness)) +
#          geom_point() +
#          geom_smooth(method = "lm", color = "blue", se = TRUE) +
#          theme_minimal() +
#          labs(title = "Correlation between Degree and Betweenness",
#               x = "Degree Centrality",
#               y = "Betweenness Centrality")
  
#   ggsave(png_file, final_plot, width = 15, height = 10, dpi = 300)
# }

# png_file <- file.path(fig_path, "degree_vs_betweenness.png")
# degree_vs_betweenness(rg_centralities, png_file)
