#!/bin/sh
SCRIPT_DIR="$(cd -- "$(dirname "$0")"; pwd -P)"

DRUSH8="$SCRIPT_DIR/../../etc/drush/drush8/vendor/bin/drush"
DRUSH10="$SCRIPT_DIR/../../etc/drush/drush10/vendor/bin/drush"
DOCROOT="$SCRIPT_DIR/../../docroot"

cd $DOCROOT

# Enable maintenance mode
${DRUSH10} sset system.maintenance_mode 1 --input-format=integer

# D8

# Update site
${DRUSH10} updb -y

# Enable maintenance mode again, as updb always set it to false after running
# if it ran an update
${DRUSH10} sset system.maintenance_mode 1 --input-format=integer

# Clear caches
${DRUSH10} cr

# Import configuration overrides if there is any config yet.
CONFIG_DIR=$(${DRUSH10} st --field=config-sync)
if [ -d $CONFIG_DIR ] && [ 0 -lt $(ls ${CONFIG_DIR}/*.yml 2>/dev/null | wc -w) ]; then
  # Ensure the ignored config is up to date.
  ${DRUSH10} rocketship:single-import ../config/sync/config_ignore.settings.yml
  # Ensure CMI knows about the split.
  ${DRUSH10} rocketship:single-import ../config/sync/config_split.config_split.live.yml
  ${DRUSH10} cr
  # Single cim should work without issues
  ${DRUSH10} cim -y
else
  echo "Skipping config import, as no config exists yet."
fi

# Clear caches
${DRUSH10} cr

# Run cron (Enable when your project needs it on build).
# ${DRUSH10} cron

# Clear Varnish cache last. Be aware of the huge performance consequences of
# clearing drupal's internal caches *and* all external caches at the same time!
# Requests will cause full Drupal bootstraps and rebuilds with no internal
# cache to soften the blow.
# ${DRUSH10} cre -y

# Turn maintenance mode off
${DRUSH10} sset system.maintenance_mode 0 --input-format=integer