#!/bin/bash
#
# Registers MQTT discovery topics for Home Assistant on container start.
# Follows HA MQTT auto-discovery norms: unique_id, device grouping, device_class, state_class.
# Energy sensors (Wh) use state_class=total_increasing for the HA Energy Dashboard.

MQTT_SERVER=$(cat /etc/inverter/mqtt.json | jq '.server' -r)
MQTT_PORT=$(cat /etc/inverter/mqtt.json | jq '.port' -r)
MQTT_TOPIC=$(cat /etc/inverter/mqtt.json | jq '.topic' -r)
MQTT_DEVICENAME=$(cat /etc/inverter/mqtt.json | jq '.devicename' -r)
MQTT_USERNAME=$(cat /etc/inverter/mqtt.json | jq '.username' -r)
MQTT_PASSWORD=$(cat /etc/inverter/mqtt.json | jq '.password' -r)
MQTT_CLIENTID=$(cat /etc/inverter/mqtt.json | jq '.clientid' -r)

# $1=key  $2=friendly_name  $3=unit  $4=icon  $5=device_class(or "none")  $6=state_class(or "none")
registerTopic () {
    local KEY="$1"
    local NAME="$2"
    local UNIT="$3"
    local ICON="$4"
    local DEVICE_CLASS="$5"
    local STATE_CLASS="$6"

    local PAYLOAD
    PAYLOAD=$(jq -n \
        --arg name         "$NAME" \
        --arg unique_id    "${MQTT_DEVICENAME}_${KEY}" \
        --arg state_topic  "${MQTT_TOPIC}/sensor/${MQTT_DEVICENAME}_${KEY}" \
        --arg unit         "$UNIT" \
        --arg icon         "mdi:${ICON}" \
        --arg device_class "$DEVICE_CLASS" \
        --arg state_class  "$STATE_CLASS" \
        --arg dev_id       "$MQTT_DEVICENAME" \
        --arg dev_name     "$MQTT_DEVICENAME" \
        '{
            name:         $name,
            unique_id:    $unique_id,
            state_topic:  $state_topic,
            icon:         $icon,
            device: {
                identifiers: [$dev_id],
                name:         $dev_name,
                model:        "Voltronic Inverter",
                manufacturer: "Voltronic"
            }
        }
        | if $unit         != ""     then . + {unit_of_measurement: $unit}         else . end
        | if $device_class != "none" then . + {device_class: $device_class}        else . end
        | if $state_class  != "none" then . + {state_class:  $state_class}         else . end
        ')

    mosquitto_pub \
        -h "$MQTT_SERVER" \
        -p "$MQTT_PORT" \
        -u "$MQTT_USERNAME" \
        -P "$MQTT_PASSWORD" \
        -i "$MQTT_CLIENTID" \
        -r \
        -t "${MQTT_TOPIC}/sensor/${MQTT_DEVICENAME}_${KEY}/config" \
        -m "$PAYLOAD"
}

registerInverterRawCMD () {
    local PAYLOAD
    PAYLOAD=$(jq -n \
        --arg name        "$MQTT_DEVICENAME" \
        --arg unique_id   "${MQTT_DEVICENAME}_raw_cmd" \
        --arg state_topic "${MQTT_TOPIC}/sensor/${MQTT_DEVICENAME}" \
        --arg dev_id      "$MQTT_DEVICENAME" \
        --arg dev_name    "$MQTT_DEVICENAME" \
        '{
            name:        $name,
            unique_id:   $unique_id,
            state_topic: $state_topic,
            device: {
                identifiers: [$dev_id],
                name:         $dev_name,
                model:        "Voltronic Inverter",
                manufacturer: "Voltronic"
            }
        }')

    mosquitto_pub \
        -h "$MQTT_SERVER" \
        -p "$MQTT_PORT" \
        -u "$MQTT_USERNAME" \
        -P "$MQTT_PASSWORD" \
        -i "$MQTT_CLIENTID" \
        -r \
        -t "${MQTT_TOPIC}/sensor/${MQTT_DEVICENAME}/config" \
        -m "$PAYLOAD"
}

