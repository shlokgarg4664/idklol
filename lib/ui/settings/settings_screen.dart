import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sports_app/ui/theme/theme_controller.dart';
import 'package:sports_app/core/developer_credentials.dart';
import 'package:sports_app/core/user_service.dart';
import 'package:sports_app/ui/settings/profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  int _secretTapCount = 0;
  bool _isDeveloperMode = false;
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _userService.addListener(_onUserServiceChanged);
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserServiceChanged);
    super.dispose();
  }

  void _onUserServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkMode = prefs.getBool('dark_mode') ?? true);
  }

  Future<void> _saveTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    await ThemeController.instance.setDarkMode(value);
  }

  void _handleSecretTap() {
    setState(() {
      _secretTapCount++;
    });
    
    if (_secretTapCount >= 7) {
      _showDeveloperLogin();
      _secretTapCount = 0;
    }
    
    // Reset counter after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _secretTapCount = 0;
        });
      }
    });
  }

  void _showDeveloperLogin() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (await DeveloperCredentials.validateCredentials(
                usernameController.text,
                passwordController.text,
              )) {
                setState(() {
                  _isDeveloperMode = true;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔓 Developer mode activated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Invalid credentials'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Secret tap area for developer access (invisible)
          GestureDetector(
            onTap: _handleSecretTap,
            child: Container(
              height: 60,
              color: Colors.transparent,
            ),
          ),
          // User profile section
          if (_userService.currentUser != null) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  _userService.userInitials,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(_userService.displayName),
              subtitle: Text(_userService.currentUser!.email),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen(),
                  ),
                );
              },
            ),
            const Divider(),
          ],
          
          SwitchListTile(
            title: const Text('Dark mode'),
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              _saveTheme(v);
            },
          ),
          const Divider(),
          if (_isDeveloperMode) ...[
            ListTile(
              leading: const Icon(Icons.developer_mode, color: Colors.orange),
              title: const Text('Developer Mode'),
              subtitle: const Text('Video upload & AI testing'),
              trailing: const Icon(Icons.verified_user, color: Colors.green),
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await _userService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Sports App v1.0.0'),
          ),
        ],
      ),
    );
  }
}
