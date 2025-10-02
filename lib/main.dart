import 'package:everyday/models/goal.dart';
import 'package:everyday/providers/goal_provider.dart';
import 'package:everyday/providers/theme_provider.dart';
import 'package:everyday/screens/add_edit_goal_screen.dart';
import 'package:everyday/screens/stats_page.dart';
import 'package:everyday/services/google_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(FrequencyTypeAdapter());

  await Hive.openBox<Goal>('goals_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => GoogleAuthService()),
        ChangeNotifierProxyProvider<GoogleAuthService, GoalProvider>(
          create: (_) => GoalProvider(),
          update: (_, auth, previousGoals) => previousGoals!..setAuth(auth),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Everyday',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
            ),
            themeMode: themeProvider.themeMode,
            home: const MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  Color _getGoalStatusColor(Goal goal) {
    if (goal.isCompletedForToday) {
      return Colors.green;
    }
    if (goal.wasCompletedInPreviousPeriod) {
      return Colors.yellow;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Goals'),
        actions: [
          Consumer<GoalProvider>(
            builder: (context, goalProvider, child) {
              if (goalProvider.isSyncing) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Consumer<GoogleAuthService>(
            builder: (context, authService, child) {
              if (authService.currentUser == null) {
                return IconButton(
                  icon: const Icon(Icons.login),
                  onPressed: () => authService.signIn(),
                  tooltip: 'Sign in with Google',
                );
              } else {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      authService.signOut();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem(
                        value: 'logout',
                        child: Text('Sign Out'),
                      ),
                    ];
                  },
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(authService.currentUser!.photoUrl ?? ''),
                    radius: 16,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const StatsPage(),
              ));
            },
          ),
        ],
      ),
      body: Consumer<GoalProvider>(
        builder: (context, goalProvider, child) {
          if (goalProvider.goals.isEmpty) {
            return const Center(
              child: Text(
                'No goals yet. Tap the + button to add one!',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: goalProvider.goals.length,
            itemBuilder: (context, index) {
              final goal = goalProvider.goals[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getGoalStatusColor(goal),
                ),
                title: Text(goal.name),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () {
                    goalProvider.toggleGoalCompletion(goal, DateTime.now());
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddEditGoalScreen(goal: goal),
                  ));
                },
                onLongPress: () {
                  // Optional: Add a confirmation dialog before deleting
                  goalProvider.deleteGoal(goal);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const AddEditGoalScreen(),
          ));
        },
        tooltip: 'Add Goal',
        child: const Icon(Icons.add),
      ),
    );
  }
}