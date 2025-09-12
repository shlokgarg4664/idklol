import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sports_app/core/user_service.dart';

class HomeWelcomeScreen extends StatelessWidget {
  const HomeWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userService = UserService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          // User avatar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                userService.userInitials,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userService.displayName,
                    style: GoogleFonts.firaCode(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready for your next workout?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats section
            if (userService.userStats != null) ...[
              Text(
                'Your Progress',
                style: GoogleFonts.firaCode(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    title: 'Total Workouts',
                    value: userService.userStats!.totalWorkouts.toString(),
                    icon: Icons.fitness_center,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Pushups Done',
                    value: userService.userStats!.totalPushups.toString(),
                    icon: Icons.sports_handball,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'Calories Burned',
                    value: userService.userStats!.totalCalories.toStringAsFixed(0),
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Total Time',
                    value: '${(userService.userStats!.totalDuration / 60).toStringAsFixed(0)}m',
                    icon: Icons.timer,
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // User info section
            if (userService.currentUser != null) ...[
              Text(
                'Profile Summary',
                style: GoogleFonts.firaCode(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _ProfileRow(
                      icon: Icons.height,
                      label: 'Height',
                      value: '${userService.currentUser!.height.toStringAsFixed(0)} cm',
                    ),
                    const SizedBox(height: 12),
                    _ProfileRow(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Weight',
                      value: '${userService.currentUser!.weight.toStringAsFixed(1)} kg',
                    ),
                    const SizedBox(height: 12),
                    _ProfileRow(
                      icon: Icons.calculate_outlined,
                      label: 'BMI',
                      value: '${userService.bmi.toStringAsFixed(1)} (${userService.bmiCategory})',
                    ),
                    if (userService.currentUser!.nationality.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ProfileRow(
                        icon: Icons.flag_outlined,
                        label: 'Nationality',
                        value: userService.currentUser!.nationality,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Quick actions
            Text(
              'Quick Actions',
              style: GoogleFonts.firaCode(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to Testing tab
                      DefaultTabController.of(context).animateTo(1);
                    },
                    icon: const Icon(Icons.directions_run),
                    label: const Text('Start Workout'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to Settings tab
                      DefaultTabController.of(context).animateTo(2);
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.firaCode(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
