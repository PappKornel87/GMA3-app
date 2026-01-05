import 'dart:io';
// HOZZÁADVA: A debugPrint funkcióhoz szükséges.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:osc/osc.dart';

// TÖRÖLVE: A 'dart:async' import felesleges volt.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData darkTheme = ThemeData.dark();

    // JAVÍTVA: Egyedi TextTheme definiálása a jobb vizuális hierarchiáért.
    final appTextTheme = darkTheme.textTheme.copyWith(
      titleLarge: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold),
      bodyMedium: GoogleFonts.roboto(fontSize: 14),
    );

    return MaterialApp(
      title: 'MA3 Remote',
      theme: darkTheme.copyWith(
        primaryColor: Colors.orange.shade800,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange.shade800,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        // JAVÍTVA: Az egyedi TextTheme használata.
        textTheme: appTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1F1F1F),
          // JAVÍTVA: Az AppBar címe mostantól az egyedi TextTheme-et használja.
          titleTextStyle: appTextTheme.titleLarge?.copyWith(color: Colors.orange.shade800),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          fillColor: const Color(0xFF2A2A2A),
          filled: true,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.orange.shade800, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade400),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
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
  final TextEditingController _ipController = TextEditingController(text: "192.168.0.102");
  final TextEditingController _portController = TextEditingController(text: "8000");
  OSCSocket? _socket;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connect();
    });
  }

  @override
  void dispose() {
    _socket?.close();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _connect() {
    if (!mounted) return;

    _socket?.close();
    try {
      final ip = InternetAddress(_ipController.text);
      final port = int.parse(_portController.text);

      _socket = OSCSocket(destination: ip, destinationPort: port);
      setState(() {
        _isConnected = true;
      });
      _showFeedback('Sikeresen csatlakozva ide: $ip:$port', Colors.green);
    } catch (e) {
      setState(() {
        _isConnected = false;
      });
      _showFeedback('Csatlakozási hiba: $e', Colors.red);
    }
  }

  void sendOSC(String address, List<Object> arguments) {
    if (!mounted) return;
    if (_socket == null || !_isConnected) {
      _showFeedback('Nincs kapcsolat! Csatlakozz újra.', Colors.orange);
      return;
    }
    final message = OSCMessage(address, arguments: arguments);
    _socket!.send(message);

    debugPrint("Elküldve: $address $arguments");
  }

  void _showFeedback(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("grandMA3 OSC Remote"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Icon(
              _isConnected ? Icons.wifi_tethering : Icons.wifi_tethering_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingsPanel(),
            const SizedBox(height: 24),
            Expanded(child: _buildButtonGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: "MA3 IP Cím"),
              onSubmitted: (_) => _connect(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _portController,
              decoration: const InputDecoration(labelText: "Port"),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _connect(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            icon: const Icon(Icons.sync),
            onPressed: _connect,
            tooltip: 'Újracsatlakozás',
            style: IconButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: [
        _buildOSCButton("Go+ Seq 5", "/cmd", ["Go+ Sequence 5"], Colors.green.shade700),
        _buildOSCButton("Off Seq 5", "/cmd", ["Off Sequence 5"], Colors.red.shade700),
        _buildOSCButton("Pause Seq 5", "/cmd", ["Pause Sequence 5"], Colors.yellow.shade800),
        _buildOSCButton("Goto Cue 1", "/cmd", ["Go+ Sequence 5 Cue 1"], Colors.blue.shade700),
        _buildOSCButton("Update", "/cmd", ["Update"], Colors.teal.shade600),
        _buildOSCButton("Clear All", "/cmd", ["Clear"], Colors.deepPurple.shade600),
        // HOZZÁADVA: Az új, dedikált gomb a "Fixture 1 At 100" parancshoz.
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber, // Sárga szín a kiemelésért
            minimumSize: const Size(200, 60),
          ),
          onPressed: () {
            sendOSC("/cmd", ["Fixture 1 At 100"]);
          },
          child: const Text(
            "FIXTURE 1 @ 100%",
            style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildOSCButton(String label, String address, List<Object> args, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () => sendOSC(address, args),
      child: Text(label),
    );
  }
}
