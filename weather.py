import requests

# Base URL for current weather endpoint
base_current_url = "http://api.weatherapi.com/v1/current.json"
base_alerts_url = "http://api.weatherapi.com/v1/alerts.json"

#  Query parameter based on which data is sent back. It could be following:
#     Latitude and Longitude (Decimal degree) e.g: q=48.8567,2.3508
#     city name e.g.: q=Paris
#     US zip e.g.: q=10001
#     UK postcode e.g: q=SW1
#     Canada postal code e.g: q=G2J
#     metar:<metar code> e.g: q=metar:EGLL
#     iata:<3 digit airport code> e.g: q=iata:DXB
#     auto:ip IP lookup e.g: q=auto:ip
#     IP address (IPv4 and IPv6 supported) e.g: q=100.0.0.1
#     By ID returned from Search API. e.g: q=id:2801268
#     bulk
def get_weather(location):
    params = {
        "key": "7f84c16adc1847168ef230955240710",
        "q": location,
        "aqi": "yes"  # Include Air Quality Index data
    }

    response = requests.get(base_current_url, params=params)


    if response.status_code == 200:
        # Parse the JSON response
        weather_data = response.json()
        print(f"JSON: {weather_data}")
        
        # Print weather information (modify to access specific data)
        print(f"Location: {weather_data['location']['name']}")
        print(f"Temperature: {weather_data['current']['temp_c']}°C")
        print(f"Condition: {weather_data['current']['condition']['text']}")
        # Access Air Quality Index data (if requested)
        if "air_quality" in weather_data:
            print(f"Air Quality Index: {weather_data['air_quality']['index']}")

    else:
        print(f"Error: {response.status_code}")
        print(response.text) 

    return response

def get_alerts(location):
    params = {
        "key": "7f84c16adc1847168ef230955240710",
        "q": location,
    }

    response = requests.get(base_alerts_url, params=params)


    if response.status_code == 200:
        # Parse the JSON response
        weather_data = response.json()
        print(f"JSON: {weather_data}")
        
        # Print weather information (modify to access specific data)
        print(f"Location: {weather_data['location']['name']}")

        for alert in weather_data['alerts']['alert']:
            print(f"Alert: ", alert)


    else:
        print(f"Error: {response.status_code}")
        print(response.text) 

    return response

get_weather('Salt lake city')

get_alerts('21.8,-90.8W')