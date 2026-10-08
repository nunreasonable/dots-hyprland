import QtQuick
import QtPositioning

PositionSource {
    id: positionSource
    updateInterval: Weather.fetchInterval

    Component.onCompleted: {
        console.info("[WeatherService] Starting the GPS service.");
        positionSource.start();
    }

    onPositionChanged: {
        // update the location if the given location is valid
        // if it fails getting the location, use the last valid location
        if (position.latitudeValid && position.longitudeValid) {
            Weather.location.lat = position.coordinate.latitude;
            Weather.location.long = position.coordinate.longitude;
            Weather.location.valid = true;
            // console.info(`📍 Location: ${position.coordinate.latitude}, ${position.coordinate.longitude}`);
            Weather.getData();
            // if can't get initialized with valid location deactivate the GPS
        } else {
            Weather.gpsActive = Weather.location.valid ? true : false;
            console.error("[WeatherService] Failed to get the GPS location.");
        }
    }

    onValidityChanged: {
        if (!positionSource.valid) {
            positionSource.stop();
            Weather.location.valid = false;
            Weather.gpsActive = false;
            Notifications.sendDesktop(Translation.tr("Weather Service"), Translation.tr("Cannot find a GPS service. Using the fallback method instead."), ["-a", "Shell"]);
            console.error("[WeatherService] Could not aquire a valid backend plugin.");
        }
    }
}
