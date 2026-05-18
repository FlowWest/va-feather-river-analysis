# analysis-figures.R
# Generates the four supplementary HSI figures from:
#   feather_river_cover_analysis_salmon.Rmd
#   feather_river_cover_analysis_steelehead.Rmd
#
# Output (saved to figures/):
#   chinook_hsi_lfc_hfc.png          – HA/HU/HSI by channel (HFC vs LFC)
#   chinook_hsi_locations_boxplot.png – HA/HU/HSI variability across locations
#   steelhead_hsi_lfc_hfc.png
#   steelhead_hsi_locations.png

library(tidyverse)
library(sf)
library(scales)
library(here)

# ── shared setup ──────────────────────────────────────────────────────────────

theme_set(
  theme_minimal() +
    theme(
      plot.title    = element_text(size = 14, face = "bold"),
      axis.title.x  = element_text(size = 14),
      axis.title.y  = element_text(size = 14)
    )
)

source(here("data-raw", "pull_from_edi.R"))

cover_vars        <- c("small_woody", "large_woody", "overhanging_veg",
                       "undercut_bank", "aquatic_veg", "boulder_substrate",
                       "cobble_substrate", "surface_turbidity")
percent_threshold <- 20

# ── helper: join redd data to nearest snorkel transect (within 50 m) ─────────
# redd_sf must have columns: location, number_redds (geometry = point, crs 4326)

build_redd_summary <- function(redd_sf, mini_snorkel_raw) {
  mini_sf <- mini_snorkel_raw |>
    filter(!is.na(longitude)) |>
    st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

  dist_m <- st_distance(
    redd_sf,
    mini_sf[st_nearest_feature(redd_sf, mini_sf), ],
    by_element = TRUE
  )

  redd_near <- redd_sf |>
    mutate(dist_to_nearest = as.numeric(dist_m)) |>
    filter(dist_to_nearest <= 50)

  st_join(
    redd_near |> select(-any_of("location")),
    mini_sf,
    join = st_nearest_feature
  ) |>
    st_drop_geometry() |>
    group_by(location) |>
    summarise(
      redd_total    = sum(number_redds),
      redd_mean     = mean(number_redds),
      redd_median   = median(number_redds),
      redd_presence = as.integer(redd_total > 0),
      .groups = "drop"
    )
}

# ── helper: build model-ready data ───────────────────────────────────────────

prep_model_data <- function(mini_snorkel_raw, redd_summary) {
  mini_snorkel_raw |>
    select(
      count, location, channel_location, depth, velocity,
      contains("inchannel"), contains("overhead"),
      percent_cobble_substrate, percent_boulder_substrate, percent_undercut_bank,
      month, fl_mm, channel_geomorphic_unit, reach_length, surface_turbidity,
      reach_width, channel_type
    ) |>
    mutate(
      small_woody       = percent_small_woody_cover_inchannel,
      large_woody       = percent_large_woody_cover_inchannel,
      boulder_substrate = percent_boulder_substrate,
      cobble_substrate  = percent_cobble_substrate,
      undercut_bank     = percent_undercut_bank,
      aquatic_veg       = percent_submerged_aquatic_veg_inchannel,
      overhanging_veg   = percent_cover_half_meter_overhead +
                          percent_cover_more_than_half_meter_overhead
    ) |>
    mutate(
      cobble_substrate  = ifelse(percent_cobble_substrate  >= percent_threshold, 1, 0),
      boulder_substrate = ifelse(percent_boulder_substrate >= percent_threshold, 1, 0),
      small_woody       = ifelse(small_woody               >= percent_threshold, 1, 0),
      large_woody       = ifelse(large_woody               >= percent_threshold, 1, 0),
      aquatic_veg       = ifelse(aquatic_veg               >= percent_threshold, 1, 0),
      undercut_bank     = ifelse(undercut_bank             >= percent_threshold, 1, 0),
      no_cover_overhead = ifelse(percent_no_cover_overhead >= percent_threshold, 1, 0),
      overhanging_veg   = ifelse(overhanging_veg           >= percent_threshold, 1, 0)
    ) |>
    select(-contains("no_cover")) |>
    distinct() |>
    mutate(fl_mm = ifelse(is.na(fl_mm), 0, fl_mm)) |>
    na.omit() |>
    select(-fl_mm) |>
    left_join(redd_summary, by = "location") |>
    mutate(
      redd_total    = replace_na(redd_total, 0),
      redd_presence = replace_na(redd_presence, 0),
      month         = as.factor(month),
      presence      = as.integer(count > 0)
    )
}

