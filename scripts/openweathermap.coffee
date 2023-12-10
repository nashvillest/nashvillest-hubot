#
# Open Weather Map
#
# Commands:
#   hubot weather - Get weather for default location.
#   hubot weather <location> - Get weather for given query.
#
# Configuration:
#   HUBOT_OPEN_WEATHER_MAP_API_KEY - API Key
#   HUBOT_DEFAULT_LATITUDE - Default latitude for Hubot interactions
#   HUBOT_DEFAULT_LONGITUDE - Default longitude for Hubot interactions

module.exports = (robot) ->
    baseUrl = 'https://api.openweathermap.org/data/2.5/weather'
    baseUrlNWS = 'https://api.weather.gov/'

    # Give default weather
    robot.respond /weather$/i, (msg) ->
        if !process.env.HUBOT_OPEN_WEATHER_MAP_API_KEY
            return msg.send 'No API Key configured.'

        if !process.env.HUBOT_DEFAULT_LATITUDE || !process.env.HUBOT_DEFAULT_LONGITUDE
            return msg.send 'No default location set.'

        getForecast({
            lat: process.env.HUBOT_DEFAULT_LATITUDE,
            lon: process.env.HUBOT_DEFAULT_LONGITUDE
        }, (err1, forecastData) ->
            if err1
                return handleError(err1, msg)
            msg.send formatWeather(forecastData)

            getAlerts({
                latitude: forecastData['coord']['lat']
                longitude: forecastData['coord']['lon']
            }, (err2, alertData) ->
                if (err2)
                    return handleError(err2, msg)
                robot.logger.info(alertData)
                if alertData['features'].length > 0
                    msg.send formatAlerts(alertData)
            )
        )

    # Search by zip code
    robot.respond /weather (\d+)/i, (msg) ->
        if !process.env.HUBOT_OPEN_WEATHER_MAP_API_KEY
            return msg.send 'No API Key configured.'

        zipCode = msg.match[1]

        getForecast({
            zip: zipCode
        }, (err1, forecastData) ->
            if err1
                return handleError(err1, msg)
            msg.send formatWeather(forecastData)

            getAlerts({
                latitude: forecastData['coord']['lat']
                longitude: forecastData['coord']['lon']
            }, (err2, alertData) ->
                if (err2)
                    return handleError(err2, msg)
                robot.logger.info(alertData)
                if alertData['features'].length > 0
                    msg.send formatAlerts(alertData)
            )
        )

    # Search by city name
    robot.respond /weather ([\w ]+)\,(?:\s)?(\w{2})/i, (msg) ->
        if !process.env.HUBOT_OPEN_WEATHER_MAP_API_KEY
            return msg.send 'No API Key configured.'

        cityName = msg.match[1]
        state = msg.match[2].toUpperCase
        robot.logger.debug cityName, state

        getForecast({
            q: "#{cityName},#{state}"
        }, (err1, forecastData) ->
            if err1
                return handleError(err1, msg)

            msg.send formatWeather(forecastData)


            getAlerts({
                latitude: forecastData['coord']['lat']
                longitude: forecastData['coord']['lon']
            }, (err2, alertData) ->
                if (err2)
                    return handleError(err2, msg)
                robot.logger.info(alertData)
                if alertData['features'].length > 0
                    msg.send formatAlerts(alertData)
            )
        )

    getForecast = (query, callback) ->
        query['appid'] = process.env.HUBOT_OPEN_WEATHER_MAP_API_KEY
        robot.http(baseUrl)
            .query(query)
            .get() (err, res, body) ->
                json = JSON.parse(body)
                if json.cod? and json.cod != 200
                    return callback(json.message)
                callback(err, json)

    getAlerts = (query, callback) ->
        robot.http("#{baseUrlNWS}/points/#{query['latitude']},#{query['longitude']}")
            .get() (err1, res1, body1) ->
                if err1
                    return callback(err1)
                pointJSON = JSON.parse(body1)
                countyCode = pointJSON['properties']['county'].match(/.*\/(\w+)$/)[1]

                robot.http("#{baseUrlNWS}/alerts/active/zone/#{countyCode}")
                    .get() (err2, res2, body2) ->
                        if err2
                            return callback(err2)
                        alerts = JSON.parse(body2)
                        robot.logger.debug alerts
                        callback(err2, alerts)

    formatWeather = (json) ->
        return "Currently #{json.weather[0].main} and #{formatUnits(json.main.temp, 'imperial')}F/#{formatUnits(json.main.temp, 'metric')}C in #{json.name}"

    formatAlerts = (json) ->
        output = ["#{json['title']}:"]
        for alert in json['features']
            output.push "- #{alert['properties']['headline']}"
        return output.join("\n")

    formatUnits = (value, unit) ->
        value = switch
            when unit == 'metric' then value - 273.15
            when unit == 'imperial' then (value - 273.15) * 9/5 + 32

        return value.toFixed(0)

    handleError = (err, msg) ->
        robot.logger.error err
        msg.send "Encountered error: #{err}"