# key                           friendly name                   unit    icon                  device_class      state_class
registerTopic "Inverter_mode"              "Inverter Mode"              ""      "solar-power"         "none"            "none"
registerTopic "AC_grid_voltage"            "AC Grid Voltage"            "V"     "power-plug"          "voltage"         "measurement"
registerTopic "AC_grid_frequency"          "AC Grid Frequency"          "Hz"    "current-ac"          "frequency"       "measurement"
registerTopic "AC_out_voltage"             "AC Output Voltage"          "V"     "power-plug"          "voltage"         "measurement"
registerTopic "AC_out_frequency"           "AC Output Frequency"        "Hz"    "current-ac"          "frequency"       "measurement"
registerTopic "PV_in_voltage"              "PV Input Voltage"           "V"     "solar-panel-large"   "voltage"         "measurement"
registerTopic "PV_in_current"              "PV Input Current"           "A"     "solar-panel-large"   "current"         "measurement"
registerTopic "PV_in_watts"                "PV Input Power"             "W"     "solar-panel-large"   "power"           "measurement"
registerTopic "PV_in_watthour"             "PV Input Energy"            "Wh"    "solar-panel-large"   "energy"          "total_increasing"
registerTopic "SCC_voltage"                "SCC Voltage"                "V"     "current-dc"          "voltage"         "measurement"
registerTopic "Load_pct"                   "Load Percentage"            "%"     "brightness-percent"  "none"            "measurement"
registerTopic "Load_watt"                  "Load Power"                 "W"     "chart-bell-curve"    "power"           "measurement"
registerTopic "Load_watthour"              "Load Energy"                "Wh"    "chart-bell-curve"    "energy"          "total_increasing"
registerTopic "Load_va"                    "Load Apparent Power"        "VA"    "chart-bell-curve"    "apparent_power"  "measurement"
registerTopic "Bus_voltage"                "Bus Voltage"                "V"     "details"             "voltage"         "measurement"
registerTopic "Heatsink_temperature"       "Heatsink Temperature"       "°C"    "thermometer"         "temperature"     "measurement"
registerTopic "Battery_capacity"           "Battery Capacity"           "%"     "battery-outline"     "battery"         "measurement"
registerTopic "Battery_voltage"            "Battery Voltage"            "V"     "battery-outline"     "voltage"         "measurement"
registerTopic "Battery_charge_current"     "Battery Charge Current"     "A"     "current-dc"          "current"         "measurement"
registerTopic "Battery_discharge_current"  "Battery Discharge Current"  "A"     "current-dc"          "current"         "measurement"
registerTopic "Load_status_on"             "Load Status"                ""      "power"               "none"            "none"
registerTopic "SCC_charge_on"              "SCC Charge Status"          ""      "power"               "none"            "none"
registerTopic "AC_charge_on"               "AC Charge Status"           ""      "power"               "none"            "none"
registerTopic "Battery_recharge_voltage"   "Battery Recharge Voltage"   "V"     "current-dc"          "voltage"         "measurement"
registerTopic "Battery_under_voltage"      "Battery Under Voltage"      "V"     "current-dc"          "voltage"         "measurement"
registerTopic "Battery_bulk_voltage"       "Battery Bulk Voltage"       "V"     "current-dc"          "voltage"         "measurement"
registerTopic "Battery_float_voltage"      "Battery Float Voltage"      "V"     "current-dc"          "voltage"         "measurement"
registerTopic "Max_grid_charge_current"    "Max Grid Charge Current"    "A"     "current-ac"          "current"         "measurement"
registerTopic "Max_charge_current"         "Max Charge Current"         "A"     "current-ac"          "current"         "measurement"
registerTopic "Out_source_priority"        "Output Source Priority"     ""      "grid"                "none"            "none"
registerTopic "Charger_source_priority"    "Charger Source Priority"    ""      "solar-power"         "none"            "none"
registerTopic "Battery_redischarge_voltage" "Battery Redischarge Voltage" "V"   "battery-negative"    "voltage"         "measurement"
registerTopic "Warnings"                   "Warnings"                   ""      "alert-outline"       "none"            "none"

# Separate topic for sending raw commands from HA back to the inverter (e.g. POP01, PCP02)
registerInverterRawCMD
