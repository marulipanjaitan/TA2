import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:kt_session/bluetooth/communication_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:collection/collection.dart';
import 'connected_device_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SimpleLogger logger = SimpleLogger();
  CommunicationHandler? communicationHandler;
  bool isScanStarted = false;
  bool isConnected = false;
  List<DiscoveredDevice> discoveredDevices =
      List<DiscoveredDevice>.empty(growable: true);

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  @override
  void dispose() {
    stopScan();
    super.dispose();
  }

  void checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.bluetoothAdvertise,
    ].request();

    logger.info("PermissionStatus -- $statuses");
  }

  void startScan() {
    communicationHandler ??= CommunicationHandler();
    communicationHandler?.startScan((scanDevice) {
      logger.info("Scan device: ${scanDevice.name}");
      if (discoveredDevices
              .firstWhereOrNull((val) => val.id == scanDevice.id) ==
          null) {
        logger.info("Added new device to list: ${scanDevice.name}");
        setState(() {
          discoveredDevices.add(scanDevice);
        });
      }
    });

    setState(() {
      isScanStarted = true;
      discoveredDevices.clear();
    });
  }

  Future<void> stopScan() async {
    await communicationHandler?.stopScan();
    setState(() {
      isScanStarted = false;
    });
  }

  Future<void> connectToDevice(DiscoveredDevice selectedDevice) async {
    await stopScan();
    communicationHandler?.connectToDevice(selectedDevice, (isConnected) {
      this.isConnected = isConnected;
      if (isConnected) {
        String ipAddress = '';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConnectedDeviceScreen(
              connectedDevice: selectedDevice,
              ipAddress: ipAddress,
            ),
          ),
        ).then((_) {
          // Setelah kembali dari ConnectedDeviceScreen, pastikan scan diinisialisasi ulang
          if (!isScanStarted) {
            startScan();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TA_KEL3"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Center(
            child: TextButton(
              onPressed: () {
                isScanStarted ? stopScan() : startScan();
              },
              child: Text(isScanStarted ? "Stop Scan" : "Start Scan"),
            ),
          ),
          SizedBox(
            height: 400,
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: discoveredDevices.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    height: 60,
                    color: Colors.greenAccent,
                    child: Center(
                      child: TextButton(
                        child: Text(discoveredDevices[index].name),
                        onPressed: () {
                          DiscoveredDevice selectedDevice =
                              discoveredDevices[index];
                          connectToDevice(selectedDevice);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
