#ifndef MYBLELIBRARY_H
#define MYBLELIBRARY_H

#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

class MyBLELibrary {
public:
    MyBLELibrary();
    void begin();
    void printStoredValues();

private:
    Preferences prefs;
    BLEServer *pServer;
    BLECharacteristic *pIpCharacteristic;
    BLECharacteristic *pACharacteristic;
    BLECharacteristic *pBCharacteristic;
    BLECharacteristic *pCCharacteristic;
    BLECharacteristic *pNameCharacteristic;

    class MyCallbacks : public BLECharacteristicCallbacks {
    public:
        MyCallbacks(MyBLELibrary* library) : myLibrary(library) {}
        void onWrite(BLECharacteristic *pCharacteristic) override;

    private:
        MyBLELibrary* myLibrary;
    };
};

#endif