# ── helper: compute HA / HU / HSI for a given grouping variable ───────────────

compute_hsi <- function(log_reg_data, site_var) {
  df_long <- log_reg_data |>
    select(all_of(site_var), presence, all_of(cover_vars)) |>
    mutate(across(all_of(cover_vars), ~ as.integer(.x > 0))) |>
    pivot_longer(cols = all_of(cover_vars),
                 names_to = "feature", values_to = "feature_present")

  df_long |>
    group_by(.data[[site_var]], feature) |>
    summarise(
      n_all                       = n(),
      n_present_feature           = sum(feature_present == 1, na.rm = TRUE),
      n_fish_present              = sum(presence == 1, na.rm = TRUE),
      n_fish_present_with_feature = sum(presence == 1 & feature_present == 1, na.rm = TRUE),
      .groups = "drop"
    ) |>
    group_by(.data[[site_var]]) |>
    mutate(
      HA      = n_present_feature / n_all,
      HU      = ifelse(n_fish_present > 0,
                       n_fish_present_with_feature / n_fish_present, NA_real_),
      P       = HU / HA,
      HSI_raw = ifelse(is.finite(P), P / max(P, na.rm = TRUE), NA_real_)
    ) |>
    ungroup() |>
    select(all_of(site_var), feature, HA, HU, HSI_raw) |>
    pivot_longer(cols = c(HA, HU, HSI_raw),
                 names_to = "panel", values_to = "value") |>
    mutate(
      panel   = recode(panel,
                       HA      = "HA (availability)",
                       HU      = "HU (utilization)",
                       HSI_raw = "HSI (preference)"),
      feature = str_replace_all(feature, "_", " "),
      feature = if_else(feature == "surface turbidity", "surface turbulence", feature)
    )
}

# ── shared theme for HSI figures ─────────────────────────────────────────────

theme_hsi <- function() {
  theme_classic(base_size = 14) +
    theme(
      axis.text.x      = element_text(angle = 45, hjust = 1, size = 12),
      axis.text.y      = element_text(size = 12),
      axis.title       = element_text(size = 14),
      strip.background = element_rect(fill = "white", color = "black", linewidth = 0.5),
      strip.text       = element_text(size = 12),
      panel.border     = element_rect(color = "black", fill = NA, linewidth = 0.5),
      axis.line        = element_blank(),
      plot.title       = element_text(size = 13),
      plot.subtitle    = element_text(size = 11, color = "grey40")
    )
}

# ── figure builders ───────────────────────────────────────────────────────────

# Bar chart: HA / HU / HSI by channel (HFC vs LFC)
plot_hsi_channel <- function(log_reg_data, title) {
  compute_hsi(log_reg_data, "channel_location") |>
    ggplot(aes(x = feature, y = value)) +
    geom_col(fill = "black", alpha = 0.8) +
    facet_grid(panel ~ channel_location, scales = "free_y") +
    labs(x = NULL, y = "Value (0–1)", title = title) +
    theme_hsi()
}

# Boxplot: HA / HU / HSI variability across locations (chinook style)
plot_hsi_locations_boxplot <- function(log_reg_data, title) {
  compute_hsi(log_reg_data, "location") |>
    ggplot(aes(x = value, y = feature)) +
    geom_boxplot() +
    facet_wrap(~panel, ncol = 1) +
    labs(x = "Value (0–1)", y = NULL, title = title) +
    theme_hsi() +
    theme(axis.text.x = element_text(angle = 0, size = 12))
}

