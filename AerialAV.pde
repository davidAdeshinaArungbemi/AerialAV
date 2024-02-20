/*
  AerialAV is software that receives IMU data(including orientation), vibration, humidity and temperature and pressure, from an Aerial system and visualises the results on graphs. It also 
  carries out some calculations behind the scene including utilising acceleration data(from iMU) and pressure readings(BMP) to estimate altitude and vertical velocity.
  Additionally, it displays all numerical values from the sensors and provides a 3d visualisation for the aerial system's orientation.
  Communication between the Aerial system and the software is achieve using Message Queuing Telemetry Transport Protocol(MQTT).
  Furthermore, it also does data logging for external analysis.
  
  The aim of AerialAV is to assist with analysing aerial systems' motion and environmental conditions by providing clear visualisation in real time from its sensors
  
  Sensors utilised:
  Sound Sensor
  MPU6050
  DHT11 Sensor
  BMP180
  
  Dependencies:
  gicentreUtils library(for visualisation with charts) by Jo Wood and Aidan Slingsby
  PeasyCam library(for camera control with mouse) by Jonathan Feinberg
  MQTT library by Joel Gaehwiler
  3D Model of a Drone by zakardian(https://free3d.com/3d-model/drone-costume-411845.html)
*/

//import libraries
import org.gicentre.utils.stat.*;
import java.util.ArrayList;
import mqtt.*;
import peasy.*;

//Chart objects
XYChart roll_ch, pitch_ch, yaw_ch;
XYChart humidity_ch, temperature_ch, pressure_ch;
XYChart vertical_velocity_ch, altitude_ch;
XYChart pressure_altitude_ch, humidity_altitude_ch;
XYChart vibration_ch;

//MQTT client object
MQTTClient client;

//peasy object and model object
PeasyCam cam;
PShape model;

//subscription topic
String topic = "AerialAV";

//sensor data collection
ArrayList<Float> roll_collection = new ArrayList<>();
ArrayList<Float> yaw_collection = new ArrayList<>();
ArrayList<Float> pitch_collection = new ArrayList<>();

ArrayList<Float> humidity_collection = new ArrayList<>();
ArrayList<Float> temperature_collection = new ArrayList<>();
ArrayList<Float> pressure_collection = new ArrayList<>();
ArrayList<Float> vertical_velocity_collection = new ArrayList<>();
ArrayList<Float> altitude_collection = new ArrayList<>();
ArrayList<Float> vibration_collection = new ArrayList<>();
ArrayList<Float> time_collection = new ArrayList<>();
ArrayList<Float> time_collection_2 = new ArrayList<>();

//sensor data variables
float accX, accY, accZ;
float gyrX, gyrY, gyrZ;

//collection size limit
int collection_size = 200;


//JSON object
JSONObject json;

//sample counter
float counter, counter_2 = 0.0;

//spacing
int spacing_w = 30;
int spacing_h = 15;
int extra_spacing = 30; //gives extra spacing if i need, especially between plots

void setup(){
  size(1400,800,P3D); //width - 1400, Height - 800, P3D - necessary for the 3D model
  pixelDensity(2); //increases density of pixels to improve quality
  background(0); //pure white background
  
  //setting up the client 
  client = new MQTTClient(this);
  client.connect("mqtt://broker.hivemq.com", "AerialAVS");

  //setting up the charts
  roll_ch = new XYChart(this);
  pitch_ch = new XYChart(this); 
  yaw_ch = new XYChart(this); 
  humidity_ch = new XYChart(this);
  temperature_ch = new XYChart(this);
  pressure_ch = new XYChart(this);
  vertical_velocity_ch = new XYChart(this);
  altitude_ch = new XYChart(this);
  pressure_altitude_ch = new XYChart(this);
  humidity_altitude_ch = new XYChart(this);
  vibration_ch = new XYChart(this);
             
  roll_ch.showXAxis(true); 
  roll_ch.showYAxis(true); 
  //roll_ch.setMinY(0);
  roll_ch.setLineColour(color(180,50,50,100));
  roll_ch.setPointSize(0);
  roll_ch.setLineWidth(2);
  
  pitch_ch.showXAxis(true); 
  pitch_ch.showYAxis(true); 
  //pitch_ch.setMinY(0);
  pitch_ch.setLineColour(color(180,50,50,100));
  pitch_ch.setPointSize(0);
  pitch_ch.setLineWidth(2);
  
  yaw_ch.showXAxis(true); 
  yaw_ch.showYAxis(true); 
  //yaw_ch.setMinY(0);
  yaw_ch.setLineColour(color(180,50,50,100));
  yaw_ch.setPointSize(0);
  yaw_ch.setLineWidth(2);
  
  temperature_ch.showXAxis(true); 
  temperature_ch.showYAxis(true); 
  //temperature_ch.setMinY(0);
  temperature_ch.setLineColour(color(180,50,50,100));
  temperature_ch.setPointSize(0);
  temperature_ch.setLineWidth(2);
  
  humidity_ch.showXAxis(true); 
  humidity_ch.showYAxis(true); 
  //humidity_ch.setMinY(0);
  humidity_ch.setLineColour(color(180,50,50,100));
  humidity_ch.setPointSize(0);
  humidity_ch.setLineWidth(2);
  
  pressure_ch.showXAxis(true); 
  pressure_ch.showYAxis(true); 
  //pressure_ch.setMinY(0);
  pressure_ch.setLineColour(color(180,50,50,100));
  pressure_ch.setPointSize(0);
  pressure_ch.setLineWidth(2);
  
  vibration_ch.showXAxis(true); 
  vibration_ch.showYAxis(true); 
  //vibration_ch.setMinY(0);
  vibration_ch.setLineColour(color(180,50,50,100));
  vibration_ch.setPointSize(0);
  vibration_ch.setLineWidth(2);
  
  altitude_ch.showXAxis(true); 
  altitude_ch.showYAxis(true); 
  altitude_ch.showXAxis(true); 
  altitude_ch.setLineColour(color(180,50,50,100));
  altitude_ch.setPointSize(0);
  altitude_ch.setLineWidth(2);
  
  //setting up camera and 3d model
  cam = new PeasyCam(this, 110);
  cam.setMinimumDistance(10);
  cam.setMaximumDistance(500);
  cam.lookAt(width/2 ,height/2,0);
  model = loadShape("Drone3D/drone.obj");
}

