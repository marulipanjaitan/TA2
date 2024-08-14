#include "MyBLELibrary.h"

#define SERVICE_UUID        "12345678-1234-5678-1234-56789abcdef0"
#define IP_CHAR_UUID        "12345678-1234-5678-1234-56789abcdef1"
#define A_CHAR_UUID         "12345678-1234-5678-1234-56789abcdef2"
#define B_CHAR_UUID         "12345678-1234-5678-1234-56789abcdef3"
#define C_CHAR_UUID         "12345678-1234-5678-1234-56789abcdef4"
#define NAME_CHAR_UUID      "12345678-1234-5678-1234-56789abcdef6"

MyBLELibrary::MyBLELibrary() {}

void MyBLELibrary::begin() {
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
    MyCallbacks* myCallbacks = new MyCallbacks(this);
    pIpCharacteristic->setCallbacks(myCallbacks);
    pNameCharacteristic->setCallbacks(myCallbacks);
    pACharacteristic->setCallbacks(myCallbacks);
    pBCharacteristic->setCallbacks(myCallbacks);
    pCCharacteristic->setCallbacks(myCallbacks);

    pService->start();
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();

    Serial.println("Waiting for a client to connect...");
}

void MyBLELibrary::printStoredValues() {
    Serial.println("Stored NVS Values:");
    Serial.println("IP Address: " + prefs.getString("ip_address", "Not set"));
    Serial.println("Name: " + prefs.getString("name", "Not set"));
    Serial.println("Value A: " + prefs.getString("value_A", "Not set"));
    Serial.println("Value B: " + prefs.getString("value_B", "Not set"));
    Serial.println("Value C: " + prefs.getString("value_C", "Not set"));
}

void MyBLELibrary::MyCallbacks::onWrite(BLECharacteristic *pCharacteristic) {
    String value = pCharacteristic->getValue().c_str();
    String uuid = pCharacteristic->getUUID().toString().c_str();

    if (value.length() > 0) {
        if (uuid == IP_CHAR_UUID) {
            myLibrary->prefs.putString("ip_address", value.c_str());
            myLibrary->pIpCharacteristic->setValue(value.c_str());
            Serial.println("IP Address updated to: " + value);
        } else if (uuid == NAME_CHAR_UUID) {
            myLibrary->prefs.putString("name", value.c_str());
            myLibrary->pNameCharacteristic->setValue(value.c_str());
            Serial.println("Name updated to: " + value);
        } else if (uuid == A_CHAR_UUID) {
            myLibrary->prefs.putString("value_A", value);
            myLibrary->pACharacteristic->setValue(value);
            Serial.println("Received value for A: " + value);
        } else if (uuid == B_CHAR_UUID) {
            myLibrary->prefs.putString("value_B", value);
            myLibrary->pBCharacteristic->setValue(value);
            Serial.println("Received value for B: " + value);
        } else if (uuid == C_CHAR_UUID) {
            myLibrary->prefs.putString("value_C", value);
            myLibrary->pCCharacteristic->setValue(value);
            Serial.println("Received value for C: " + value);
        }
    }
}
