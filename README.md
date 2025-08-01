# AerialAV: Aerial Analysis and Visualisation

## Overview
**AerialAV** integrates Internet of Things (IoT) principles with Unmanned Aerial Vehicles (UAVs) to enable real-time data collection and visualisation of motion and environmental conditions.  
The system combines:

- **Hardware:** ESP-WROOM-32 microcontroller with multiple sensors (IMU, barometer, temperature, humidity, sound).  
- **Firmware:** C++/Arduino-based firmware for data collection, sensor fusion, and MQTT publishing.  
- **Software:** A desktop flight application built with Processing (Java) for real-time data visualisation and 3D orientation tracking.

### Key Features
- Real-time UAV orientation, altitude, and environmental monitoring
- Sensor fusion using accelerometer and gyroscope (Madgwick filter)
- MQTT-based lightweight messaging for IoT communication
- 3D drone model visualisation for orientation tracking
- JSON-based data streaming for efficiency and compatibility

---

## System Architecture

### Hardware Components
- **ESP-WROOM-32:** Main controller, Wi-Fi enabled
- **MPU6050:** 6-DOF IMU (accelerometer + gyroscope)
- **BMP180:** Barometric pressure and temperature sensor
- **DHT11:** Temperature and humidity sensor
- **LM393:** Sound/vibration detection
- **Optional Future Sensors:** GPS module, 9-DOF IMU

### Firmware Features
- Reads sensor data via **I2C** and single-wire protocols
- Computes **roll, pitch, yaw** from sensor fusion
- Publishes JSON-formatted telemetry to MQTT broker (`HiveMQ`)
- Uses **QoS 0** for low-latency, real-time updates

### Software Application
- Built in **Processing (Java)**
- Visualises:
  - Orientation (3D drone model)
  - Sensor charts (roll, pitch, yaw, altitude, temp, humidity, pressure, vibration)
- Dependencies:
  - `giCentreUtils` for charts
  - `PeasyCam` for 3D camera controls
  - `processing-mqtt` for MQTT
  - Free 3D drone model from [Free3D](https://free3d.com)

---

## Project Workflow

1. **Sensor Data Collection:**  
   Sensors capture UAV orientation, environmental, and vibration data.

2. **Firmware Processing:**  
   - Sensor fusion for orientation  
   - JSON serialization  
   - Data published to MQTT topic `AerialAV`

3. **Data Visualisation:**  
   - Flight software subscribes to MQTT topic  
   - 3D drone model reflects live orientation  
   - Charts display environmental and motion data

---

## Challenges and Solutions
- **DHT11 Inconsistent Readings:** Some units unreliable at 3.3V → plan to replace with higher-quality sensor.  
- **Orientation Drift:** Yaw drift without magnetometer → future 9-DOF IMU integration.  
- **Initial Software Lag:** Reduced sampling rate from 1000 Hz to 100 Hz to improve responsiveness.

---

## Future Improvements
- Integrate GPS for position tracking
- Use 9-DOF IMU for improved orientation accuracy
- Improve environmental sensor reliability
- Add encrypted MQTT communication for secure data transfer

---

## Applications
- Recreational and hobby drone flights
- Aerial surveillance and environmental monitoring
- IoT-driven UAV telemetry for research and development

---

## References
- [MQTT Protocol](https://en.wikipedia.org/wiki/MQTT)  
- [Processing IDE](https://processing.org/)  
- [HiveMQ Public Broker](https://www.hivemq.com/mqtt/public-mqtt-broker/)  
- Full reference list available in the project PDF report.

---

## Author
**David Adeshina Arungbemi**  
Department of Computer Engineering,  
Nile University of Nigeria