void popCollections(ArrayList<Float> collection){ //ensure size of arraylist collections are limited by poping the first element
  if (collection.size() > int(width/4)){
    collection.remove(0);
  }
}

void draw(){ //for redrawing every frame
  background(0);
  
  cam.beginHUD(); //prevents interference from 3d camera peasy
  //update graph data
  roll_ch.setData(convertToArray(time_collection),convertToArray(roll_collection));
  pitch_ch.setData(convertToArray(time_collection),convertToArray(pitch_collection));
  yaw_ch.setData(convertToArray(time_collection),convertToArray(yaw_collection));
  altitude_ch.setData(convertToArray(time_collection_2),convertToArray(altitude_collection));
  
  temperature_ch.setData(convertToArray(time_collection_2),convertToArray(temperature_collection));
  humidity_ch.setData(convertToArray(time_collection_2),convertToArray(humidity_collection));
  pressure_ch.setData(convertToArray(time_collection_2),convertToArray(pressure_collection));
  vibration_ch.setData(convertToArray(time_collection_2),convertToArray(vibration_collection));
  
  //draw graph
  roll_ch.draw(spacing_w,spacing_h,width/4,height/5);
  pitch_ch.draw(spacing_w,extra_spacing+(height/5),width/4,height/5);
  yaw_ch.draw(spacing_w,extra_spacing+(height/5)*2 + spacing_h,width/4,height/5);
  altitude_ch.draw(spacing_w,extra_spacing+(height/5)*3+ spacing_h*2,width/4,height/5);
  
  temperature_ch.draw(width-spacing_w-width/4,spacing_h,width/4,height/5);
  humidity_ch.draw(width-spacing_w-width/4,extra_spacing+(height/5),width/4,height/5);
  pressure_ch.draw(width-spacing_w-width/4,extra_spacing+(height/5)*2 + spacing_h,width/4,height/5);
  vibration_ch.draw(width-spacing_w-width/4,extra_spacing+(height/5)*3 + spacing_h*2,width/4,height/5);
  
  //ensure data is of limited size
  popCollections(roll_collection);
  popCollections(pitch_collection);
  popCollections(yaw_collection);
  popCollections(time_collection);
  popCollections(time_collection_2);
  popCollections(temperature_collection);
  popCollections(humidity_collection);
  popCollections(pressure_collection);
  popCollections(vibration_collection);
  popCollections(altitude_collection);
   
   //display direct sensor readings
  if(vibration_collection.size() > 0){
    textSize(13);
    text("Direct Sensor Readings",width/2-200,spacing_h*2);
    textSize(12);
    text("AccX(m/s^2): " +accX,width/2-200,spacing_h*2+15);
    text("AccY(m/s^2): " +accY,width/2-200,spacing_h*2+30);
    text("AccZ(m/s^2): " +accZ,width/2-200,spacing_h*2+45);
    text("GyrX(deg/s): " +gyrX,width/2-200,spacing_h*2+60);
    text("GyrY(deg/s): " +gyrY,width/2-200,spacing_h*2+75);
    text("GyrZ(Deg/s): " +gyrZ,width/2-200,spacing_h*2+90);
    
    text("Humidity(%): " +humidity_collection.get(humidity_collection.size()-1), width/2-200, spacing_h*2+115);
    text("Temperature(oC): "+temperature_collection.get(temperature_collection.size()-1), width/2-200, spacing_h*2+130);
    text("Pressure(pa): " +pressure_collection.get(pressure_collection.size()-1), width/2-200, spacing_h*2+145);
    text("Vibration: " +vibration_collection.get(vibration_collection.size()-1), width/2-200, spacing_h*2+160);
  }
  
  //display derived readings
  textSize(13);
  text("Derived Readings",width/2+50,spacing_h*2);
  textSize(12);
  
  if (roll_collection.size() > 0){
    text("Roll(deg): " +roll_collection.get(roll_collection.size()-1), width/2+50, spacing_h*2+15);
    text("Pitch(deg): " +pitch_collection.get(pitch_collection.size()-1), width/2+50, spacing_h*2+30);
    text("Yaw(deg): "+yaw_collection.get(yaw_collection.size()-1), width/2+50, spacing_h*2+45);
    text("Altitude(m): "+altitude_collection.get(altitude_collection.size()-1), width/2+50, spacing_h*3+45);
  }
  
  //graph labels
  textSize(13);
  text("Roll(deg)", spacing_w + 25,spacing_h*2);
  text("Pitch(deg)", spacing_w + 25,height/5+spacing_h*3);
  text("Yaw(deg)", spacing_w + 25,(height/5)*2+spacing_h*4);
  text("Altitude(m)", spacing_w + 25,(height/5)*3+spacing_h*5);
  
  text("Temeprature(oC)", width/1.335 - spacing_w + 25,spacing_h*2);
  text("Humidity(%)",  width/1.335 - spacing_w + 25,height/5+spacing_h*3);
  text("Pressure(Pa)",  width/1.335 - spacing_w + 25,(height/5)*2+spacing_h*4);
  text("Vibration(mag)",  width/1.335 - spacing_w + 25,(height/5)*3+spacing_h*5);
  cam.endHUD();
  
  push();
  translate(width/2, height/2);
  scale(5);
  
  rotateX(PI);
  rotateY(PI);
  
  //light
  lights();
  lightSpecular(255, 220, 180);

  directionalLight(255, 220, 180, 1, 0, 1);
  ambient(255, 220, 180);
  
  //rotate 3d model according to orientation readings
  if (roll_collection.size() > 0){ //ensure collection is greater than 0;
    int last_pos = roll_collection.size()-1;
    rotateY(-1.0*radians(yaw_collection.get(last_pos)));
    rotateX(radians(pitch_collection.get(last_pos)));
    rotateZ(radians(roll_collection.get(last_pos)));
  }
  
  //axis lines
  stroke(0,0,255); //make blue
  line(0,-5,0,5); //z axis
  stroke(255,0,0); //make red
  line(-5,0,5,0); //x axis
  push();
  stroke(0,255,0); //make green
  rotateX(PI/2);
  line(0,-5,0,5); //y axis
  
  pop();

  shape(model);
  pop();
}

