import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('isFirstRun') ?? true;
  runApp(MyApp(isFirstRun: isFirstRun));
}

class MyApp extends StatelessWidget {
  final bool isFirstRun;
  const MyApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider(create: (_) => GameLauncher()),
      ],
      child: MaterialApp(
        title: 'MC Java Launcher',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          fontFamily: 'Roboto',
        ),
        initialRoute: isFirstRun ? '/install' : '/home',
        routes: {
          '/': (context) => const HomeScreen(),
          '/home': (context) => const HomeScreen(),
          '/install': (context) => const InstallScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/login': (context) => const LoginScreen(),
        },
        localizationsDelegates: const [
          // Add localization delegates for Korean and English
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('ko', ''),
        ],
        locale: const Locale('ko', ''), // Default to Korean
      ),
    );
  }
}

class AppSettings extends ChangeNotifier {
  String _language = 'ko';
  int _memory = 1024;

  String get language => _language;
  int get memory => _memory;

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void setMemory(int mem) {
    _memory = mem;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language);
    await prefs.setInt('memory', _memory);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? 'ko';
    _memory = prefs.getInt('memory') ?? 1024;
    notifyListeners();
  }
}

class GameLauncher extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _offlineNickname = 'tester_12345';
  List<String> _supportedVersions = [
    '1.21',
    '1.21.1',
    '1.21.10',
    '1.0',
    '1.19',
    '1.19.1',
    '1.16.5',
    '1.16'
  ];
  String? _selectedVersion;
  bool _isInstalling = false;
  double _installProgress = 0.0;

  bool get isLoggedIn => _isLoggedIn;
  String get offlineNickname => _offlineNickname;
  List<String> get supportedVersions => _supportedVersions;
  String? get selectedVersion => _selectedVersion;
  bool get isInstalling => _isInstalling;
  double get installProgress => _installProgress;

  void selectVersion(String version) {
    _selectedVersion = version;
    notifyListeners();
  }

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> installVersions() async {
    _isInstalling = true;
    _installProgress = 0.0;
    notifyListeners();

    // Simulate installation process
    for (int i = 0; i < _supportedVersions.length; i++) {
      await Future.delayed(const Duration(seconds: 10)); // Simulate download time
      _installProgress = (i + 1) / _supportedVersions.length;
      notifyListeners();
    }

    _isInstalling = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);
    notifyListeners();
  }

  Future<void> launchGame() async {
    // Placeholder for launching Minecraft
    // In real implementation, this would use PojavLauncher or similar
    print('Launching Minecraft version: $_selectedVersion');
  }

  Future<void> openGameFiles() async {
    final directory = await getExternalStorageDirectory();
    final gameDir = Directory('${directory!.path}/.minecraft');
    if (!await gameDir.exists()) {
      await gameDir.create(recursive: true);
    }
    // Use url_launcher to open file manager
    final uri = Uri.parse('file://${gameDir.path}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final launcher = Provider.of<GameLauncher>(context);
    final settings = Provider.of<AppSettings>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MC Java Launcher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('지원 버전:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: launcher.supportedVersions.length,
                itemBuilder: (context, index) {
                  final version = launcher.supportedVersions[index];
                  return ListTile(
                    title: Text(version),
                    leading: Radio<String>(
                      value: version,
                      groupValue: launcher.selectedVersion,
                      onChanged: (value) => launcher.selectVersion(value!),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: launcher.selectedVersion != null ? () => launcher.launchGame() : null,
              child: const Text('게임 실행'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => launcher.openGameFiles(),
              child: const Text('게임 파일 열기'),
            ),
          ],
        ),
      ),
    );
  }
}

class InstallScreen extends StatefulWidget {
  const InstallScreen({super.key});

  @override
  State<InstallScreen> createState() => _InstallScreenState();
}

class _InstallScreenState extends State<InstallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameLauncher>(context, listen: false).installVersions().then((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final launcher = Provider.of<GameLauncher>(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('게임 버전 설치 중...', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            CircularProgressIndicator(value: launcher.installProgress),
            const SizedBox(height: 20),
            Text('${(launcher.installProgress * 100).toStringAsFixed(0)}% 완료'),
            const SizedBox(height: 20),
            const Text('인터넷 연결이 필요하며, 약 5-15분 소요됩니다.'),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('언어:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: settings.language,
              items: const [
                DropdownMenuItem(value: 'ko', child: Text('한국어')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) => settings.setLanguage(value!),
            ),
            const SizedBox(height: 20),
            const Text('메모리 (MB):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: settings.memory.toDouble(),
              min: 512,
              max: 4096,
              divisions: 7,
              label: '${settings.memory} MB',
              onChanged: (value) => settings.setMemory(value.toInt()),
            ),
            Text('${settings.memory} MB'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => settings.saveSettings(),
              child: const Text('설정 저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final launcher = Provider.of<GameLauncher>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!launcher.isLoggedIn) ...[
              const Text('마인크래프트 정품 계정으로 로그인하세요.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => launcher.login(), // Placeholder for real login
                child: const Text('Microsoft 로그인'),
              ),
            ] else ...[
              const Text('로그인됨'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => launcher.logout(),
                child: const Text('로그아웃'),
              ),
            ],
            const SizedBox(height: 20),
            Text('오프라인 닉네임: ${launcher.offlineNickname}'),
          ],
        ),
      ),
    );
  }
}