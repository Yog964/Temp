import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

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
  
  String? _selectedDept;
  String? _selectedSub;
  final TextEditingController _descController = TextEditingController();
  
  // Location
  Position? _currentPosition;
  bool _isFetchingLocation = false;

  // Recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordedPath;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;

  bool _isSubmitting = false;

  final Map<String, List<String>> _departmentData = {
    'Water Supply': ['Water Leakage', 'Low Water Pressure', 'Broken Pipeline', 'No Water Supply'],
    'Electricity': ['Exposed Wire', 'Power Failure', 'Transformer Issue'],
    'Road & Infrastructure': ['Pothole', 'Road Crack', 'Blocked Drain', 'Broken Footpath'],
    'Waste Management': ['Garbage Heap', 'Stray Animal Issue', 'Drainage Block'],
    'Streetlight Maintenance': ['Light Not Working', 'Continuous Dimm'],
    'Sanitation': ['Clogged Sewer', 'Public Toilet Issue'],
  };

  @override
  void dispose() {
    _descController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);
    print("DEBUG: Starting location fetch...");
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("DEBUG: Location services disabled");
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print("DEBUG: Current permission: $permission");
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("DEBUG: Permission denied");
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("DEBUG: Permission denied forever");
        throw 'Location permissions are permanently denied';
      }

      print("DEBUG: Fetching current position...");
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      print("DEBUG: Position fetched: ${pos.latitude}, ${pos.longitude}");
      
      setState(() {
        _currentPosition = pos;
        _isFetchingLocation = false;
      });
    } catch (e) {
      print('DEBUG: Location Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location Error: $e')));
      }
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() => _recordDuration++);
          if (_recordDuration >= 60) _stopRecording();
        });
      }
    } catch (e) {
      print('Recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _recordedPath = path;
    });
  }

  Future<void> _playRecording() async {
    if (_recordedPath != null) {
      await _audioPlayer.play(DeviceFileSource(_recordedPath!));
    }
  }

  Future<void> _submitReport() async {
    if (_image == null || _selectedDept == null || _selectedSub == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all mandatory sections')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // 1. Upload Image
      var imgReq = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/'));
      imgReq.files.add(await http.MultipartFile.fromPath('file', _image!.path));
      var imgRes = await imgReq.send();
      var imgData = json.decode(await imgRes.stream.bytesToString());

      // 2. Upload Voice (if exists)
      String? voiceUrl;
      if (_recordedPath != null) {
        var voiceReq = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/'));
        voiceReq.files.add(await http.MultipartFile.fromPath('file', _recordedPath!));
        var voiceRes = await voiceReq.send();
        var voiceData = json.decode(await voiceRes.stream.bytesToString());
        voiceUrl = voiceData['image_url'];
      }

      // 3. Submit Complaint
      final res = await http.post(
        Uri.parse('$baseUrl/complaints/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': '$_selectedSub at ${_selectedDept}',
          'description': _descController.text.isEmpty ? 'Reported Issue' : _descController.text,
          'image_url': imgData['image_url'],
          'voice_url': voiceUrl,
          'latitude': _currentPosition?.latitude ?? 0.0,
          'longitude': _currentPosition?.longitude ?? 0.0,
          'department': _selectedDept,
          'subcategory': _selectedSub,
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Service Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('1. Photo Upload (Mandatory)', Icons.camera_alt),
            _buildPhotoSection(),
            
            if (_image != null) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('2. Select Department', Icons.business),
              _buildDeptGrid(),
              
              if (_selectedDept != null) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('3. Select Subcategory', Icons.category),
                _buildSubGrid(),
              ],

              const SizedBox(height: 24),
              _buildSectionHeader('4. Additional Info', Icons.info_outline),
              _buildAdditionalInfo(),

              const SizedBox(height: 24),
              _buildSectionHeader('5. Location Detection', Icons.location_on),
              _buildLocationSection(),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF14B8A6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SUBMIT TO BACKEND', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF14B8A6), size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return InkWell(
      onTap: () => _showPickerOptions(),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF334155)),
          image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
        ),
        child: _image == null 
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo, size: 50, color: Colors.blueGrey[300]),
                const SizedBox(height: 8),
                const Text('Tap to Take Photo', style: TextStyle(color: Colors.grey)),
              ],
            )
          : Stack(
              children: [
                Positioned(
                  right: 10, top: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: _showPickerOptions),
                  ),
                )
              ],
            ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.camera), title: const Text('Camera'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.camera); }),
            ListTile(leading: const Icon(Icons.image), title: const Text('Gallery'), onTap: () { Navigator.pop(c); _pickImage(ImageSource.gallery); }),
          ],
        ),
      ),
    );
  }

  Widget _buildDeptGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _departmentData.keys.length,
      itemBuilder: (context, index) {
        String dept = _departmentData.keys.elementAt(index);
        bool isSelected = _selectedDept == dept;
        return GestureDetector(
          onTap: () => setState(() { _selectedDept = dept; _selectedSub = null; }),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF14B8A6) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFF334155)),
            ),
            child: Text(dept, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        );
      },
    );
  }

  Widget _buildSubGrid() {
    List<String> subs = _departmentData[_selectedDept] ?? [];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: subs.length,
      itemBuilder: (context, index) {
        String sub = subs[index];
        bool isSelected = _selectedSub == sub;
        return GestureDetector(
          onTap: () => setState(() => _selectedSub = sub),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E293B).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFF334155)),
            ),
            child: Text(sub, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        );
      },
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _descController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Describe the issue (Optional)...',
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
                label: Text(_isRecording ? 'Stopping (${_recordDuration}s)' : 'Record Voice Info'),
                style: ElevatedButton.styleFrom(backgroundColor: _isRecording ? Colors.redAccent : Colors.blueGrey),
              ),
            ),
            if (_recordedPath != null) ...[
              const SizedBox(width: 10),
              IconButton(onPressed: _playRecording, icon: const Icon(Icons.play_circle, size: 40, color: Color(0xFF14B8A6))),
              IconButton(onPressed: () => setState(() => _recordedPath = null), icon: const Icon(Icons.delete, color: Colors.red)),
            ]
          ],
        )
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Auto-Fetched Location', style: TextStyle(color: Colors.white70)),
              if (_isFetchingLocation) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else IconButton(onPressed: _determinePosition, icon: const Icon(Icons.refresh, color: Color(0xFF14B8A6))),
            ],
          ),
          const Divider(color: Color(0xFF334155)),
          Row(
            children: [
              _locBox('Latitude', _currentPosition?.latitude.toString() ?? '...'),
              const SizedBox(width: 12),
              _locBox('Longitude', _currentPosition?.longitude.toString() ?? '...'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 120, width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), 
              borderRadius: BorderRadius.circular(10),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&q=80&w=400'), // Placeholder Map
                fit: BoxFit.cover,
                opacity: 0.5
              )
            ),
            child: const Center(child: Icon(Icons.map, color: Colors.white24, size: 50)),
          )
        ],
      ),
    );
  }

  Widget _locBox(String l, String v) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );
}

