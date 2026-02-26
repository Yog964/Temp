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
        final token = data['access_token'];
        print("DEBUG: Login successful. Token: ${token.substring(0, 10)}...");
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        
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
    HelpView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E293B),
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_vote_rounded), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF14B8A6),
        unselectedItemColor: Colors.white54,
        onTap: (i) => setState(() => _selectedIndex = i),
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
      if (userRes.statusCode == 401) {
        _handleUnauthorized();
        return;
      }
      
      if (userRes.statusCode == 200) {
        setState(() => _userName = json.decode(userRes.body)['name']);
      }

      final complaintRes = await http.get(Uri.parse('$baseUrl/complaints/me'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
      if (complaintRes.statusCode == 401) {
        _handleUnauthorized();
        return;
      }
      
      if (complaintRes.statusCode == 200) {
        setState(() {
          _myComplaints = json.decode(complaintRes.body);
          _myComplaints.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
        });
      }
    } catch (e) {
      print('Error fetching home data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session expired. Please login again.')));
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
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportIssuePage())),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_a_photo, color: Color(0xFF14B8A6)),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Report an Issue', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Take a photo and help the city', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Your Recent Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchData,
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _myComplaints.isEmpty 
                    ? const Center(child: Text('No reports yet. Click "Report an Issue" above.'))
                    : ListView.builder(
                        itemCount: _myComplaints.length,
                        itemBuilder: (context, index) {
                          final item = _myComplaints[index];
                          return _buildReportCard(item);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(dynamic item) {
    final status = item['status'] ?? 'Pending';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Resolved':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'In Progress':
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.loop;
        break;
      case 'Rejected':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.hourglass_empty;
    }

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ComplaintDetailPage(complaint: item))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage('$baseUrl/${item['image_url']}'),
              fit: BoxFit.cover,
              onError: (e, s) => {},
            ),
          ),
          child: item['image_url'] == null ? const Icon(Icons.image) : null,
        ),
        title: Text(item['issue_type'] ?? 'Issue Report', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }
}

class ComplaintDetailPage extends StatelessWidget {
  final dynamic complaint;
  const ComplaintDetailPage({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final status = complaint['status'] ?? 'Pending';
    final date = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(complaint['created_at']));

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                '$baseUrl/${complaint['image_url']}',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, size: 50)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(complaint['issue_type'] ?? 'Grievance', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('ID: COMP-${complaint['id']}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                          ],
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const Divider(height: 40, color: Colors.white12),
                  _buildDetailRow(Icons.business, 'Department', complaint['department'] ?? 'General'),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.calendar_today, 'Reported On', date),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.location_on, 'Location', '${complaint['latitude']}, ${complaint['longitude']}'),
                  
