#!/bin/bash

# Change thsi path to target folder 
DOWNLOAD_DIR="$PWD/data/Temperature"

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
    echo "https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001212.h09v05.061.2020097015249/MOD11A1.A2001212.h09v05.061.2020097015249.cmr.xml"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001212.h09v05.061.2020097015249/MOD11A1.A2001212.h09v05.061.2020097015249.cmr.xml -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001212.h09v05.061.2020097015249/MOD11A1.A2001212.h09v05.061.2020097015249.cmr.xml | tail -1)
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
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001212.h09v05.061.2020097015249/MOD11A1.A2001212.h09v05.061.2020097015249.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001212.h09v05.061.2020097015249/BROWSE.MOD11A1.A2001212.h09v05.061.2020097015257.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001212.h09v05.061.2020097015249/BROWSE.MOD11A1.A2001212.h09v05.061.2020097015257.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001212.h09v05.061.2020097015249/MOD11A1.A2001212.h09v05.061.2020097015249.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001211.h09v05.061.2020097003600/BROWSE.MOD11A1.A2001211.h09v05.061.2020097003605.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001211.h09v05.061.2020097003600/MOD11A1.A2001211.h09v05.061.2020097003600.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001211.h09v05.061.2020097003600/BROWSE.MOD11A1.A2001211.h09v05.061.2020097003605.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001211.h09v05.061.2020097003600/MOD11A1.A2001211.h09v05.061.2020097003600.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001210.h09v05.061.2020096190656/BROWSE.MOD11A1.A2001210.h09v05.061.2020096190700.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001210.h09v05.061.2020096190656/MOD11A1.A2001210.h09v05.061.2020096190656.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001210.h09v05.061.2020096190656/BROWSE.MOD11A1.A2001210.h09v05.061.2020096190700.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001210.h09v05.061.2020096190656/MOD11A1.A2001210.h09v05.061.2020096190656.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001209.h09v05.061.2020096183022/MOD11A1.A2001209.h09v05.061.2020096183022.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001208.h09v05.061.2020096151340/BROWSE.MOD11A1.A2001208.h09v05.061.2020096151347.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001208.h09v05.061.2020096151340/MOD11A1.A2001208.h09v05.061.2020096151340.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001208.h09v05.061.2020096151340/MOD11A1.A2001208.h09v05.061.2020096151340.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001208.h09v05.061.2020096151340/BROWSE.MOD11A1.A2001208.h09v05.061.2020096151347.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001207.h09v05.061.2020096100851/BROWSE.MOD11A1.A2001207.h09v05.061.2020096100854.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001207.h09v05.061.2020096100851/BROWSE.MOD11A1.A2001207.h09v05.061.2020096100854.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001207.h09v05.061.2020096100851/MOD11A1.A2001207.h09v05.061.2020096100851.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001207.h09v05.061.2020096100851/MOD11A1.A2001207.h09v05.061.2020096100851.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001206.h09v05.061.2020096022314/BROWSE.MOD11A1.A2001206.h09v05.061.2020096022317.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001206.h09v05.061.2020096022314/BROWSE.MOD11A1.A2001206.h09v05.061.2020096022317.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001206.h09v05.061.2020096022314/MOD11A1.A2001206.h09v05.061.2020096022314.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001206.h09v05.061.2020096022314/MOD11A1.A2001206.h09v05.061.2020096022314.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001205.h09v05.061.2020095223414/BROWSE.MOD11A1.A2001205.h09v05.061.2020095223417.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001205.h09v05.061.2020095223414/BROWSE.MOD11A1.A2001205.h09v05.061.2020095223417.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001205.h09v05.061.2020095223414/MOD11A1.A2001205.h09v05.061.2020095223414.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001205.h09v05.061.2020095223414/MOD11A1.A2001205.h09v05.061.2020095223414.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001204.h09v05.061.2020095205232/BROWSE.MOD11A1.A2001204.h09v05.061.2020095205238.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001204.h09v05.061.2020095205232/MOD11A1.A2001204.h09v05.061.2020095205232.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001204.h09v05.061.2020095205232/BROWSE.MOD11A1.A2001204.h09v05.061.2020095205238.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001204.h09v05.061.2020095205232/MOD11A1.A2001204.h09v05.061.2020095205232.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001203.h09v05.061.2020095193116/BROWSE.MOD11A1.A2001203.h09v05.061.2020095193122.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001203.h09v05.061.2020095193116/MOD11A1.A2001203.h09v05.061.2020095193116.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001203.h09v05.061.2020095193116/BROWSE.MOD11A1.A2001203.h09v05.061.2020095193122.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001203.h09v05.061.2020095193116/MOD11A1.A2001203.h09v05.061.2020095193116.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001202.h09v05.061.2020095174629/MOD11A1.A2001202.h09v05.061.2020095174629.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001202.h09v05.061.2020095174629/BROWSE.MOD11A1.A2001202.h09v05.061.2020095174630.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001202.h09v05.061.2020095174629/BROWSE.MOD11A1.A2001202.h09v05.061.2020095174630.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001202.h09v05.061.2020095174629/MOD11A1.A2001202.h09v05.061.2020095174629.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001201.h09v05.061.2020095152823/BROWSE.MOD11A1.A2001201.h09v05.061.2020095152825.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001201.h09v05.061.2020095152823/BROWSE.MOD11A1.A2001201.h09v05.061.2020095152825.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001201.h09v05.061.2020095152823/MOD11A1.A2001201.h09v05.061.2020095152823.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001201.h09v05.061.2020095152823/MOD11A1.A2001201.h09v05.061.2020095152823.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001200.h09v05.061.2020095133759/BROWSE.MOD11A1.A2001200.h09v05.061.2020095133801.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001200.h09v05.061.2020095133759/BROWSE.MOD11A1.A2001200.h09v05.061.2020095133801.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001200.h09v05.061.2020095133759/MOD11A1.A2001200.h09v05.061.2020095133759.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001200.h09v05.061.2020095133759/MOD11A1.A2001200.h09v05.061.2020095133759.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001199.h09v05.061.2020095131333/BROWSE.MOD11A1.A2001199.h09v05.061.2020095131337.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001199.h09v05.061.2020095131333/BROWSE.MOD11A1.A2001199.h09v05.061.2020095131337.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001199.h09v05.061.2020095131333/MOD11A1.A2001199.h09v05.061.2020095131333.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001199.h09v05.061.2020095131333/MOD11A1.A2001199.h09v05.061.2020095131333.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001198.h09v05.061.2020095104636/MOD11A1.A2001198.h09v05.061.2020095104636.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001198.h09v05.061.2020095104636/BROWSE.MOD11A1.A2001198.h09v05.061.2020095104637.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001198.h09v05.061.2020095104636/BROWSE.MOD11A1.A2001198.h09v05.061.2020095104637.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001198.h09v05.061.2020095104636/MOD11A1.A2001198.h09v05.061.2020095104636.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001197.h09v05.061.2020095102629/MOD11A1.A2001197.h09v05.061.2020095102629.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001197.h09v05.061.2020095102629/BROWSE.MOD11A1.A2001197.h09v05.061.2020095102631.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001197.h09v05.061.2020095102629/BROWSE.MOD11A1.A2001197.h09v05.061.2020095102631.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001197.h09v05.061.2020095102629/MOD11A1.A2001197.h09v05.061.2020095102629.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001196.h09v05.061.2020095081935/BROWSE.MOD11A1.A2001196.h09v05.061.2020095081938.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001196.h09v05.061.2020095081935/BROWSE.MOD11A1.A2001196.h09v05.061.2020095081938.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001196.h09v05.061.2020095081935/MOD11A1.A2001196.h09v05.061.2020095081935.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001196.h09v05.061.2020095081935/MOD11A1.A2001196.h09v05.061.2020095081935.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001195.h09v05.061.2020095065014/BROWSE.MOD11A1.A2001195.h09v05.061.2020095065016.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001195.h09v05.061.2020095065014/BROWSE.MOD11A1.A2001195.h09v05.061.2020095065016.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001195.h09v05.061.2020095065014/MOD11A1.A2001195.h09v05.061.2020095065014.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001195.h09v05.061.2020095065014/MOD11A1.A2001195.h09v05.061.2020095065014.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001194.h09v05.061.2020095060527/BROWSE.MOD11A1.A2001194.h09v05.061.2020095060529.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001194.h09v05.061.2020095060527/BROWSE.MOD11A1.A2001194.h09v05.061.2020095060529.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001194.h09v05.061.2020095060527/MOD11A1.A2001194.h09v05.061.2020095060527.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001194.h09v05.061.2020095060527/MOD11A1.A2001194.h09v05.061.2020095060527.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001193.h09v05.061.2020095043757/BROWSE.MOD11A1.A2001193.h09v05.061.2020095043800.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001193.h09v05.061.2020095043757/BROWSE.MOD11A1.A2001193.h09v05.061.2020095043800.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001193.h09v05.061.2020095043757/MOD11A1.A2001193.h09v05.061.2020095043757.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001193.h09v05.061.2020095043757/MOD11A1.A2001193.h09v05.061.2020095043757.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001192.h09v05.061.2020095031318/MOD11A1.A2001192.h09v05.061.2020095031318.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001192.h09v05.061.2020095031318/BROWSE.MOD11A1.A2001192.h09v05.061.2020095031321.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001192.h09v05.061.2020095031318/BROWSE.MOD11A1.A2001192.h09v05.061.2020095031321.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001192.h09v05.061.2020095031318/MOD11A1.A2001192.h09v05.061.2020095031318.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001191.h09v05.061.2020095020651/MOD11A1.A2001191.h09v05.061.2020095020651.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001190.h09v05.061.2020095001703/MOD11A1.A2001190.h09v05.061.2020095001703.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001189.h09v05.061.2020094224951/BROWSE.MOD11A1.A2001189.h09v05.061.2020094224953.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001189.h09v05.061.2020094224951/BROWSE.MOD11A1.A2001189.h09v05.061.2020094224953.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001189.h09v05.061.2020094224951/MOD11A1.A2001189.h09v05.061.2020094224951.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001189.h09v05.061.2020094224951/MOD11A1.A2001189.h09v05.061.2020094224951.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001188.h09v05.061.2020094211324/BROWSE.MOD11A1.A2001188.h09v05.061.2020094211326.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001188.h09v05.061.2020094211324/MOD11A1.A2001188.h09v05.061.2020094211324.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001188.h09v05.061.2020094211324/BROWSE.MOD11A1.A2001188.h09v05.061.2020094211326.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001188.h09v05.061.2020094211324/MOD11A1.A2001188.h09v05.061.2020094211324.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001187.h09v05.061.2020094191843/BROWSE.MOD11A1.A2001187.h09v05.061.2020094191845.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001187.h09v05.061.2020094191843/BROWSE.MOD11A1.A2001187.h09v05.061.2020094191845.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001187.h09v05.061.2020094191843/MOD11A1.A2001187.h09v05.061.2020094191843.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001187.h09v05.061.2020094191843/MOD11A1.A2001187.h09v05.061.2020094191843.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001186.h09v05.061.2020094181746/BROWSE.MOD11A1.A2001186.h09v05.061.2020094181749.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001186.h09v05.061.2020094181746/BROWSE.MOD11A1.A2001186.h09v05.061.2020094181749.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001186.h09v05.061.2020094181746/MOD11A1.A2001186.h09v05.061.2020094181746.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001186.h09v05.061.2020094181746/MOD11A1.A2001186.h09v05.061.2020094181746.cmr.xml
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001185.h09v05.061.2020094163228/MOD11A1.A2001185.h09v05.061.2020094163228.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001184.h09v05.061.2020094152837/BROWSE.MOD11A1.A2001184.h09v05.061.2020094152840.1.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-public/MOD11A1.061/MOD11A1.A2001184.h09v05.061.2020094152837/BROWSE.MOD11A1.A2001184.h09v05.061.2020094152840.2.jpg
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001184.h09v05.061.2020094152837/MOD11A1.A2001184.h09v05.061.2020094152837.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MOD11A1.061/MOD11A1.A2001184.h09v05.061.2020094152837/MOD11A1.A2001184.h09v05.061.2020094152837.cmr.xml
EDSCEOF