# Jitter + mean diamond: HA / HU / HSI variability across locations (steelhead style)
plot_hsi_locations_jitter <- function(log_reg_data, title) {
  compute_hsi(log_reg_data, "location") |>
    ggplot(aes(x = value, y = feature, color = feature)) +
    geom_jitter(height = 0.2, alpha = 0.5, size = 1.8) +
    stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "black") +
    facet_wrap(~panel, ncol = 1) +
    scale_color_manual(guide = "none",
                       values = setNames(rep("black", length(cover_vars)),
                                         str_replace_all(cover_vars, "_", " "))) +
    labs(x = "Value (0–1)", y = NULL, title = title,
         subtitle = "Points = locations; diamond = mean") +
    theme_hsi() +
    theme(axis.text.x = element_text(angle = 0, size = 12))
}

# ══════════════════════════════════════════════════════════════════════════════
# CHINOOK SALMON
# ══════════════════════════════════════════════════════════════════════════════

mini_snorkel_chinook <- mini_fish_raw |>
  left_join(mini_locations_raw |> distinct()) |>
  mutate(
    count         = ifelse(is.na(count), 0, count),
    fish_presence = as.factor(ifelse(count < 1, "0", "1")),
    month         = month(date)
  ) |>
  filter(species == "chinook salmon" | count == 0)

redd_chinook_sf <- redd_data |>
  filter(number_redds > 0) |>
  rename(date_redd = date) |>
  filter(!is.na(longitude)) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

redd_summary_chinook <- build_redd_summary(redd_chinook_sf, mini_snorkel_chinook)

log_reg_chinook <- prep_model_data(mini_snorkel_chinook, redd_summary_chinook)

# Figure S1: HSI by channel location
ggsave(
  here("figures", "chinook_hsi_lfc_hfc.png"),
  plot_hsi_channel(log_reg_chinook,
    "Chinook - Habitat feature availability, use, and preference by channel location"),
  width = 12, height = 9, dpi = 300, bg = "white"
)

# Figure S2: HSI across locations (boxplot)
ggsave(
  here("figures", "chinook_hsi_locations_boxplot.png"),
  plot_hsi_locations_boxplot(log_reg_chinook,
    "Chinook habitat: habitat variability across locations"),
  width = 12, height = 9, dpi = 300, bg = "white"
)

# ══════════════════════════════════════════════════════════════════════════════
# STEELHEAD
# ══════════════════════════════════════════════════════════════════════════════

mini_snorkel_steelhead <- mini_fish_raw |>
  left_join(mini_locations_raw |> distinct()) |>
  mutate(
    count         = ifelse(is.na(count), 0, count),
    fish_presence = as.factor(ifelse(count < 1, "0", "1")),
    month         = month(date)
  ) |>
  filter(species %in% c("steelhead trout (wild)", "steelhead trout (clipped)") | count == 0)

redd_steelhead_sf <- readxl::read_excel(here("data-raw", "SH Redd Survey.xlsx")) |>
  janitor::clean_names() |>
  rename(number_redds = number_of_redds, date_redd = date) |>
  filter(number_redds > 0) |>
  mutate(lat = as.numeric(lat), long = as.numeric(long)) |>
  filter(!is.na(lat), !is.na(long)) |>
  st_as_sf(coords = c("long", "lat"), crs = 4326)

redd_summary_steelhead <- build_redd_summary(redd_steelhead_sf, mini_snorkel_steelhead)

log_reg_steelhead <- prep_model_data(mini_snorkel_steelhead, redd_summary_steelhead)

# Figure S3: HSI by channel location
ggsave(
  here("figures", "steelhead_hsi_lfc_hfc.png"),
  plot_hsi_channel(log_reg_steelhead,
    "Steelhead - Habitat feature availability, use, and preference by channel location"),
  width = 12, height = 9, dpi = 300, bg = "white"
)

# Figure S4: HSI across locations (jitter + mean)
ggsave(
  here("figures", "steelhead_hsi_locations.png"),
  plot_hsi_locations_jitter(log_reg_steelhead,
    "Steelhead habitat: habitat variability across locations"),
  width = 12, height = 9, dpi = 300, bg = "white"
)