                  const SizedBox(height: 32),
                  const Text('Updates & Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Timeline view for updates
                  _buildTimelineItem(
                    'Complaint Registered',
                    'Your report has been successfully recorded in our system.',
                    date,
                    isFirst: true,
                    isLast: status == 'Pending',
                    isDone: true,
                  ),
                  if (status != 'Pending')
                    _buildTimelineItem(
                      'Admin Review',
                      'The local administration has reviewed your request.',
                      'Updated by System',
                      isLast: status == 'In Progress',
                      isDone: status != 'Pending',
                    ),
                  if (status == 'Resolved')
                    _buildTimelineItem(
                      'Issue Resolved',
                      'The department has completed the assigned task. Final validation success.',
                      'Resolution Success',
                      isLast: true,
                      isDone: true,
                      color: const Color(0xFF10B981),
                    ),
                  if (status == 'Rejected')
                    _buildTimelineItem(
                      'Request Rejected',
                      'This report does not meet the necessary criteria or is a duplicate.',
                      'Review Complete',
                      isLast: true,
                      isDone: true,
                      color: const Color(0xFFEF4444),
                    ),

                  const SizedBox(height: 32),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      complaint['description'] ?? 'No description provided.',
                      style: const TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = const Color(0xFFF59E0B);
    if (status == 'Resolved') color = const Color(0xFF10B981);
    if (status == 'Rejected') color = const Color(0xFFEF4444);
    if (status == 'In Progress') color = const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF14B8A6)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String desc, String time, {bool isFirst = false, bool isLast = false, bool isDone = false, Color? color}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? (color ?? const Color(0xFF14B8A6)) : Colors.white12,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.white12)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDone ? Colors.white : Colors.white38)),
                    Text(time, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 13, color: isDone ? Colors.white70 : Colors.white24)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
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
    if (_image == null && _recordedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide at least a Photo or a Voice Recording')));
      return;
    }

    if (_selectedDept == null || _selectedSub == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Department and Subcategory')));
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waiting for GPS coordinates... Please wait a moment.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      print("DEBUG: Token retrieved: ${token != null ? 'YES' : 'NO'}");

      // 1. Upload Image (if exists)
      String? imageUrl;
      if (_image != null) {
        print("DEBUG: Uploading image: ${_image!.path}");
        var imgReq = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/'));
        imgReq.files.add(await http.MultipartFile.fromPath('file', _image!.path));
        var imgRes = await imgReq.send().timeout(const Duration(seconds: 30));
        
        if (imgRes.statusCode != 200) {
          throw 'Image upload failed with status: ${imgRes.statusCode}';
        }
        
        var imgData = json.decode(await imgRes.stream.bytesToString());
        imageUrl = imgData['image_url'];
        print("DEBUG: Image uploaded: $imageUrl");
      }

      // 2. Upload Voice (if exists)
      String? voiceUrl;
      if (_recordedPath != null) {
        print("DEBUG: Uploading voice: $_recordedPath");
        var voiceReq = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/'));
        voiceReq.files.add(await http.MultipartFile.fromPath('file', _recordedPath!));
        var voiceRes = await voiceReq.send().timeout(const Duration(seconds: 30));
        
        if (voiceRes.statusCode == 200) {
          var voiceData = json.decode(await voiceRes.stream.bytesToString());
          voiceUrl = voiceData['image_url'];
          print("DEBUG: Voice uploaded: $voiceUrl");
        }
      }

      // 3. Submit Complaint
      print("DEBUG: Submitting complaint to $baseUrl/complaints/");
      final res = await http.post(
        Uri.parse('$baseUrl/complaints/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': '$_selectedSub at ${_selectedDept}',
          'description': _descController.text.isEmpty ? 'Reported Issue' : _descController.text,
          'image_url': imageUrl ?? '',
          'voice_url': voiceUrl,
          'latitude': _currentPosition?.latitude ?? 0.0,
          'longitude': _currentPosition?.longitude ?? 0.0,
          'department': _selectedDept,
          'subcategory': _selectedSub,
        }),
      ).timeout(const Duration(seconds: 20));

      print("DEBUG: Complaint response: ${res.statusCode}");
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else if (res.statusCode == 401) {
        _handleUnauthorizedReport();
      } else {
        var errorMsg = res.body;
        try {
          var errorData = json.decode(res.body);
          errorMsg = errorData['detail'] ?? res.body;
        } catch (_) {}
        throw 'Submission failed (${res.statusCode}): $errorMsg';
      }
    } catch (e) {
      print("DEBUG: Submission Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleUnauthorizedReport() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session expired. Please login again.')));
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
            _buildSectionHeader('1. Voice Recording (Optional)', Icons.mic),
            _buildVoiceSection(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('2. Photo Upload (Optional)', Icons.camera_alt),
            _buildPhotoSection(),
            const SizedBox(height: 12),
            const Text('* Provide at least Photo or Voice', style: TextStyle(color: Colors.white54, fontSize: 12)),
            
            if (_image != null || _recordedPath != null) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('3. Select Department', Icons.business),
              _buildDeptGrid(),
              
              if (_selectedDept != null) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('4. Select Subcategory', Icons.category),
                _buildSubGrid(),
              ],

              const SizedBox(height: 24),
              _buildSectionHeader('5. Additional Info', Icons.info_outline),
              _buildAdditionalInfo(),

              const SizedBox(height: 24),
              _buildSectionHeader('6. Location Detection', Icons.location_on),
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

  Widget _buildVoiceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF334155))),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
              label: Text(_isRecording ? 'Stopping (${_recordDuration}s)' : 'Record Voice Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.redAccent : const Color(0xFF334155),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (_recordedPath != null) ...[
            const SizedBox(width: 10),
            IconButton(onPressed: _playRecording, icon: const Icon(Icons.play_circle, size: 40, color: Color(0xFF14B8A6))),
            IconButton(onPressed: () => setState(() => _recordedPath = null), icon: const Icon(Icons.delete, color: Colors.red)),
          ]
        ],
      ),
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


class HelpView extends StatefulWidget {
  const HelpView({super.key});

  @override
  State<HelpView> createState() => _HelpViewState();
}

class _HelpViewState extends State<HelpView> {
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'content': 'Hello! I am your UrbanSathi AI assistant. How can I help you today? You can ask me about your complaint status or how to use the app.'}
  ];
  final _controller = TextEditingController();
  bool _isTyping = false;
  final String _geminiApiKey = 'AIzaSyBXX09gmHe4sBKXjM2ESGCbS6vkemQQZuI';
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isTyping = true;
      _controller.clear();
    });
    
    _scrollToBottom();

    try {
      // Get context about user's complaints
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      String complaintContext = "";
      
      try {
        final res = await http.get(Uri.parse('$baseUrl/complaints/me'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final List complaints = json.decode(res.body);
          if (complaints.isNotEmpty) {
            complaintContext = "\nUser's Current Complaints:\n" + complaints.map((c) => "- ID: ${c['id']}, Title: ${c['title']}, Status: ${c['status']}").join("\n");
          } else {
             complaintContext = "\nThe user has absolutely no reported complaints at the moment.";
          }
        }
      } catch (_) {}

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": "You are UrbanSathi AI, a helpful assistant for a civic grievance reporting app (like identifying potholes, water leaks). Be polite, very concise, and directly address the user's issue.\n$complaintContext\n\nUser Question: $userMessage"
              }
            ]
          }
        ]
      };

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiText = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add({'role': 'ai', 'content': aiText});
        });
      } else {
        setState(() {
          _messages.add({'role': 'ai', 'content': 'Sorry, I am having trouble connecting to my brain right now.'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'content': 'Error: Could not reach AI services. Please check your internet connection.'});
      });
    } finally {
      if (mounted) setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('AI Help & Support'),
          elevation: 0,
          backgroundColor: const Color(0xFF0F172A),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() => _messages.removeRange(1, _messages.length));
              },
              tooltip: 'Clear Chat',
            )
          ],
        ),
        Expanded(
          child: Container(
            color: const Color(0xFF0F172A),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _buildChatBubble(msg['role'] == 'user', msg['content']!);
              },
            ),
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatBubble(bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF14B8A6) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
        child: const Text('AI is thinking...', style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), 
        border: Border(top: BorderSide(color: Color(0xFF334155)))
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ask about your complaints...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF14B8A6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), 
                onPressed: _sendMessage
              ),
            )
          ],
        ),
      ),
    );
  }
}
