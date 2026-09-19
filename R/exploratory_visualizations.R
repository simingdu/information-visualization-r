library(ggplot2)
library(dplyr)
library(scales)

# Load FEC candidate finance data
data_url <- "https://www.ics.uci.edu/~algol/teaching/s2022-IV/fec_2008-2022.csv"
fec <- read.csv(data_url)

# Remove index column if present
if ("X" %in% names(fec)) {
  fec$X <- NULL
}

# Keep Democratic and Republican candidate-year records
major_parties <- fec %>%
  filter(Cand_Party_Affiliation %in% c("DEM", "REP"))

# Create output directory
dir.create("images", showWarnings = FALSE)


# ------------------------------------------------------------
# 1. Candidate records by office and party
# ------------------------------------------------------------

candidate_counts <- as.data.frame(
  table(
    major_parties$Cand_Office,
    major_parties$Cand_Party_Affiliation
  )
)

names(candidate_counts) <- c("Office", "Party", "Count")

candidate_counts$Office <- factor(
  candidate_counts$Office,
  levels = c("H", "S", "P"),
  labels = c("House", "Senate", "President")
)

candidate_records_plot <- ggplot(
  candidate_counts,
  aes(x = Office, y = Count, fill = Party)
) +
  geom_col(position = "dodge") +
  labs(
    title = "Candidate Records by Office and Party",
    x = "Office",
    y = "Number of Candidate-Year Records",
    fill = "Party"
  ) +
  theme_minimal()

ggsave(
  "images/candidate_records.png",
  candidate_records_plot,
  width = 8,
  height = 5,
  dpi = 300
)


# ------------------------------------------------------------
# 2. Total receipts by party across election years
# ------------------------------------------------------------

major_parties$Coverage_End_Date <- as.Date(
  major_parties$Coverage_End_Date,
  format = "%m/%d/%Y"
)

major_parties$Year <- as.numeric(
  format(major_parties$Coverage_End_Date, "%Y")
)

election_years <- c(
  2008, 2010, 2012, 2014,
  2016, 2018, 2020, 2022
)

receipts_by_year <- major_parties %>%
  filter(Year %in% election_years) %>%
  group_by(Year, Cand_Party_Affiliation) %>%
  summarize(
    Total_Receipt = sum(Total_Receipt, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Receipt_Billions = Total_Receipt / 1e9
  )

receipts_by_year_plot <- ggplot(
  receipts_by_year,
  aes(
    x = Year,
    y = Receipt_Billions,
    color = Cand_Party_Affiliation,
    group = Cand_Party_Affiliation
  )
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_x_continuous(breaks = election_years) +
  labs(
    title = "Total Receipts by Party in Election Years",
    x = "Election Year",
    y = "Total Receipts (Billions of Dollars)",
    color = "Party"
  ) +
  theme_minimal()

ggsave(
  "images/receipts_by_year.png",
  receipts_by_year_plot,
  width = 8,
  height = 5,
  dpi = 300
)


# ------------------------------------------------------------
# 3. Distribution of candidate receipts by party
# ------------------------------------------------------------

receipt_distribution <- major_parties %>%
  mutate(
    Log_Total_Receipt = log10(Total_Receipt + 1)
  )

receipt_distribution_plot <- ggplot(
  receipt_distribution,
  aes(
    x = Cand_Party_Affiliation,
    y = Log_Total_Receipt,
    fill = Cand_Party_Affiliation
  )
) +
  geom_boxplot() +
  labs(
    title = "Distribution of Candidate Receipts by Party",
    x = "Party",
    y = "log10(Total Receipts + 1)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none"
  )

ggsave(
  "images/receipt_distribution.png",
  receipt_distribution_plot,
  width = 7,
  height = 5,
  dpi = 300
)