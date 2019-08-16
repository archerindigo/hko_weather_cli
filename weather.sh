#!/bin/sh
set -u

URL_CUR_WEATHER_RPT=https://data.weather.gov.hk/weatherAPI/opendata/weather.php

gen_current_weather_report()
{
    local data_type="dataType=rhrread"
    local url="$URL_CUR_WEATHER_RPT?$data_type"
    local report=$(curl -s -X GET "$url")

    if [ -z "$report" ]; then
        echo "Failed to connect to server"
        return 1
    fi

    # Collect the data
    local updatedTime=$(echo "$report" | jq -r '.updateTime')
    local cur_temp=$(echo "$report" | jq -r '.temperature.data[1].value')
    local temp_unit=$(echo "$report" | jq -r '.temperature.data[1].unit')
    local humidity=$(echo "$report" | jq -r '.humidity.data[0].value')
    local warnings=$(echo "$report" | jq -r '.warningMessage[]' 2>/dev/null)
    local special_wx_tips=$(echo "$report" | jq -r '.specialWxTips[]' 2>/dev/null)

    # Print the report
    echo -e "\033[1;37mLatest weather report ($updatedTime):\033[0m"
    echo "Temperature: $cur_temp $temp_unit"
    echo "Humidity: $humidity%"

    if [ -n "$warnings" ]; then
        echo ""
        echo -e "\033[1;31mWarning!\033[0m"
        echo -e "\033[1;33m$warnings\033[0m"
    fi

    if [ -n "$special_wx_tips" ]; then
        echo ""
        echo -e "\033[1;31mSpecial weather tips:\033[0m"
        echo -e "\033[1;33m$special_wx_tips\033[0m"
    fi
}

gen_district_report()
{
    local data_type="dataType=rhrread"
    local url="$URL_CUR_WEATHER_RPT?$data_type"
    local report=$(curl -s -X GET "$url")
    local choice_district=

    echo ""
    echo "Regional Weather Report"
    echo "========================================"


    if [ -z "$report" ]; then
        echo "Failed to connect to server"
        echo "========================================"
        return 1
    fi

    list_districts=$(echo "$report" | jq -r '.temperature.data[].place')

    # Put into array
    IFS=$'\n'
    local array_districts=($list_districts)
    IFS=

    for ((i=0; i<${#array_districts[@]}; i++)); do
        echo "$(($i+1))) ${array_districts[$i]}"
    done

    echo "========================================"
    echo -n "Please choose the district: "

    read choice_district
    choice_district=$(( $choice_district - 1 ))

    local district_name=$(echo "$report" | jq -r ".temperature.data["$choice_district"].place")
    local cur_temp=$(echo "$report" | jq -r ".temperature.data["$choice_district"].value")
    local temp_unit=$(echo "$report" | jq -r ".temperature.data["$choice_district"].unit")
    echo ""
    echo -e "Weather of \033[1;37m$district_name\033[0m:"
    echo "Temperature: $cur_temp $temp_unit"
}

#### Main ####
# Check tools
if [ -z $(which curl) ]; then
    echo "curl is required to run this program!"
    exit 1
fi

if [ -z $(which jq) ]; then
    echo "jq is required to run this program!"
    exit 1
fi

gen_current_weather_report

## Main menu
while true; do
    echo ""
    echo "Main menu"
    echo "========================================"
    echo "1) Regional weather report"
    echo "q) Quit the program"
    echo "========================================"
    echo -n "Select a service: "
    read option

    case "$option" in
        1)
            gen_district_report
            ;;
        q)
            echo "Bye!"
            exit 0
            ;;
        *)
            echo "Invalid option!"
            ;;
    esac
done

