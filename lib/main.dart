import 'package:flutter/material.dart';
import 'package:osc/osc.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MA3 Remote',
      theme: ThemeData.dark(), // Sötét téma, hogy profin nézzen ki
      home: const RemotePage(),
    );
  }
}

class RemotePage extends StatefulWidget {
  const RemotePage({super.key});

  @override
  State<RemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends State<RemotePage> {
  // MA3 beállítások (Alapértelmezett)
  final TextEditingController _ipController = TextEditingController(text: "192.168.0.102");
  final TextEditingController _portController = TextEditingController(text: "8000");

  // OSC üzenet küldése
  void sendOSC(String address, List<Object> arguments) {
    try {
      final ip = InternetAddress(_ipController.text);
      final port = int.parse(_portController.text);
      
      final message = OSCMessage(address, arguments: arguments);
      final socket = OSCSocket(destination: ip, destinationPort: port);
      socket.send(message);
      socket.close(); // Fontos: lezárjuk a kapcsolatot küldés után
      
      print("Elküldve: $address $arguments");
    } catch (e) {
      print("Hiba: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("grandMA3 OSC Remote")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- BEÁLLÍTÁSOK ---
            Row(
              children: [
                Expanded(child: TextField(controller: _ipController, decoration: const InputDecoration(labelText: "MA3 IP Cím"))),
                const SizedBox(width: 20),
                Expanded(child: TextField(controller: _portController, decoration: const InputDecoration(labelText: "Port (pl. 8000)"))),
              ],
            ),
            const SizedBox(height: 50),

            // --- GOMBOK ---
            // A "/cmd" cím a grandMA3-ban parancssori utasítást futtat!
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(200, 60)),
              onPressed: () => sendOSC("/cmd", ["Go+ Sequence 5"]), // PÉLDA PARANCS
              child: const Text("GO+ Seq 5", style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(200, 60)),
              onPressed: () => sendOSC("/cmd", ["Off Sequence 5"]),
              child: const Text("OFF Seq 5", style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(200, 60)),
               onPressed: () => sendOSC("/cmd", ["Clear"]),
               child: const Text("CLEAR ALL", style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ),
    );
  }
}