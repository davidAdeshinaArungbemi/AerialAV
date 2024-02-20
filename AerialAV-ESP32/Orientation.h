#include <Butterworth.h>
#include <Fusion.h>
#include <Wire.h>
#include <MPU6050.h>

#define itr 300
#define SAMPLE_PERIOD (0.02) //100Hz

struct MPU{
  private:

  MPU6050 mpu;
  int16_t rawData[6] = {0};
  int16_t mpuOffsets[6] = {0.0};

  float processedData[6] = {0.0};
  float orientationData[3] = {0.0};
  float ACC_SENS, GYR_SENS;

  FusionAhrs ahrs;

  // const int order = 1; // 4th order (=2 biquads)
  // Iir::Butterworth::LowPass<1> f;
  // const float samplingrate = 1000; // Hz
  // const float cutoff_frequency = 20; // Hz

  void OffsetCalib(){
    for(int i = 0; i < itr; i++){
      mpu.getMotion6(
        &rawData[0], 
        &rawData[1], 
        &rawData[2], 
        &rawData[3], 
        &rawData[4], 
        &rawData[5]
      );

      mpuOffsets[0] += rawData[0]; 
      mpuOffsets[1] += rawData[1]; 
      mpuOffsets[2] += rawData[2]; 
      mpuOffsets[3] += rawData[3]; 
      mpuOffsets[4] += rawData[4]; 
      mpuOffsets[5] += rawData[5];
    }

    mpuOffsets[0] = mpuOffsets[0]/itr; 
    mpuOffsets[1] = mpuOffsets[1]/itr; 
    mpuOffsets[2] = mpuOffsets[2]/itr; 
    mpuOffsets[3] = mpuOffsets[3]/itr; 
    mpuOffsets[4] = mpuOffsets[4]/itr; 
    mpuOffsets[5] = mpuOffsets[5]/itr;
  }

  public:

  void Begin(float ACC_SENS = 16384, float GYR_SENS = 131){
    this->ACC_SENS = ACC_SENS;
    this->GYR_SENS = GYR_SENS;
    Wire.begin();
    mpu.initialize();
    // f.setup (samplingrate, cutoff_frequency);
    this->OffsetCalib();

    FusionAhrsInitialise(&ahrs);
  }

  float* ReadData(){
    mpu.getMotion6(
        &rawData[0], 
        &rawData[1], 
        &rawData[2], 
        &rawData[3], 
        &rawData[4], 
        &rawData[5]
    );

    processedData[0] = (rawData[0]-mpuOffsets[0])/ACC_SENS; 
    processedData[1] = (rawData[1]-mpuOffsets[1])/ACC_SENS; 
    processedData[2] = (rawData[2]-mpuOffsets[2])/ACC_SENS; 
    processedData[3] = (rawData[3]-mpuOffsets[3])/GYR_SENS; 
    processedData[4] = (rawData[4]-mpuOffsets[4])/GYR_SENS; 
    processedData[5] = (rawData[5]-mpuOffsets[5])/GYR_SENS;

    // processedData[0] = f.filter(processedData[0]);
    // processedData[1] = f.filter(processedData[1]);
    // processedData[2] = f.filter(processedData[2]);
    // processedData[3] = f.filter(processedData[3]);
    // processedData[4] = f.filter(processedData[4]);
    // processedData[5] = f.filter(processedData[5]);
    
    return processedData;
  }

  float* DeriveOrientation(){
    ReadData();
    const FusionVector acc = {processedData[0],processedData[1],processedData[2]};
    const FusionVector gyr = {processedData[3],processedData[4],processedData[5]};
    FusionAhrsUpdateNoMagnetometer(&ahrs, gyr, acc, SAMPLE_PERIOD);
    const FusionEuler euler = FusionQuaternionToEuler(FusionAhrsGetQuaternion(&ahrs));
    orientationData[0] = euler.angle.roll;
    orientationData[1] = euler.angle.pitch;
    orientationData[2] = euler.angle.yaw;

    return orientationData;
  }

  float* ProcessedDataPointerAccess(){
    return processedData;
  }
};



