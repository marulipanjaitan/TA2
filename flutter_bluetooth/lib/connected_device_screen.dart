import 'dart:async';
import 'dart:convert'; // For utf8 encoding

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectedDeviceScreen extends StatefulWidget {
  final DiscoveredDevice connectedDevice;
  final String ipAddress;

  const ConnectedDeviceScreen({
    Key? key,
    required this.connectedDevice,
    required this.ipAddress,
  }) : super(key: key);

  @override
  _ConnectedDeviceScreenState createState() => _ConnectedDeviceScreenState();
}

class _ConnectedDeviceScreenState extends State<ConnectedDeviceScreen> {
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  late Stream<ConnectionStateUpdate> _connectionStream;
  late StreamSubscription<ConnectionStateUpdate> _connectionSubscription;

  late TextEditingController _ipAddressController;
  late TextEditingController _nameController;
  late TextEditingController _serviceUuidController;
  late TextEditingController _rssiController;

  // Controllers for A, B, C
  late TextEditingController _controllerA;
  late TextEditingController _controllerB;
  late TextEditingController _controllerC;
  late TextEditingController _controllerPort;

  // UUIDs for characteristics
  final Map<String, String> characteristicUuids = {
    'SERVICE': '12345678-1234-5678-1234-56789abcdef0',
    'IP': '12345678-1234-5678-1234-56789abcdef1',
    'A': '12345678-1234-5678-1234-56789abcdef2',
    'B': '12345678-1234-5678-1234-56789abcdef3',
    'C': '12345678-1234-5678-1234-56789abcdef4',
    'Name': '12345678-1234-5678-1234-56789abcdef6',
    'Port': '12345678-1234-5678-1234-56789abcdef7',
  };

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _ipAddressController = TextEditingController();
    _nameController = TextEditingController(text: widget.connectedDevice.name);
    _serviceUuidController =
        TextEditingController(text: '12345678-1234-5678-1234-56789abcdef0');
    _rssiController =
        TextEditingController(text: widget.connectedDevice.rssi.toString());

    _controllerA = TextEditingController();
    _controllerB = TextEditingController();
    _controllerC = TextEditingController();
    _controllerPort = TextEditingController();

    // Load saved preferences
    _loadPreferences();

    // Initialize connection and characteristics
    _startConnectionMonitor();
  }

  @override
  void dispose() {
    _ipAddressController.dispose();
    _nameController.dispose();
    _serviceUuidController.dispose();
    _rssiController.dispose();
    _controllerA.dispose();
    _controllerB.dispose();
    _controllerC.dispose();
    _controllerPort.dispose();
    _connectionSubscription.cancel(); // Cancel subscription when disposing
    super.dispose();
  }

  void _startConnectionMonitor() {
    _connectionStream = flutterReactiveBle
        .connectToDevice(
          id: widget.connectedDevice.id,
          connectionTimeout: const Duration(seconds: 10),
        )
        .asBroadcastStream();

    _connectionSubscription = _connectionStream.listen((connectionState) {
      if (connectionState.connectionState ==
          DeviceConnectionState.disconnected) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }, onError: (error) {
      // Handle connection errors
      print('Connection error: $error');
    });
  }

  // Load SharedPreferences
  void _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipAddressController.text =
          prefs.getString('ip_address') ?? widget.ipAddress;
      _controllerA.text = prefs.getString('a_value') ?? '';
      _controllerB.text = prefs.getString('b_value') ?? '';
      _controllerC.text = prefs.getString('c_value') ?? '';
      _controllerPort.text = prefs.getString('Port_value') ?? '';
      _nameController.text =
          prefs.getString('device_name') ?? widget.connectedDevice.name;
    });
  }

  // Save SharedPreferences
  void _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip_address', _ipAddressController.text);
    await prefs.setString('a_value', _controllerA.text);
    await prefs.setString('b_value', _controllerB.text);
    await prefs.setString('c_value', _controllerC.text);
    await prefs.setString('Port_value', _controllerPort.text);
    await prefs.setString('device_name', _nameController.text);
  }

  // Send data to Bluetooth
  void _sendDataToBluetooth(String uuid, String value) {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse('12345678-1234-5678-1234-56789abcdef0'),
      characteristicId: Uuid.parse(uuid),
      deviceId: widget.connectedDevice.id,
    );

    flutterReactiveBle
        .writeCharacteristicWithResponse(
      characteristic,
      value: utf8.encode(value),
    )
        .then((_) {
      print("Data berhasil dikirim UUID: $uuid - Value: $value");
    }).catchError((error) {
      print("Gagal mengirim data: $error");
    });
  }

  void _onFieldSubmitted(String uuid, TextEditingController controller) {
    String value = controller.text;
    if (value.isNotEmpty) {
      _sendDataToBluetooth(uuid, value);
    }
  }

  bool _isValidIpAddress(String ip) {
    final regex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return regex.hasMatch(ip);
  }

  void _saveChanges() {
    final ipAddress = _ipAddressController.text;
    final a = _controllerA.text;
    final b = _controllerB.text;
    final c = _controllerC.text;
    final Port = _controllerPort.text;
    final name = _nameController.text;

    if (_isValidIpAddress(ipAddress)) {
      _sendDataToBluetooth(characteristicUuids['IP']!, ipAddress);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid IP Address'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _sendDataToBluetooth(characteristicUuids['A']!, a);
    _sendDataToBluetooth(characteristicUuids['B']!, b);
    _sendDataToBluetooth(characteristicUuids['C']!, c);
    _sendDataToBluetooth(characteristicUuids['Port']!, Port);
    _sendDataToBluetooth(characteristicUuids['Name']!, name);

    // Save the name in SharedPreferences
    _savePreferences();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perubahan berhasil disimpan!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connected Device Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "IP Address: ${_ipAddressController.text}",
                style: const TextStyle(fontSize: 16),
              ),
              TextField(
                controller: _ipAddressController,
                decoration: const InputDecoration(labelText: "Edit IP Address"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              Text(
                "MAC Address: ${widget.connectedDevice.id}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "Name: ${_nameController.text}",
                style: const TextStyle(fontSize: 16),
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Edit Name"),
              ),
              const SizedBox(height: 10),
              Text(
                "Service UUID: ${_serviceUuidController.text}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "RSSI: ${_rssiController.text}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // A, B, C EditTexts
              TextField(
                controller: _controllerA,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "A"),
                onSubmitted: (value) =>
                    _onFieldSubmitted(characteristicUuids['A']!, _controllerA),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controllerB,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "B"),
                onSubmitted: (value) =>
                    _onFieldSubmitted(characteristicUuids['B']!, _controllerB),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controllerC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "C"),
                onSubmitted: (value) =>
                    _onFieldSubmitted(characteristicUuids['C']!, _controllerC),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controllerPort,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Port"),
                onSubmitted: (value) => _onFieldSubmitted(
                    characteristicUuids['Port']!, _controllerPort),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
