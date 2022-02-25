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

    # Give default weather
    robot.respond /weather$/i, (msg) ->
        if !process.env.HUBOT_OPEN_WEATHER_MAP_API_KEY
            return msg.send 'No API Key configured.'

        if !process.env.HUBOT_DEFAULT_LATITUDE || !process.env.HUBOT_DEFAULT_LONGITUDE
            return msg.send 'No default location set.'

        msg.http(baseUrl)
            .query({
                appid: process.env.HUBOT_OPEN_WEATHER_MAP_API_KEY,
                lat: process.env.HUBOT_DEFAULT_LATITUDE,
                lon: process.env.HUBOT_DEFAULT_LONGITUDE
            })
            .get() (err, res, body) ->
                if err
                    return handleError(err, msg)
                robot.logger.debug process.env.HUBOT_DEFAULT_LATITUDE
                robot.logger.debug process.env.HUBOT_DEFAULT_LONGITUDE
                robot.logger.debug body
                json = JSON.parse(body)
                msg.send formatWeather(json)

    # Search by zip code
    robot.respond /weather (\d+)/i, (msg) ->
        if !process.env.HUBOT_OPEN_WEATHER_MAP_API_KEY
            return msg.send 'No API Key configured.'

        zipCode = msg.match[1]

        msg.http(baseUrl)
            .query({
                appid: process.env.HUBOT_OPEN_WEATHER_MAP_API_KEY,
                zip: zipCode
            })
            .get() (err, res, body) ->
                if err
                    return handleError(err, msg)
                json = JSON.parse(body)
                msg.send formatWeather(json)


    # Search by city name
    robot.respond /weather ([\w ]+)\,(?:\s)?(\w{2})/i, (msg) ->
        if !process.env.HUBOT_OPEN_WEATHER_MAP_API_KEY
            return msg.send 'No API Key configured.'

        cityName = msg.match[1]
        state = msg.match[2].toUpperCase
        robot.logger.debug cityName, state

        msg.http(baseUrl)
            .query({
                appid: process.env.HUBOT_OPEN_WEATHER_MAP_API_KEY,
                q: "#{cityName},#{state}"
            })
            .get() (err, res, body) ->
                if err
                    return handleError(err, msg)
                robot.logger.debug body
                json = JSON.parse(body)
                if json.cod? and json.cod != 200
                    return handleError(json.message, msg)

                msg.send formatWeather(json)


    formatWeather = (json) ->
        return "Currently #{json.weather[0].main} and #{formatUnits(json.main.temp, 'imperial')}F/#{formatUnits(json.main.temp, 'metric')}C in #{json.name}"

    formatUnits = (value, unit) ->
        value = switch
            when unit == 'metric' then value - 273.15
            when unit == 'imperial' then (value - 273.15) * 9/5 + 32

        return value.toFixed(0)

    handleError = (err, msg) ->
        robot.logger.error err
        msg.send "Encountered error: #{err}"
