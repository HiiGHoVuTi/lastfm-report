#!/bin/bash

# French Republican Calendar conversion script
# Adapted from a script by an unknown author

# This script is complex because the calendar rules are complex.
# It is based on the equinox, which varies from year to year.

get_republican_date() {
    year=$(date -u +%Y)
    month=$(date -u +%m)
    day=$(date -u +%d)

    # The Republican calendar starts on the autumn equinox.
    # The exact date of the equinox varies, so we use a table of known equinox dates.
    # This table is for the 21st century.
    equinox_day() {
        case $1 in
            2000) echo 22;; 2001) echo 22;; 2002) echo 23;; 2003) echo 23;;
            2004) echo 22;; 2005) echo 22;; 2006) echo 23;; 2007) echo 23;;
            2008) echo 22;; 2009) echo 22;; 2010) echo 23;; 2011) echo 23;;
            2012) echo 22;; 2013) echo 22;; 2014) echo 23;; 2015) echo 23;;
            2016) echo 22;; 2017) echo 22;; 2018) echo 23;; 2019) echo 23;;
            2020) echo 22;; 2021) echo 22;; 2022) echo 23;; 2023) echo 23;;
            2024) echo 22;; 2025) echo 22;; 2026) echo 23;; 2027) echo 23;;
            *) echo 22;; # Default for years not in the list
        esac
    }

    republican_year=$((year - 1792 + 1))
    equinox=$(equinox_day $year)

    # Day of the year for the Gregorian date
    day_of_year=$(date -u -d "$year-$month-$day" +%j)

    # Day of the year for the equinox
    equinox_doy=$(date -u -d "$year-09-$equinox" +%j)

    if [ $day_of_year -lt $equinox_doy ]; then
        republican_year=$((republican_year - 1))
        # Previous year's equinox
        prev_year_equinox=$(equinox_day $((year - 1)))
        prev_equinox_doy=$(date -u -d "$((year - 1))-09-$prev_year_equinox" +%j)
        days_in_prev_year=$(date -u -d "$((year - 1))-12-31" +%j)
        day_in_republican_year=$((day_of_year + days_in_prev_year - prev_equinox_doy))
    else
        day_in_republican_year=$((day_of_year - equinox_doy + 1))
    fi

    if [ $day_in_republican_year -le 360 ]; then
        republican_month=$(((day_in_republican_year - 1) / 30 + 1))
        republican_day=$(((day_in_republican_year - 1) % 30 + 1))
        month_names=("Vendémiaire" "Brumaire" "Frimaire" "Nivôse" "Pluviôse" "Ventôse" "Germinal" "Floréal" "Prairial" "Messidor" "Thermidor" "Fructidor")
        echo "$republican_day ${month_names[$((republican_month - 1))]}, An $republican_year"
    else
        # Sansculottides
        republican_day=$((day_in_republican_year - 360))
        sansculottides_names=("Fête de la Vertu" "Fête du Génie" "Fête du Travail" "Fête de l'Opinion" "Fête des Récompenses" "Fête de la Révolution")
        echo "${sansculottides_names[$((republican_day - 1))]}, An $republican_year"
    fi
}

get_republican_date
