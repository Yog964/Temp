import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

// Automatically determine the correct baseUrl for the environment
String getBaseUrl() {
  if (kIsWeb) return 'http://localhost:8000';
  if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  return 'http://localhost:8000';
}
final String baseUrl = getBaseUrl();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('access_token');
  
  runApp(UrbanSathiApp(initialPage: token != null ? const DashboardPage() : const LoginPage()));
}

class UrbanSathiApp extends StatelessWidget {
  final Widget initialPage;
  const UrbanSathiApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanSathi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF14B8A6),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF14B8A6),
          secondary: Color(0xFF3B82F6),
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Roboto',
      ),
      home: initialPage,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token'),
        body: {
          'username': _phoneController.text,
          'password': _passwordController.text,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      } else {
        _showError('Invalid phone number or password');
      }
    } catch (e) {
      _showError('Connection error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Icon(Icons.location_city_rounded, size: 80, color: Color(0xFF14B8A6)),
                const SizedBox(height: 24),
                const Text('UrbanSathi', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration('Phone Number', Icons.phone),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: _inputDecoration('Password', Icons.lock),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _login,
                      style: _btnStyle(),
                      child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                  child: const Text("Don't have an account? Register", style: TextStyle(color: Color(0xFF14B8A6))),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF14B8A6),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text,
          'phone_number': _phoneController.text,
          'password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful! Please login.')));
          Navigator.pop(context);
        }
      } else {
        _showError('Registration failed: ${json.decode(response.body)['detail']}');
      }
    } catch (e) {
      _showError('Connection error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextFormField(controller: _nameController, decoration: _inputDecoration('Full Name', Icons.person)),
            const SizedBox(height: 16),
            TextFormField(controller: _phoneController, decoration: _inputDecoration('Phone Number', Icons.phone)),
            const SizedBox(height: 16),
            TextFormField(controller: _passwordController, decoration: _inputDecoration('Password', Icons.lock), obscureText: true),
            const SizedBox(height: 24),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _register, style: _btnStyle(), child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      backgroundColor: const Color(0xFF14B8A6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeView(),
    CommunityView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E293B),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_vote_rounded), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF14B8A6),
        unselectedItemColor: Colors.white54,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportIssuePage())),
        backgroundColor: const Color(0xFF14B8A6),
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<dynamic> _myComplaints = [];
  String _userName = 'Citizen';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final userRes = await http.get(Uri.parse('$baseUrl/users/me'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
      if (userRes.statusCode == 200) {
        setState(() => _userName = json.decode(userRes.body)['name']);
      }

      final complaintRes = await http.get(Uri.parse('$baseUrl/complaints/me'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
      if (complaintRes.statusCode == 200) {
        setState(() => _myComplaints = json.decode(complaintRes.body));
      }
    } catch (e) {
      print('Error fetching home data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $_userName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Reports', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text('${_myComplaints.length} Issues', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Icon(Icons.assignment, color: Colors.white, size: 30)
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Your Recent Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _myComplaints.length,
                    itemBuilder: (context, index) {
                      final item = _myComplaints[index];
                      return _buildReportCard(item['title'], item['status'], Colors.orange);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String status, Color statusColor) {
    return Card(
      color: const Color(0xFF1E293B),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Status tracking enabled'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class CommunityView extends StatelessWidget {
  const CommunityView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Community Validation View'));
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_pin, size: 100, color: Color(0xFF14B8A6)),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          )
        ],
      ),
    );
  }
}

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  File? _image;
  final picker = ImagePicker();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _aiData;

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _isAnalyzing = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // 1. Upload File
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/'));
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
      var uploadRes = await request.send();
      var uploadData = json.decode(await uploadRes.stream.bytesToString());

      // 2. Create Complaint (Back-end does AI analysis mock internally)
      final complaintRes = await http.post(
        Uri.parse('$baseUrl/complaints/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': 'New Issue Spotted',
          'description': 'Reported via mobile',
          'image_url': uploadData['image_url'],
          'latitude': 28.6139,
          'longitude': 77.2090,
        }),
      );

      if (complaintRes.statusCode == 200) {
        setState(() {
          _aiData = json.decode(complaintRes.body);
          _isAnalyzing = false;
        });
        _showAiSuggestion();
      }
    } catch (e) {
      print('Error in report flow: $e');
      setState(() => _isAnalyzing = false);
    }
  }

  void _showAiSuggestion() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI Analysis Result', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _row('Issue', _aiData?['issue_type']),
            _row('Dept', _aiData?['department_suggested']),
            _row('Severity', '${_aiData?['severity_score']}/10'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Confirm & Submit'),
            )
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String? v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text(v ?? '...', style: const TextStyle(fontWeight: FontWeight.bold))]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null) Image.file(_image!, height: 300),
            if (_isAnalyzing) const CircularProgressIndicator(),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: getImage, icon: const Icon(Icons.camera), label: const Text('Capture Issue')),
          ],
        ),
      ),
    );
  }
}
