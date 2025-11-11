#!/bin/bash

# Change this path to target folder
DOWNLOAD_DIR="$PWD/data/NDVI"

mkdir -p "$DOWNLOAD_DIR"

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (keingtobin): " username
    username=${username:-keingtobin}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2025209.h09v05.061.2025227005847/MOD13Q1.A2025209.h09v05.061.2025227005847.hdf"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2025209.h09v05.061.2025227005847/MOD13Q1.A2025209.h09v05.061.2025227005847.hdf -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2025209.h09v05.061.2025227005847/MOD13Q1.A2025209.h09v05.061.2025227005847.hdf | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"
        output_path="$DOWNLOAD_DIR/$stripped_query_params"
        if [ -f "$output_path" ]; then
            echo "Skipping existing file: $output_path"
            continue
        fi
        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $output_path -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $output_path --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2025209.h09v05.061.2025227005847/MOD13Q1.A2025209.h09v05.061.2025227005847.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2025193.h09v05.061.2025212122804/MOD13Q1.A2025193.h09v05.061.2025212122804.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2025177.h09v05.061.2025195134522/MOD13Q1.A2025177.h09v05.061.2025195134522.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2024209.h09v05.061.2024228023346/MOD13Q1.A2024209.h09v05.061.2024228023346.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2024193.h09v05.061.2024212093418/MOD13Q1.A2024193.h09v05.061.2024212093418.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2024177.h09v05.061.2024195021436/MOD13Q1.A2024177.h09v05.061.2024195021436.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2023209.h09v05.061.2023226001302/MOD13Q1.A2023209.h09v05.061.2023226001302.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2023193.h09v05.061.2023215110047/MOD13Q1.A2023193.h09v05.061.2023215110047.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2023177.h09v05.061.2023201060701/MOD13Q1.A2023177.h09v05.061.2023201060701.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2022209.h09v05.061.2022232150320/MOD13Q1.A2022209.h09v05.061.2022232150320.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2022193.h09v05.061.2022215010907/MOD13Q1.A2022193.h09v05.061.2022215010907.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2022177.h09v05.061.2022195121329/MOD13Q1.A2022177.h09v05.061.2022195121329.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2021209.h09v05.061.2021226040542/BROWSE.MOD13Q1.A2021209.h09v05.061.2021226040542.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2021209.h09v05.061.2021226040542/MOD13Q1.A2021209.h09v05.061.2021226040542.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2021209.h09v05.061.2021226040542/BROWSE.MOD13Q1.A2021209.h09v05.061.2021226040542.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2021209.h09v05.061.2021226040542/MOD13Q1.A2021209.h09v05.061.2021226040542.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2021193.h09v05.061.2021213234450/BROWSE.MOD13Q1.A2021193.h09v05.061.2021213234450.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2021193.h09v05.061.2021213234450/MOD13Q1.A2021193.h09v05.061.2021213234450.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2021193.h09v05.061.2021213234450/BROWSE.MOD13Q1.A2021193.h09v05.061.2021213234450.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2021193.h09v05.061.2021213234450/MOD13Q1.A2021193.h09v05.061.2021213234450.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2021177.h09v05.061.2021194011920/BROWSE.MOD13Q1.A2021177.h09v05.061.2021194011920.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2021177.h09v05.061.2021194011920/MOD13Q1.A2021177.h09v05.061.2021194011920.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2021177.h09v05.061.2021194011920/BROWSE.MOD13Q1.A2021177.h09v05.061.2021194011920.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2021177.h09v05.061.2021194011920/MOD13Q1.A2021177.h09v05.061.2021194011920.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2020209.h09v05.061.2020342003643/BROWSE.MOD13Q1.A2020209.h09v05.061.2020342003644.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2020209.h09v05.061.2020342003643/MOD13Q1.A2020209.h09v05.061.2020342003643.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2020209.h09v05.061.2020342003643/BROWSE.MOD13Q1.A2020209.h09v05.061.2020342003644.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2020209.h09v05.061.2020342003643/MOD13Q1.A2020209.h09v05.061.2020342003643.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2020193.h09v05.061.2020340125709/BROWSE.MOD13Q1.A2020193.h09v05.061.2020340125710.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2020193.h09v05.061.2020340125709/MOD13Q1.A2020193.h09v05.061.2020340125709.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2020193.h09v05.061.2020340125709/BROWSE.MOD13Q1.A2020193.h09v05.061.2020340125710.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2020193.h09v05.061.2020340125709/MOD13Q1.A2020193.h09v05.061.2020340125709.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2020177.h09v05.061.2020340101402/BROWSE.MOD13Q1.A2020177.h09v05.061.2020340101402.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2020177.h09v05.061.2020340101402/MOD13Q1.A2020177.h09v05.061.2020340101402.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2020177.h09v05.061.2020340101402/BROWSE.MOD13Q1.A2020177.h09v05.061.2020340101402.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2020177.h09v05.061.2020340101402/MOD13Q1.A2020177.h09v05.061.2020340101402.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2019209.h09v05.061.2020304165258/BROWSE.MOD13Q1.A2019209.h09v05.061.2020304165258.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2019209.h09v05.061.2020304165258/MOD13Q1.A2019209.h09v05.061.2020304165258.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2019209.h09v05.061.2020304165258/BROWSE.MOD13Q1.A2019209.h09v05.061.2020304165258.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2019209.h09v05.061.2020304165258/MOD13Q1.A2019209.h09v05.061.2020304165258.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2019193.h09v05.061.2020304011217/BROWSE.MOD13Q1.A2019193.h09v05.061.2020304011217.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2019193.h09v05.061.2020304011217/MOD13Q1.A2019193.h09v05.061.2020304011217.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2019193.h09v05.061.2020304011217/BROWSE.MOD13Q1.A2019193.h09v05.061.2020304011217.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2019193.h09v05.061.2020304011217/MOD13Q1.A2019193.h09v05.061.2020304011217.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2019177.h09v05.061.2020303060225/BROWSE.MOD13Q1.A2019177.h09v05.061.2020303060225.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2019177.h09v05.061.2020303060225/MOD13Q1.A2019177.h09v05.061.2020303060225.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2019177.h09v05.061.2020303060225/BROWSE.MOD13Q1.A2019177.h09v05.061.2020303060225.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2019177.h09v05.061.2020303060225/MOD13Q1.A2019177.h09v05.061.2020303060225.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2018209.h09v05.061.2021339232632/BROWSE.MOD13Q1.A2018209.h09v05.061.2021339232632.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2018209.h09v05.061.2021339232632/MOD13Q1.A2018209.h09v05.061.2021339232632.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2018209.h09v05.061.2021339232632/BROWSE.MOD13Q1.A2018209.h09v05.061.2021339232632.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2018209.h09v05.061.2021339232632/MOD13Q1.A2018209.h09v05.061.2021339232632.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2018193.h09v05.061.2021339232416/BROWSE.MOD13Q1.A2018193.h09v05.061.2021339232416.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2018193.h09v05.061.2021339232416/MOD13Q1.A2018193.h09v05.061.2021339232416.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2018193.h09v05.061.2021339232416/BROWSE.MOD13Q1.A2018193.h09v05.061.2021339232416.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2018193.h09v05.061.2021339232416/MOD13Q1.A2018193.h09v05.061.2021339232416.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2018177.h09v05.061.2021339232211/BROWSE.MOD13Q1.A2018177.h09v05.061.2021339232211.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2018177.h09v05.061.2021339232211/MOD13Q1.A2018177.h09v05.061.2021339232211.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2018177.h09v05.061.2021339232211/MOD13Q1.A2018177.h09v05.061.2021339232211.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2018177.h09v05.061.2021339232211/BROWSE.MOD13Q1.A2018177.h09v05.061.2021339232211.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2017209.h09v05.061.2021279220850/BROWSE.MOD13Q1.A2017209.h09v05.061.2021279220850.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2017209.h09v05.061.2021279220850/MOD13Q1.A2017209.h09v05.061.2021279220850.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2017209.h09v05.061.2021279220850/BROWSE.MOD13Q1.A2017209.h09v05.061.2021279220850.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2017209.h09v05.061.2021279220850/MOD13Q1.A2017209.h09v05.061.2021279220850.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2017193.h09v05.061.2021278044800/BROWSE.MOD13Q1.A2017193.h09v05.061.2021278044800.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2017193.h09v05.061.2021278044800/MOD13Q1.A2017193.h09v05.061.2021278044800.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2017193.h09v05.061.2021278044800/BROWSE.MOD13Q1.A2017193.h09v05.061.2021278044800.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2017193.h09v05.061.2021278044800/MOD13Q1.A2017193.h09v05.061.2021278044800.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2017177.h09v05.061.2021277061124/BROWSE.MOD13Q1.A2017177.h09v05.061.2021277061124.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2017177.h09v05.061.2021277061124/MOD13Q1.A2017177.h09v05.061.2021277061124.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2017177.h09v05.061.2021277061124/BROWSE.MOD13Q1.A2017177.h09v05.061.2021277061124.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2017177.h09v05.061.2021277061124/MOD13Q1.A2017177.h09v05.061.2021277061124.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2016209.h09v05.061.2021356181728/BROWSE.MOD13Q1.A2016209.h09v05.061.2021356181728.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2016209.h09v05.061.2021356181728/MOD13Q1.A2016209.h09v05.061.2021356181728.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2016209.h09v05.061.2021356181728/BROWSE.MOD13Q1.A2016209.h09v05.061.2021356181728.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2016209.h09v05.061.2021356181728/MOD13Q1.A2016209.h09v05.061.2021356181728.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2016193.h09v05.061.2021354120919/BROWSE.MOD13Q1.A2016193.h09v05.061.2021354120919.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2016193.h09v05.061.2021354120919/MOD13Q1.A2016193.h09v05.061.2021354120919.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2016193.h09v05.061.2021354120919/BROWSE.MOD13Q1.A2016193.h09v05.061.2021354120919.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2016193.h09v05.061.2021354120919/MOD13Q1.A2016193.h09v05.061.2021354120919.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2016177.h09v05.061.2021353092632/BROWSE.MOD13Q1.A2016177.h09v05.061.2021353092632.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2016177.h09v05.061.2021353092632/MOD13Q1.A2016177.h09v05.061.2021353092632.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2016177.h09v05.061.2021353092632/BROWSE.MOD13Q1.A2016177.h09v05.061.2021353092632.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2016177.h09v05.061.2021353092632/MOD13Q1.A2016177.h09v05.061.2021353092632.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2015209.h09v05.061.2021329231153/BROWSE.MOD13Q1.A2015209.h09v05.061.2021329231153.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2015209.h09v05.061.2021329231153/MOD13Q1.A2015209.h09v05.061.2021329231153.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2015209.h09v05.061.2021329231153/BROWSE.MOD13Q1.A2015209.h09v05.061.2021329231153.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2015209.h09v05.061.2021329231153/MOD13Q1.A2015209.h09v05.061.2021329231153.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2015193.h09v05.061.2021329024349/BROWSE.MOD13Q1.A2015193.h09v05.061.2021329024350.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2015193.h09v05.061.2021329024349/MOD13Q1.A2015193.h09v05.061.2021329024349.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2015193.h09v05.061.2021329024349/BROWSE.MOD13Q1.A2015193.h09v05.061.2021329024350.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2015193.h09v05.061.2021329024349/MOD13Q1.A2015193.h09v05.061.2021329024349.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2015177.h09v05.061.2021327204349/BROWSE.MOD13Q1.A2015177.h09v05.061.2021327204349.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2015177.h09v05.061.2021327204349/MOD13Q1.A2015177.h09v05.061.2021327204349.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2015177.h09v05.061.2021327204349/BROWSE.MOD13Q1.A2015177.h09v05.061.2021327204349.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2015177.h09v05.061.2021327204349/MOD13Q1.A2015177.h09v05.061.2021327204349.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2014209.h09v05.061.2021260012025/BROWSE.MOD13Q1.A2014209.h09v05.061.2021260012026.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2014209.h09v05.061.2021260012025/MOD13Q1.A2014209.h09v05.061.2021260012025.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2014209.h09v05.061.2021260012025/BROWSE.MOD13Q1.A2014209.h09v05.061.2021260012026.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2014209.h09v05.061.2021260012025/MOD13Q1.A2014209.h09v05.061.2021260012025.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2014193.h09v05.061.2021259104358/BROWSE.MOD13Q1.A2014193.h09v05.061.2021259104359.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2014193.h09v05.061.2021259104358/MOD13Q1.A2014193.h09v05.061.2021259104358.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2014193.h09v05.061.2021259104358/BROWSE.MOD13Q1.A2014193.h09v05.061.2021259104359.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2014193.h09v05.061.2021259104358/MOD13Q1.A2014193.h09v05.061.2021259104358.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2014177.h09v05.061.2021258035012/BROWSE.MOD13Q1.A2014177.h09v05.061.2021258035013.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2014177.h09v05.061.2021258035012/MOD13Q1.A2014177.h09v05.061.2021258035012.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2014177.h09v05.061.2021258035012/BROWSE.MOD13Q1.A2014177.h09v05.061.2021258035013.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2014177.h09v05.061.2021258035012/MOD13Q1.A2014177.h09v05.061.2021258035012.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2013209.h09v05.061.2021235055333/BROWSE.MOD13Q1.A2013209.h09v05.061.2021235055334.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2013209.h09v05.061.2021235055333/MOD13Q1.A2013209.h09v05.061.2021235055333.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2013209.h09v05.061.2021235055333/BROWSE.MOD13Q1.A2013209.h09v05.061.2021235055334.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2013209.h09v05.061.2021235055333/MOD13Q1.A2013209.h09v05.061.2021235055333.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2013193.h09v05.061.2021234075302/BROWSE.MOD13Q1.A2013193.h09v05.061.2021234075302.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2013193.h09v05.061.2021234075302/MOD13Q1.A2013193.h09v05.061.2021234075302.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2013193.h09v05.061.2021234075302/BROWSE.MOD13Q1.A2013193.h09v05.061.2021234075302.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2013193.h09v05.061.2021234075302/MOD13Q1.A2013193.h09v05.061.2021234075302.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2013177.h09v05.061.2021233094941/BROWSE.MOD13Q1.A2013177.h09v05.061.2021233094941.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2013177.h09v05.061.2021233094941/MOD13Q1.A2013177.h09v05.061.2021233094941.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2013177.h09v05.061.2021233094941/BROWSE.MOD13Q1.A2013177.h09v05.061.2021233094941.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2013177.h09v05.061.2021233094941/MOD13Q1.A2013177.h09v05.061.2021233094941.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2012209.h09v05.061.2021213105736/BROWSE.MOD13Q1.A2012209.h09v05.061.2021213105736.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2012209.h09v05.061.2021213105736/MOD13Q1.A2012209.h09v05.061.2021213105736.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2012209.h09v05.061.2021213105736/BROWSE.MOD13Q1.A2012209.h09v05.061.2021213105736.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2012209.h09v05.061.2021213105736/MOD13Q1.A2012209.h09v05.061.2021213105736.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2012193.h09v05.061.2021212103403/BROWSE.MOD13Q1.A2012193.h09v05.061.2021212103404.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2012193.h09v05.061.2021212103403/MOD13Q1.A2012193.h09v05.061.2021212103403.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2012193.h09v05.061.2021212103403/BROWSE.MOD13Q1.A2012193.h09v05.061.2021212103404.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2012193.h09v05.061.2021212103403/MOD13Q1.A2012193.h09v05.061.2021212103403.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2012177.h09v05.061.2021211200342/BROWSE.MOD13Q1.A2012177.h09v05.061.2021211200342.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2012177.h09v05.061.2021211200342/MOD13Q1.A2012177.h09v05.061.2021211200342.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2012177.h09v05.061.2021211200342/MOD13Q1.A2012177.h09v05.061.2021211200342.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2012177.h09v05.061.2021211200342/BROWSE.MOD13Q1.A2012177.h09v05.061.2021211200342.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2011209.h09v05.061.2021195014149/BROWSE.MOD13Q1.A2011209.h09v05.061.2021195014150.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2011209.h09v05.061.2021195014149/MOD13Q1.A2011209.h09v05.061.2021195014149.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2011209.h09v05.061.2021195014149/BROWSE.MOD13Q1.A2011209.h09v05.061.2021195014150.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2011209.h09v05.061.2021195014149/MOD13Q1.A2011209.h09v05.061.2021195014149.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2011193.h09v05.061.2021193185839/BROWSE.MOD13Q1.A2011193.h09v05.061.2021193185839.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2011193.h09v05.061.2021193185839/BROWSE.MOD13Q1.A2011193.h09v05.061.2021193185839.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2011193.h09v05.061.2021193185839/MOD13Q1.A2011193.h09v05.061.2021193185839.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2011193.h09v05.061.2021193185839/MOD13Q1.A2011193.h09v05.061.2021193185839.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2011177.h09v05.061.2021193161752/BROWSE.MOD13Q1.A2011177.h09v05.061.2021193161752.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2011177.h09v05.061.2021193161752/MOD13Q1.A2011177.h09v05.061.2021193161752.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2011177.h09v05.061.2021193161752/BROWSE.MOD13Q1.A2011177.h09v05.061.2021193161752.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2011177.h09v05.061.2021193161752/MOD13Q1.A2011177.h09v05.061.2021193161752.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2010209.h09v05.061.2021168205433/BROWSE.MOD13Q1.A2010209.h09v05.061.2021168205433.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2010209.h09v05.061.2021168205433/MOD13Q1.A2010209.h09v05.061.2021168205433.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2010209.h09v05.061.2021168205433/BROWSE.MOD13Q1.A2010209.h09v05.061.2021168205433.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2010209.h09v05.061.2021168205433/MOD13Q1.A2010209.h09v05.061.2021168205433.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2010193.h09v05.061.2021168185612/BROWSE.MOD13Q1.A2010193.h09v05.061.2021168185612.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2010193.h09v05.061.2021168185612/BROWSE.MOD13Q1.A2010193.h09v05.061.2021168185612.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2010193.h09v05.061.2021168185612/MOD13Q1.A2010193.h09v05.061.2021168185612.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2010193.h09v05.061.2021168185612/MOD13Q1.A2010193.h09v05.061.2021168185612.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2010177.h09v05.061.2021168165413/BROWSE.MOD13Q1.A2010177.h09v05.061.2021168165413.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2010177.h09v05.061.2021168165413/MOD13Q1.A2010177.h09v05.061.2021168165413.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2010177.h09v05.061.2021168165413/BROWSE.MOD13Q1.A2010177.h09v05.061.2021168165413.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2010177.h09v05.061.2021168165413/MOD13Q1.A2010177.h09v05.061.2021168165413.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2009209.h09v05.061.2021139133922/BROWSE.MOD13Q1.A2009209.h09v05.061.2021139133923.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2009209.h09v05.061.2021139133922/MOD13Q1.A2009209.h09v05.061.2021139133922.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2009209.h09v05.061.2021139133922/BROWSE.MOD13Q1.A2009209.h09v05.061.2021139133923.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2009209.h09v05.061.2021139133922/MOD13Q1.A2009209.h09v05.061.2021139133922.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2009193.h09v05.061.2021138051046/BROWSE.MOD13Q1.A2009193.h09v05.061.2021138051047.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2009193.h09v05.061.2021138051046/MOD13Q1.A2009193.h09v05.061.2021138051046.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2009193.h09v05.061.2021138051046/BROWSE.MOD13Q1.A2009193.h09v05.061.2021138051047.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2009193.h09v05.061.2021138051046/MOD13Q1.A2009193.h09v05.061.2021138051046.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2009177.h09v05.061.2021137201207/BROWSE.MOD13Q1.A2009177.h09v05.061.2021137201207.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2009177.h09v05.061.2021137201207/MOD13Q1.A2009177.h09v05.061.2021137201207.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2009177.h09v05.061.2021137201207/BROWSE.MOD13Q1.A2009177.h09v05.061.2021137201207.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2009177.h09v05.061.2021137201207/MOD13Q1.A2009177.h09v05.061.2021137201207.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2008209.h09v05.061.2021104100825/MOD13Q1.A2008209.h09v05.061.2021104100825.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2008193.h09v05.061.2021102125734/BROWSE.MOD13Q1.A2008193.h09v05.061.2021102125734.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2008193.h09v05.061.2021102125734/MOD13Q1.A2008193.h09v05.061.2021102125734.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2008193.h09v05.061.2021102125734/BROWSE.MOD13Q1.A2008193.h09v05.061.2021102125734.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2008193.h09v05.061.2021102125734/MOD13Q1.A2008193.h09v05.061.2021102125734.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2008177.h09v05.061.2021100023054/BROWSE.MOD13Q1.A2008177.h09v05.061.2021100023054.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2008177.h09v05.061.2021100023054/MOD13Q1.A2008177.h09v05.061.2021100023054.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2008177.h09v05.061.2021100023054/BROWSE.MOD13Q1.A2008177.h09v05.061.2021100023054.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2008177.h09v05.061.2021100023054/MOD13Q1.A2008177.h09v05.061.2021100023054.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2007209.h09v05.061.2021071042807/BROWSE.MOD13Q1.A2007209.h09v05.061.2021071042808.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2007209.h09v05.061.2021071042807/MOD13Q1.A2007209.h09v05.061.2021071042807.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2007209.h09v05.061.2021071042807/BROWSE.MOD13Q1.A2007209.h09v05.061.2021071042808.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2007209.h09v05.061.2021071042807/MOD13Q1.A2007209.h09v05.061.2021071042807.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2007193.h09v05.061.2021068160231/BROWSE.MOD13Q1.A2007193.h09v05.061.2021068160232.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2007193.h09v05.061.2021068160231/MOD13Q1.A2007193.h09v05.061.2021068160231.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2007193.h09v05.061.2021068160231/BROWSE.MOD13Q1.A2007193.h09v05.061.2021068160232.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2007193.h09v05.061.2021068160231/MOD13Q1.A2007193.h09v05.061.2021068160231.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2007177.h09v05.061.2021068095459/BROWSE.MOD13Q1.A2007177.h09v05.061.2021068095459.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2007177.h09v05.061.2021068095459/MOD13Q1.A2007177.h09v05.061.2021068095459.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2007177.h09v05.061.2021068095459/BROWSE.MOD13Q1.A2007177.h09v05.061.2021068095459.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2007177.h09v05.061.2021068095459/MOD13Q1.A2007177.h09v05.061.2021068095459.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2006209.h09v05.061.2020269041742/BROWSE.MOD13Q1.A2006209.h09v05.061.2020269041742.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2006209.h09v05.061.2020269041742/BROWSE.MOD13Q1.A2006209.h09v05.061.2020269041742.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2006209.h09v05.061.2020269041742/MOD13Q1.A2006209.h09v05.061.2020269041742.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2006209.h09v05.061.2020269041742/MOD13Q1.A2006209.h09v05.061.2020269041742.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2006193.h09v05.061.2020267122642/BROWSE.MOD13Q1.A2006193.h09v05.061.2020267122642.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2006193.h09v05.061.2020267122642/MOD13Q1.A2006193.h09v05.061.2020267122642.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2006193.h09v05.061.2020267122642/BROWSE.MOD13Q1.A2006193.h09v05.061.2020267122642.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2006193.h09v05.061.2020267122642/MOD13Q1.A2006193.h09v05.061.2020267122642.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2006177.h09v05.061.2020266020603/BROWSE.MOD13Q1.A2006177.h09v05.061.2020266020603.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2006177.h09v05.061.2020266020603/MOD13Q1.A2006177.h09v05.061.2020266020603.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2006177.h09v05.061.2020266020603/BROWSE.MOD13Q1.A2006177.h09v05.061.2020266020603.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2006177.h09v05.061.2020266020603/MOD13Q1.A2006177.h09v05.061.2020266020603.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2005209.h09v05.061.2020241214051/BROWSE.MOD13Q1.A2005209.h09v05.061.2020241214051.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2005209.h09v05.061.2020241214051/MOD13Q1.A2005209.h09v05.061.2020241214051.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2005209.h09v05.061.2020241214051/BROWSE.MOD13Q1.A2005209.h09v05.061.2020241214051.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2005209.h09v05.061.2020241214051/MOD13Q1.A2005209.h09v05.061.2020241214051.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2005193.h09v05.061.2020241062509/BROWSE.MOD13Q1.A2005193.h09v05.061.2020241062510.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2005193.h09v05.061.2020241062509/MOD13Q1.A2005193.h09v05.061.2020241062509.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2005193.h09v05.061.2020241062509/BROWSE.MOD13Q1.A2005193.h09v05.061.2020241062510.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2005193.h09v05.061.2020241062509/MOD13Q1.A2005193.h09v05.061.2020241062509.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2005177.h09v05.061.2020237080859/BROWSE.MOD13Q1.A2005177.h09v05.061.2020237080900.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2005177.h09v05.061.2020237080859/MOD13Q1.A2005177.h09v05.061.2020237080859.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2005177.h09v05.061.2020237080859/BROWSE.MOD13Q1.A2005177.h09v05.061.2020237080900.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2005177.h09v05.061.2020237080859/MOD13Q1.A2005177.h09v05.061.2020237080859.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2004209.h09v05.061.2020196085319/MOD13Q1.A2004209.h09v05.061.2020196085319.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2004193.h09v05.061.2020196084123/BROWSE.MOD13Q1.A2004193.h09v05.061.2020196084123.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2004193.h09v05.061.2020196084123/MOD13Q1.A2004193.h09v05.061.2020196084123.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2004193.h09v05.061.2020196084123/BROWSE.MOD13Q1.A2004193.h09v05.061.2020196084123.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2004193.h09v05.061.2020196084123/MOD13Q1.A2004193.h09v05.061.2020196084123.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2004177.h09v05.061.2020196083323/BROWSE.MOD13Q1.A2004177.h09v05.061.2020196083324.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2004177.h09v05.061.2020196083323/MOD13Q1.A2004177.h09v05.061.2020196083323.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2004177.h09v05.061.2020196083323/BROWSE.MOD13Q1.A2004177.h09v05.061.2020196083324.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2004177.h09v05.061.2020196083323/MOD13Q1.A2004177.h09v05.061.2020196083323.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2003209.h09v05.061.2020106060713/BROWSE.MOD13Q1.A2003209.h09v05.061.2020106060713.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2003209.h09v05.061.2020106060713/MOD13Q1.A2003209.h09v05.061.2020106060713.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2003209.h09v05.061.2020106060713/BROWSE.MOD13Q1.A2003209.h09v05.061.2020106060713.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2003209.h09v05.061.2020106060713/MOD13Q1.A2003209.h09v05.061.2020106060713.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2003193.h09v05.061.2020097180020/BROWSE.MOD13Q1.A2003193.h09v05.061.2020097180020.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2003193.h09v05.061.2020097180020/MOD13Q1.A2003193.h09v05.061.2020097180020.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2003193.h09v05.061.2020097180020/BROWSE.MOD13Q1.A2003193.h09v05.061.2020097180020.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2003193.h09v05.061.2020097180020/MOD13Q1.A2003193.h09v05.061.2020097180020.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2003177.h09v05.061.2020096223113/BROWSE.MOD13Q1.A2003177.h09v05.061.2020096223113.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2003177.h09v05.061.2020096223113/MOD13Q1.A2003177.h09v05.061.2020096223113.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2003177.h09v05.061.2020096223113/BROWSE.MOD13Q1.A2003177.h09v05.061.2020096223113.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2003177.h09v05.061.2020096223113/MOD13Q1.A2003177.h09v05.061.2020096223113.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2002209.h09v05.061.2020077124500/BROWSE.MOD13Q1.A2002209.h09v05.061.2020077124500.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2002209.h09v05.061.2020077124500/MOD13Q1.A2002209.h09v05.061.2020077124500.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2002209.h09v05.061.2020077124500/BROWSE.MOD13Q1.A2002209.h09v05.061.2020077124500.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2002209.h09v05.061.2020077124500/MOD13Q1.A2002209.h09v05.061.2020077124500.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2002193.h09v05.061.2020077115357/BROWSE.MOD13Q1.A2002193.h09v05.061.2020077115357.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2002193.h09v05.061.2020077115357/MOD13Q1.A2002193.h09v05.061.2020077115357.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2002193.h09v05.061.2020077115357/BROWSE.MOD13Q1.A2002193.h09v05.061.2020077115357.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2002193.h09v05.061.2020077115357/MOD13Q1.A2002193.h09v05.061.2020077115357.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2002177.h09v05.061.2020072144253/BROWSE.MOD13Q1.A2002177.h09v05.061.2020072144253.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2002177.h09v05.061.2020072144253/MOD13Q1.A2002177.h09v05.061.2020072144253.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2002177.h09v05.061.2020072144253/BROWSE.MOD13Q1.A2002177.h09v05.061.2020072144253.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2002177.h09v05.061.2020072144253/MOD13Q1.A2002177.h09v05.061.2020072144253.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2001209.h09v05.061.2020064123714/BROWSE.MOD13Q1.A2001209.h09v05.061.2020064123714.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2001209.h09v05.061.2020064123714/MOD13Q1.A2001209.h09v05.061.2020064123714.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD13Q1.061/MOD13Q1.A2001209.h09v05.061.2020064123714/BROWSE.MOD13Q1.A2001209.h09v05.061.2020064123714.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2001209.h09v05.061.2020064123714/MOD13Q1.A2001209.h09v05.061.2020064123714.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2001193.h09v05.061.2020062163244/MOD13Q1.A2001193.h09v05.061.2020062163244.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD13Q1.061/MOD13Q1.A2001177.h09v05.061.2020062110743/MOD13Q1.A2001177.h09v05.061.2020062110743.hdf
EDSCEOF