#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

Preferences prefs;

#define SERVICE_UUID        "12345678-1234-5678-1234-56789abcdef0"
#define IP_CHAR_UUID        "12345678-1234-5678-1234-56789abcdef1"
#define A_CHAR_UUID         "12345678-1234-5678-1234-56789abcdef2"
#define B_CHAR_UUID         "12345678-1234-5678-1234-56789abcdef3"
#define C_CHAR_UUID         "12345678-1234-5678-1234-56789abcdef4"
#define NAME_CHAR_UUID      "12345678-1234-5678-1234-56789abcdef6"

BLEServer *pServer = nullptr;
BLECharacteristic *pIpCharacteristic = nullptr;
BLECharacteristic *pACharacteristic = nullptr;
BLECharacteristic *pBCharacteristic = nullptr;
BLECharacteristic *pCCharacteristic = nullptr;
BLECharacteristic *pNameCharacteristic = nullptr;

// Callback class for BLE characteristic changes
class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) override {
    // Get value from characteristic as String
    String value = pCharacteristic->getValue().c_str();
    String uuid = pCharacteristic->getUUID().toString().c_str();

    if (value.length() > 0) {
      if (uuid == IP_CHAR_UUID) {
        prefs.putString("ip_address", value.c_str());
        pIpCharacteristic->setValue(value.c_str()); // Optionally notify clients
        Serial.println("IP Address updated to: " + value);
      } else if (uuid == NAME_CHAR_UUID) {
        prefs.putString("name", value.c_str());
        pNameCharacteristic->setValue(value.c_str()); // Optionally notify clients
        Serial.println("Name updated to: " + value);
      } else if (uuid == A_CHAR_UUID) {
        prefs.putString("value_A", value);
        pACharacteristic->setValue(value); // Optionally notify clients
        Serial.println("Received value for A: " + value);
      } else if (uuid == B_CHAR_UUID) {
        prefs.putString("value_B", value);
        pBCharacteristic->setValue(value); // Optionally notify clients
        Serial.println("Received value for B: " + value);
      } else if (uuid == C_CHAR_UUID) {
        prefs.putString("value_C", value);
        pCCharacteristic->setValue(value); // Optionally notify clients
        Serial.println("Received value for C: " + value);
      }
    }
  }
};

void setup() {
  Serial.begin(115200);

  prefs.begin("my-app", false);

  BLEDevice::init("ESP32_BLE");

  pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);

  pIpCharacteristic = pService->createCharacteristic(
    IP_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY
  );
  pIpCharacteristic->addDescriptor(new BLE2902());

  pNameCharacteristic = pService->createCharacteristic(
    NAME_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY
  );
  pNameCharacteristic->addDescriptor(new BLE2902());

  pACharacteristic = pService->createCharacteristic(
    A_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
  );
  pACharacteristic->addDescriptor(new BLE2902());

  pBCharacteristic = pService->createCharacteristic(
    B_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
  );
  pBCharacteristic->addDescriptor(new BLE2902());

  pCCharacteristic = pService->createCharacteristic(
    C_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
  );

  // Set the callback for characteristics
  pIpCharacteristic->setCallbacks(new MyCallbacks());
  pNameCharacteristic->setCallbacks(new MyCallbacks());
  pACharacteristic->setCallbacks(new MyCallbacks());
  pBCharacteristic->setCallbacks(new MyCallbacks());
  pCCharacteristic->setCallbacks(new MyCallbacks());

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();

  Serial.println("Waiting for a client to connect...");

  // Check and print stored values in NVS
  Serial.println("Stored NVS Values:");
  Serial.println("IP Address: " + prefs.getString("ip_address", "Not set"));
  Serial.println("Name: " + prefs.getString("name", "Not set"));
  Serial.println("Value A: " + prefs.getString("value_A", "Not set"));
  Serial.println("Value B: " + prefs.getString("value_B", "Not set"));
  Serial.println("Value C: " + prefs.getString("value_C", "Not set"));
}

void loop() {
  // No need for additional code in loop() since all BLE operations are handled via callbacks
}