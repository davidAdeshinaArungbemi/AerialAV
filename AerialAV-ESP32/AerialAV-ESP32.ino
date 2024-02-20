#include <DHT.h>
#include <DHT_U.h>
#include <Adafruit_Sensor.h>
#include <ArduinoJson.h>
#include <PubSubClient.h>
#include <Adafruit_BMP085.h>
#include "Orientation.h"
#include <WiFi.h>

#define SOUND_SEN_PIN 36
#define DHTPIN 23
#define DHTTYPE DHT11

MPU mpu;
DHT_Unified  dht(DHTPIN, DHTTYPE); //temperature and humidity sensor  
Adafruit_BMP085 bmp180;

const char* ssid = "Bladeworks";
const char* password = "beautifulDay4m3@2024";

const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883; // non-secure port. Dont send sensitive data

const char* topic = "AerialAV";

WiFiClient espClient;
PubSubClient client(espClient);

int second_payload_counter = 0;

void WiFiConnect(){
  Serial.println("Connecting to WiFi...");
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    Serial.println("Couldn't get a wifi connection. Trying again...");
    delay(1000);
    Serial.print(".");
  }

  Serial.println("Wifi connected!");
}

void ConnectToBroker(){
  while(!client.connected()){
    Serial.println("Connecting to MQTT Broker via port " + String(mqtt_port));

    if (client.connect("AerialAV")) {
      Serial.println("Connected!");
    }

    else{
      Serial.println("Failed to connect!");
      Serial.println(client.state());
      Serial.println("Reattempting....");
      delay(1000);
    }
  }
}

void setup() {
  pinMode(19, OUTPUT);
  digitalWrite(19, HIGH);
  Serial.begin(115200);
  while(!Serial)
    delay(1000);

  //begin bmp180, mpu and dht
  mpu.Begin();
  delay(2000);
  dht.begin();
  while (!bmp180.begin()){
    Serial.println(("Failed to connect"));
    delay(1000);
  }

  delay(2000);
  WiFiConnect();

  client.setServer(mqtt_server, mqtt_port); //connect to server
}

void loop() {
  if (!client.connected()){
    ConnectToBroker();
  }
  
  float* orientation = mpu.DeriveOrientation();

  // Create a JSON document
  StaticJsonDocument<200> json;

  // Add data to the JSON document
  json["orientation"]["roll"] = orientation[0];
  json["orientation"]["pitch"] = orientation[1];
  json["orientation"]["yaw"] = orientation[2];
  float* raw_imu = mpu.ProcessedDataPointerAccess();
  json["accX"] = raw_imu[0];
  json["accY"] = raw_imu[1];
  json["accZ"] = raw_imu[2];
  json["gyrX"] = raw_imu[3];
  json["gyrY"] = raw_imu[4];
  json["gyrZ"] = raw_imu[5];

  // Serialize the JSON document to a string
  String jsonString;
  serializeJson(json, jsonString);

  // Serial.printf("%f,%f,%f\n", orientation[0], orientation[1], orientation[2]);

  // Serial.println(jsonString);
  
  const char* message_payload = jsonString.c_str();
  
  if(!client.publish(topic, message_payload, 0)){
    Serial.println("Failed to publish!");
  }
  else{
    Serial.println("Publish successful!");
  }

  // second_payload_counter++;

  // if (second_payload_counter == 100){
    // second_payload_counter = 0;
    //SECOND PAYLOAD

    sensors_event_t event;
  
    StaticJsonDocument<200> json_2;
    dht.temperature().getEvent(&event);
    if (isnan(event.temperature)) {
      Serial.println("Problem comrade!");
    }

    json_2["temperature"] = bmp180.readTemperature();
    dht.humidity().getEvent(&event);
    // json_2["humidity"] =  event.relative_humidity;
    json_2["humidity"] =  20.0;
    json_2["pressure"] = bmp180.readPressure();
    json_2["vibration"] = analogRead(SOUND_SEN_PIN);
    json_2["altitude"] = bmp180.readAltitude();

    // Serialize the JSON document to a string
    String jsonString_2;
    serializeJson(json_2, jsonString_2);

    Serial.println(jsonString_2);
    
    const char* message_payload_2 = jsonString_2.c_str();
    
    if(!client.publish(topic, message_payload_2, 2)){
      Serial.println("Failed to publish!");
    }
    else{
      Serial.println("Publish successful!");
    }
  // }
}
