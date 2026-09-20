library(ggplot2)
library(dplyr)
library(stringr)
library(readr)
library(scales)

# Load FEC candidate finance data
data_url <- "https://www.ics.uci.edu/~algol/teaching/s2022-IV/fec_2008-2022.csv"
fec <- read.csv(data_url)

# Remove index column if present
if ("X" %in% names(fec)) {
  fec$X <- NULL
}

# Prepare shared fields
fec_clean <- fec %>%
  mutate(
    Year = as.integer(str_extract(Link_Image, "(?<=cycle=)\\d{4}")),
    Total_Receipt = parse_number(as.character(Total_Receipt)),
    Total_Disbursement = parse_number(as.character(Total_Disbursement))
  )

# Create output directory
dir.create("images", showWarnings = FALSE)


# ============================================================
# Case Study 1: Median campaign receipts by party
# ============================================================

# ------------------------------------------------------------
# Correct visualization
# ------------------------------------------------------------

correct_receipts_data <- fec_clean %>%
  filter(
    Year >= 2008,
    Year <= 2020,
    Cand_Party_Affiliation %in% c("DEM", "REP"),
    !is.na(Total_Receipt),
    Total_Receipt > 0
  ) %>%
  group_by(Year, Cand_Party_Affiliation) %>%
  summarize(
    median_receipt = median(Total_Receipt, na.rm = TRUE),
    candidate_count = n(),
    .groups = "drop"
  )

correct_receipts_plot <- ggplot(
  correct_receipts_data,
  aes(
    x = Year,
    y = median_receipt,
    color = Cand_Party_Affiliation,
    group = Cand_Party_Affiliation
  )
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_y_continuous(
    labels = dollar_format(),
    limits = c(0, NA)
  ) +
  scale_x_continuous(
    breaks = seq(2008, 2020, by = 2)
  ) +
  labs(
    title = "Median Campaign Receipts by Party, 2008-2020",
    subtitle = "Democratic and Republican candidate records with positive receipts",
    x = "Election Cycle Year",
    y = "Median Total Receipts",
    color = "Party",
    caption = "Federal Election Commission candidate summary data"
  ) +
  theme_minimal()

ggsave(
  "images/correct_receipts_by_party.png",
  correct_receipts_plot,
  width = 9,
  height = 5.5,
  dpi = 300
)


# ------------------------------------------------------------
# Intentionally misleading visualization
# ------------------------------------------------------------

misleading_receipts_data <- fec_clean %>%
  filter(
    Year >= 2008,
    Year <= 2016,
    Cand_Party_Affiliation %in% c("DEM", "REP"),
    !is.na(Total_Receipt),
    Total_Receipt > 0
  ) %>%
  group_by(Year, Cand_Party_Affiliation) %>%
  summarize(
    median_receipt = median(Total_Receipt, na.rm = TRUE),
    candidate_count = n(),
    .groups = "drop"
  )

misleading_receipts_plot <- ggplot(
  misleading_receipts_data,
  aes(
    x = Year,
    y = median_receipt,
    color = Cand_Party_Affiliation,
    group = Cand_Party_Affiliation
  )
) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  coord_cartesian(
    ylim = c(
      min(misleading_receipts_data$median_receipt) * 0.92,
      max(misleading_receipts_data$median_receipt) * 1.05
    )
  ) +
  scale_y_continuous(
    labels = dollar_format()
  ) +
  scale_x_continuous(
    breaks = seq(2008, 2016, by = 2)
  ) +
  labs(
    title = "Democrats Appear to Have a Fundraising Advantage",
    subtitle = "Median campaign receipts, 2008-2016",
    x = "Election Cycle Year",
    y = "Median Total Receipts",
    color = "Party",
    caption = "Intentionally misleading example for visualization analysis"
  ) +
  theme_minimal()

ggsave(
  "images/misleading_receipts_by_party.png",
  misleading_receipts_plot,
  width = 9,
  height = 5.5,
  dpi = 300
)


# ============================================================
# Case Study 2: Campaign receipts vs. disbursements
# ============================================================

# ------------------------------------------------------------
# Correct visualization
# ------------------------------------------------------------

correct_spending_data <- fec_clean %>%
  filter(
    Year >= 2008,
    Year <= 2020,
    Cand_Party_Affiliation %in% c("DEM", "REP"),
    !is.na(Total_Receipt),
    !is.na(Total_Disbursement),
    Total_Receipt > 0,
    Total_Disbursement > 0
  )

correct_spending_plot <- ggplot(
  correct_spending_data,
  aes(
    x = Total_Receipt,
    y = Total_Disbursement,
    color = Cand_Party_Affiliation
  )
) +
  geom_point(alpha = 0.35, size = 1.5) +
  geom_smooth(
    method = "lm",
    se = TRUE,
    linewidth = 1,
    show.legend = FALSE
  ) +
  scale_x_log10(
    labels = dollar_format()
  ) +
  scale_y_log10(
    labels = dollar_format()
  ) +
  labs(
    title = "Relationship Between Campaign Receipts and Disbursements",
    subtitle = "Both axes use log10 scales",
    x = "Total Receipts",
    y = "Total Disbursements",
    color = "Party",
    caption = "Federal Election Commission candidate summary data"
  ) +
  theme_minimal()

ggsave(
  "images/correct_receipts_vs_spending.png",
  correct_spending_plot,
  width = 9,
  height = 5.5,
  dpi = 300
)


# ------------------------------------------------------------
# Intentionally misleading visualization
# ------------------------------------------------------------

receipt_cutoff <- quantile(
  correct_spending_data$Total_Receipt,
  0.75,
  na.rm = TRUE
)

misleading_spending_data <- correct_spending_data %>%
  filter(Total_Receipt >= receipt_cutoff)

misleading_spending_plot <- ggplot(
  misleading_spending_data,
  aes(
    x = Total_Receipt,
    y = Total_Disbursement,
    color = Cand_Party_Affiliation
  )
) +
  geom_point(alpha = 0.5, size = 1.8) +
  geom_smooth(
    method = "lm",
    se = FALSE,
    linewidth = 1.2,
    show.legend = FALSE
  ) +
  scale_x_continuous(
    labels = dollar_format(
      scale = 1 / 1000000,
      suffix = "M"
    )
  ) +
  scale_y_continuous(
    labels = dollar_format(
      scale = 1 / 1000000,
      suffix = "M"
    )
  ) +
  scale_color_manual(
    values = c(
      "DEM" = "firebrick",
      "REP" = "gray60"
    )
  ) +
  labs(
    title = "Fundraising Appears to Predict Campaign Spending",
    subtitle = "Top 25% of campaigns by total receipts",
    x = "Total Receipts",
    y = "Total Disbursements",
    color = "Party",
    caption = "Intentionally misleading example for visualization analysis"
  ) +
  theme_minimal()

ggsave(
  "images/misleading_receipts_vs_spending.png",
  misleading_spending_plot,
  width = 9,
  height = 5.5,
  dpi = 300
)