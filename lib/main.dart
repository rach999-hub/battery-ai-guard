import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(const BatteryAiApp());
}

class BatteryAiApp extends StatelessWidget {
  const BatteryAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battery AI Guard',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const BatteryHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BatteryHomePage extends StatefulWidget {
  const BatteryHomePage({super.key});

  @override
  State<BatteryHomePage> createState() => _BatteryHomePageState();
}

class _BatteryHomePageState extends State<BatteryHomePage> {
  int _currentIndex = 0;
  
  // Instance du package battery
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  Timer? _timer;

  // Paramètres personnalisables par l'utilisateur
  int _lowThreshold = 20;
  int _highThreshold = 80;
  String _lowMessage = "Yo toi vas-y branche-moi !";
  String _highMessage = "Mec débranche-moi pour protéger la batterie !";
  String _aiStatusMessage = "Analyse du système en cours...";

  // Contrôleurs pour les champs de texte des paramètres
  late TextEditingController _lowMsgController;
  late TextEditingController _highMsgController;
  late TextEditingController _lowThreshController;
  late TextEditingController _highThreshController;

  @override
  void initState() {
    super.initState();
    _lowMsgController = TextEditingController(text: _lowMessage);
    _highMsgController = TextEditingController(text: _highMessage);
    _lowThreshController = TextEditingController(text: _lowThreshold.toString());
    _highThreshController = TextEditingController(text: _highThreshold.toString());

    _loadSettings();
    _initBatteryMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lowMsgController.dispose();
    _highMsgController.dispose();
    _lowThreshController.dispose();
    _highThreshController.dispose();
    super.dispose();
  }

  // Charger les paramètres enregistrés
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lowThreshold = prefs.getInt('lowThreshold') ?? 20;
      _highThreshold = prefs.getInt('highThreshold') ?? 80;
      _lowMessage = prefs.getString('lowMessage') ?? "Yo toi vas-y branche-moi !";
      _highMessage = prefs.getString('highMessage') ?? "Mec débranche-moi pour protéger la batterie !";

      _lowThreshController.text = _lowThreshold.toString();
      _highThreshController.text = _highThreshold.toString();
      _lowMsgController.text = _lowMessage;
      _highMsgController.text = _highMessage;
    });
  }

  // Sauvegarder les paramètres
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lowThreshold = int.tryParse(_lowThreshController.text) ?? 20;
      _highThreshold = int.tryParse(_highThreshController.text) ?? 80;
      _lowMessage = _lowMsgController.text;
      _highMessage = _highMsgController.text;
    });

    await prefs.setInt('lowThreshold', _lowThreshold);
    await prefs.setInt('highThreshold', _highThreshold);
    await prefs.setString('lowMessage', _lowMessage);
    await prefs.setString('highMessage', _highMessage);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres enregistrés avec succès !')),
    );
  }

  // Surveillance de la batterie
  void _initBatteryMonitoring() async {
    _batteryLevel = await _battery.batteryLevel;
    _batteryState = await _battery.batteryState;

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      setState(() {
        _batteryLevel = level;
        _batteryState = state;
        _evaluateAiMessage();
      });
    });
  }

  // La logique de la Mini IA
  void _evaluateAiMessage() {
    if (_batteryState == BatteryState.charging) {
      if (_batteryLevel >= _highThreshold) {
        _aiStatusMessage = "💬 \"$_highMessage\"";
      } else {
        _aiStatusMessage = "💬 \"Recharge en cours... Tout est sous contrôle.\"";
      }
    } else {
      if (_batteryLevel <= _lowThreshold) {
        _aiStatusMessage = "💬 \"$_lowMessage\"";
      } else {
        _aiStatusMessage = "💬 \"Niveau stable. Je surveille la consommation.\"";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      // ÉCRAN 1 : LE MONITEUR
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent, width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    "$_batteryLevel%",
                    style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _batteryState == BatteryState.charging ? "⚡ En charge" : "🔋 Sur batterie",
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _aiStatusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.amberAccent),
              ),
            ),
          ],
        ),
      ),

      // ÉCRAN 2 : LES PARAMÈTRES DE LA MINI IA
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("⚙️ Personnalisation Mini IA", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _lowThreshController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Seuil batterie faible (%)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _lowMsgController,
              decoration: const InputDecoration(labelText: 'Message (Batterie Faible)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _highThreshController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Seuil batterie pleine/haute (%)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _highMsgController,
              decoration: const InputDecoration(labelText: 'Message (Batterie Pleine)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.all(14)),
                onPressed: _saveSettings,
                child: const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery AI Guard'),
        backgroundColor: const Color(0xFF1F1F1F),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1F1F1F),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Moniteur'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}