float[] convertToArray(ArrayList<Float> collection){
  float arr[] = new float[collection.size()]; //create an array with same size as arraylist
  for(int i = 0; i < collection.size(); i++){ //loop through arraylist
    arr[i] = collection.get(i); //fill up the array
  } 
  return arr;
}

void clientConnected() {
  println("client connected");
  client.subscribe("AerialAV");
}

void messageReceived(String topic, byte[] payload) {
  JSONObject json = JSONObject.parse(new String(payload)); //deserialise byte string to json

  if(json.hasKey("orientation")){
    time_collection.add(counter);
    counter++;
    
    //update orientation collection data
    roll_collection.add(json.getJSONObject("orientation").getFloat("pitch")); //i switched the roll and pitch due to issues with pitch and yaw being switched up during 3d rotation. I'm sure its caused by difference in axis direction of screen and object
    pitch_collection.add(json.getJSONObject("orientation").getFloat("roll"));
    yaw_collection.add(json.getJSONObject("orientation").getFloat("yaw"));
    gyrX = json.getFloat("gyrX");
    gyrY = json.getFloat("gyrY");
    gyrZ = json.getFloat("gyrZ");
    accX = json.getFloat("accX");
    accY = json.getFloat("accY");
    accZ = json.getFloat("accZ");
  }
  
  else{
    time_collection_2.add(counter);
    counter_2++;
    if (!json.isNull("temperature")){
      temperature_collection.add(json.getFloat("temperature"));
      humidity_collection.add(json.getFloat("humidity"));
    }
    pressure_collection.add(json.getFloat("pressure"));
    vibration_collection.add(json.getFloat("vibration"));
    altitude_collection.add(json.getFloat("altitude"));
  }
}

void connectionLost() {
  println("connection lost");
}
