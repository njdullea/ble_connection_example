//This is version trying to include switch
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

bool deviceConnected = false;
bool oldDeviceConnected = false;
bool switchPressed = false;
uint8_t value = 0;
int switchState = 0;
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristicLight = NULL;
BLECharacteristic* pCharacteristicSwitch = NULL;


//This is a practice BLE example.
//It will control three lights (Red Yellow Green)
//And count when the switch is pushed 


#define SERVICE_UUID                "6c251c91-dde0-4263-a0a7-d26b4a662b41"
#define LIGHT_CHARACTERISTIC_UUID   "ffc7b3e7-3ff6-4672-a060-a47b884f38b1"
#define SWITCH_CHARACTERISTIC_UUID  "3b712824-9972-4283-946b-7257f760b29c"

void switchLight(std::string code) {
  if (code == "0") {
    digitalWrite(A0, LOW);
    digitalWrite(A1, HIGH);
    digitalWrite(A5, LOW);
  }
  else if (code == "1") {
    digitalWrite(A0, LOW);
    digitalWrite(A1, LOW);
    digitalWrite(A5, HIGH);
  } 
  else if (code == "2") {
    digitalWrite(A0, HIGH);
    digitalWrite(A1, LOW);
    digitalWrite(A5, LOW);
  }
  //delay(250);
}

class serverCallBacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
  };

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
  };
};

class callBacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0) {
      for (int i = 0; i < value.length(); i++) {
        Serial.print(value[i]);
      }
      //lightOn = value;
      switchLight(value);
    }
  }
};

void setup() {
  // put your setup code here, to run once:
  // Setting serial baud rate to 115200
  Serial.begin(115200);

  // Setting up pins
  pinMode(A2, INPUT);
  pinMode(A1, OUTPUT);
  pinMode(A0, OUTPUT);
  pinMode(A5, OUTPUT);

  //Turn one pin on
  digitalWrite(A0, HIGH);
  digitalWrite(A1, LOW);
  digitalWrite(A5, LOW);
  
  // Setting up BLE server
  BLEDevice ::init("ESP");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new serverCallBacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristicLight = pService->createCharacteristic(
                                              LIGHT_CHARACTERISTIC_UUID,
                                              BLECharacteristic::PROPERTY_READ |
                                              BLECharacteristic::PROPERTY_WRITE_NR
                                             ); 

  pCharacteristicSwitch = pService->createCharacteristic(
                                                SWITCH_CHARACTERISTIC_UUID,
                                                BLECharacteristic::PROPERTY_READ   |
                                                BLECharacteristic::PROPERTY_WRITE  |
                                                BLECharacteristic::PROPERTY_NOTIFY |
                                                BLECharacteristic::PROPERTY_INDICATE
                                              );

  pCharacteristicLight->setCallbacks(new callBacks());
  //pCharacteristicLight->setValue("Hello World");
  pService->start();

  BLEAdvertising *pAdvertising = pServer->getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  //pAdvertising->addServiceUUID(pService->getUUID());
  pAdvertising->start();
}

void loop() {
  // put your main code here, to run repeatedly:
  //delay(2000);
  if (deviceConnected) {
    switchState = digitalRead(A2);

    if (switchState == HIGH) {
      if (switchPressed == false) {
        switchPressed = true;
        value++;
        pCharacteristicSwitch->setValue(&value, 1);
        pCharacteristicSwitch->notify();
        Serial.print("should be updating");
        delay(100);
      }
    }
    else {
      if (switchPressed == true) {
        switchPressed = false;
      }
    }
  }
}
