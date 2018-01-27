# MagicMirror

A web based information radiator software for your magic mirror wall poject.

![Screenshot](https://raw.github.com/arrizer/MagicMirror/master/screenshot.png)

This node.js project provides a simple black and white webpage interface that you can run on a RaspberryPi, hooked up to a display inside a home-made magic mirror project (display behind a semi-transparent glass front). It is configurable with widgets that are displayed from top to bottom.

## Installation

You need node.js, and the npm dendency manager (comes with node.js) installed. Read a tutorial for your platform for details. After you have node.js installed and checked-out this git repository, install coffee-script globally by running:

`npm -g i coffeescript`

then, cd into the git repository and run:

`npm -g i`

to install all dependencies.

## Configuration

The server supports several widgets, all of them need to be configured inside a `config.json` file. Rename the `config.example.json` file and use it as base for your desired configruation. The config file is a JSON object with the following keys:

- `port`: The HTTP port at which the server runs, defaults to 8080
- `language`: The language used by all widgets (currently `en` and `de` are supported)
- `widgets`: An array of objects that configure individual widgets that are displayed from top to bottom. Each widget has a `widget` key that declares the widget's name and a `config` key that contains more widget-specific configuration. See below for details.

Currently the following widgets are supported:

### Clock

Displays the current time and date in large text.

Widget name: `clock`

Configuration keys:

- `locale`: The moment.js locale used for formatting date and time (e.g. en or de)

### News

Cycles through the titles of one or more RSS feeds.

Widget name: `news`

Configuration keys:

- `feeds`: Array of strings with RSS feed URLs that are used for the news headlines

### Netatmo

Display indoor and outdoor temperature and other measurements from Netatmo sensors. You need to register an app with https://dev.netatmo.com/en-US/dev to obtain a client ID and secret.

Widget name: `netatmo`

Configuration keys:

- `auth`: Contains the following 4 keys reuqired to authenticate againts the netatmo API:
    - `client_id`: Client ID of your netatmo app
    - `client_secret`: Client secret of your netatmo app
    - `username`: Username of you netatmo account
    - `password`: Password of your netatmo acocunt
- `stations`: Array of strings that is used to filter the netatmo base stations that are displayed, if your accounts contains more than one

### Rain

Hyperlocal rain prediction for the next hour. Works with the RainToday iOS app API by Meteo-Group, only supported in Germany at the moment.

Widget name: `rain`

Configuration keys:

- `latitude`: Latitude of the location for which rain forecast should be displayed
- `longitude`: Longitude of the location for which rain forecast should be displayed

### Weather

Weather forecast for today and the next 7 days via the wunderground weather API. You need to register an app at https://espanol.wunderground.com/weather/api to obtain an API key.

Widget name: `weather`

Configuration keys:

- `wunderground_api_key`: API key of your wunderground app
- `city`: Full (english) name of the city for which you whish to display weather forecast
- `country`: Full name of the country of the city for which you whish to display weather forecast
- `units`: Choose between `"celsius"` or `"fahrenheit"` for temperature units

### MVG Live

Real-time public transport departures for munich (MVG stations only). Displays U-Bahn, S-Bahn, Tram and Bus departures in real-time for all MVG stations (see http://www.mvg-live.de/). You need to obtain an API keys. Unfortunately there is no way to register directly, but you can ask MVG for a key via e-mail.

Widget name: `mvglive`

Configuration keys:

- `mvglive_api_key`: API key for MVG live API
- `stations`: Array of strings with station names. Make sure the spelling matches exactly the spelling from the website

## Deployment

To run the server, simply run `coffee app.coffee` from the command line. I recommend using a deployment manager (e.g. http://pm2.keymetrics.io) to make sure the server keeps running.