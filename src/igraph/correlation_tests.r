
# Compute correlations
correlations <- sapply(centrality_df[, !(names(centrality_df) %in% c("name", "demand"))], 
                       function(x) cor(centrality_df$demand, x))

# Print correlations
print(correlations)

# Print centrality dataframe
print(centrality_df)
