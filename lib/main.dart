import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(const TodoAppWithRoutes());

const Color vert = Color(0xFF427A43);
const Color beige = Color(0xFFE8E2DB);

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }
  
  void _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    Navigator.of(context).pushReplacementNamed(
      isLoggedIn ? '/home' : '/login'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [beige, vert],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 200,
                backgroundImage: AssetImage('assets/images/picture1.png'),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Tout chan yo obligatwa !');
      return;
    }
    
    if (!_isValidEmail(_emailController.text)) {
      _showSnackBar('Foma imel la envalid !');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final users = prefs.getStringList('users') ?? [];
      
      if (await _checkLocalUser(users, prefs)) return;
      if (await _checkApiUser(users, prefs)) return;
      
      _showSnackBar('Imel oswa modpas la enkorek !');
    } catch (e) {
      _showSnackBar('Ere: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkLocalUser(List<String> users, SharedPreferences prefs) async {
    for (var userJson in users) {
      final user = jsonDecode(userJson);
      if (user['email'] == _emailController.text && 
          user['password'] == _passwordController.text) {
        await _saveUserSession(prefs, user['id'].toString(), user['name'], user['email']);
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
        return true;
      }
    }
    return false;
  }

  Future<bool> _checkApiUser(List<String> users, SharedPreferences prefs) async {
    final response = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/users')
    );
    
    if (response.statusCode != 200) return false;

    final apiUsers = jsonDecode(response.body) as List;
    for (var apiUser in apiUsers) {
      if (apiUser['email'] == _emailController.text) {
        final newUser = {
          'id': apiUser['id'].toString(),
          'name': apiUser['name'],
          'email': apiUser['email'],
          'password': _passwordController.text,
        };
        
        users.add(jsonEncode(newUser));
        await prefs.setStringList('users', users);
        await _saveUserSession(
          prefs, 
          apiUser['id'].toString(), 
          apiUser['name'], 
          apiUser['email']
        );
        
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
        return true;
      }
    }
    return false;
  }

  Future<void> _saveUserSession(
    SharedPreferences prefs, 
    String userId, 
    String userName, 
    String userEmail
  ) async {
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', userId);
    await prefs.setString('userName', userName);
    await prefs.setString('userEmail', userEmail);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        title: const Text(
          'TachFLOW',
          style: TextStyle(
            fontSize: 18,
            color: beige,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: vert,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 60, color: Color(0xFF427A43)),
            const SizedBox(height: 10),
            const Text(
              'KONEKSYON',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF427A43),
              ),
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _emailController,
              label: 'Adres imel',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _passwordController,
              label: 'Modpas',
              isPassword: true,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Konekte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vert,
                      foregroundColor: beige,
                    ),
                  ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignupScreen())
              ),
              child: const Text(
                'Ou pa gen kont ? Kreye yon kont',
                style: TextStyle(color: vert),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: vert),
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: vert),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: vert),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: vert, width: 2),
        ),
        filled: true,
        fillColor: beige,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);
  
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  Future<void> _signup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar('Tout chan yon obligatwa !');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _showSnackBar('Foma imel la envalid !');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList('users') ?? [];

    for (var userJson in users) {
      final user = jsonDecode(userJson);
      if (user['email'] == _emailController.text) {
        _showSnackBar('Imel sa deja itilize !');
        return;
      }
    }

    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    users.add(jsonEncode(newUser));
    await prefs.setStringList('users', users);
    
    _showSnackBar('Kont ou an kreye ak sikse !');
    
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        title: const Text(
          'TachFLOW',
          style: TextStyle(
            fontSize: 18,
            color: beige,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: vert,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 60, color: Color(0xFF427A43)),
            const SizedBox(height: 10),
            const Text(
              'ENSKRIPSYON',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF427A43),
              ),
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _nameController,
              label: 'Non konple',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              label: 'Adres imel',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _passwordController,
              label: 'Modpas',
              isPassword: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _signup,
              child: const Text('Kreye yon kont'),
              style: ElevatedButton.styleFrom(
                backgroundColor: vert,
                foregroundColor: beige,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: vert),
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: vert),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: vert),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: vert, width: 2),
        ),
        filled: true,
        fillColor: beige,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Task> _tasks = [];
  List<Task> _completedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '1';

    try {
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos?userId=$userId')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _tasks = data
              .where((task) => !task['completed'])
              .map((task) => Task(
                    id: task['id'],
                    title: task['title'],
                    description: '',
                    startDate: '',
                    endDate: '',
                    completed: false,
                  ))
              .toList();
          
          _completedTasks = data
              .where((task) => task['completed'])
              .map((task) => Task(
                    id: task['id'],
                    title: task['title'],
                    description: '',
                    startDate: '',
                    endDate: '',
                    completed: true,
                  ))
              .toList();
        });
      }
    } catch (e) {
      print('Ere: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _toggleTask(Task task) {
    setState(() {
      if (task.completed) {
        _completedTasks.remove(task);
        task.completed = false;
        _tasks.add(task);
      } else {
        _tasks.remove(task);
        task.completed = true;
        _completedTasks.add(task);
      }
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
      _completedTasks.remove(task);
    });
  }

  void _editTask(Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    final startController = TextEditingController(text: task.startDate);
    final endController = TextEditingController(text: task.endDate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: beige,
        title: const Text(
          'Modifye',
          style: TextStyle(color: vert, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              controller: titleController,
              label: 'Tit tach',
            ),
            const SizedBox(height: 10),
            _buildDialogTextField(
              controller: descController,
              label: 'Deskripsyon',
            ),
            const SizedBox(height: 10),
            _buildDateField(
              controller: startController,
              label: 'Dat komansman',
            ),
            const SizedBox(height: 10),
            _buildDateField(
              controller: endController,
              label: 'Dat fen',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Anile',
              style: TextStyle(color: vert, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                task.title = titleController.text;
                task.description = descController.text;
                task.startDate = startController.text;
                task.endDate = endController.text;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Anrejistre',
              style: TextStyle(
                color: vert,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTask() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: beige,
        title: const Text(
          'Ajoute',
          style: TextStyle(color: vert, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              controller: titleController,
              label: 'Tit tach',
            ),
            const SizedBox(height: 10),
            _buildDialogTextField(
              controller: descController,
              label: 'Deskripsyon',
            ),
            const SizedBox(height: 10),
            _buildDateField(
              controller: startController,
              label: 'Dat komansman',
            ),
            const SizedBox(height: 10),
            _buildDateField(
              controller: endController,
              label: 'Dat fen',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Anile',
              style: TextStyle(color: vert, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  _tasks.add(Task(
                    id: _tasks.length + 1,
                    title: titleController.text,
                    description: descController.text,
                    startDate: startController.text,
                    endDate: endController.text,
                    completed: false,
                  ));
                });
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Ajoute',
              style: TextStyle(
                color: vert,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: vert, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: vert, fontSize: 15),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: vert),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: vert, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: vert, fontSize: 15),
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text = "${picked.day}/${picked.month}/${picked.year}";
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: vert, fontSize: 15),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: vert),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: vert, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      TaskListScreen(
        tasks: _tasks,
        onToggle: _toggleTask,
        onDelete: _deleteTask,
        onEdit: _editTask,
        onAdd: _addTask,
      ),
      CompletedTasksScreen(
        tasks: _completedTasks,
        onToggle: _toggleTask,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        title: const Text(
          'TachFLOW',
          style: TextStyle(
            fontSize: 18,
            color: beige,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: vert,
        actions: _currentIndex == 0
            ? [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)]
            : null,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: vert,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_home_outlined),
            label: 'Tach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Konplete',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Pwofil',
          ),
        ],
      ),
    );
  }
}

class TaskListScreen extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onToggle;
  final Function(Task) onDelete;
  final Function(Task) onEdit;
  final Function() onAdd;

  const TaskListScreen({
    required this.tasks,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 80, color: vert),
                  const SizedBox(height: 15),
                  const Text(
                    'Pa genyen okenn tach !',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: vert, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                        backgroundColor: vert,
                      ),
                      title: Text(task.title),
                      subtitle: Text(task.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => onEdit(task),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => onDelete(task),
                          ),
                          Checkbox(
                            value: task.completed,
                            onChanged: (_) => onToggle(task),
                            activeColor: vert,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        child: const Icon(Icons.add),
        backgroundColor: vert,
      ),
    );
  }
}

class CompletedTasksScreen extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onToggle;

  const CompletedTasksScreen({
    required this.tasks,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 80, color: vert),
                  const SizedBox(height: 15),
                  const Text(
                    'Pa genyen okenn tach !',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: vert, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                        backgroundColor: vert,
                      ),
                      title: Text(
                        task.title,
                        style: const TextStyle(decoration: TextDecoration.lineThrough),
                      ),
                      subtitle: Text(
                        task.description,
                        style: const TextStyle(decoration: TextDecoration.lineThrough),
                      ),
                      trailing: Checkbox(
                        value: task.completed,
                        onChanged: (_) => onToggle(task),
                        activeColor: vert,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('userName') ?? '';
      _email = prefs.getString('userEmail') ?? '';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: beige,
        title: const Text(
          'Konfime',
          style: TextStyle(color: vert),
        ),
        content: const Text(
          'Siprime kont lan ?',
          style: TextStyle(color: vert),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Anile',
              style: TextStyle(color: vert),
            ),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final email = prefs.getString('userEmail');
              
              if (email != null) {
                final users = prefs.getStringList('users') ?? [];
                users.removeWhere((userJson) {
                  final user = jsonDecode(userJson);
                  return user['email'] == email;
                });
                await prefs.setStringList('users', users);
              }
              
              await prefs.remove('isLoggedIn');
              await prefs.remove('userId');
              await prefs.remove('userName');
              await prefs.remove('userEmail');
              
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text(
              'Siprime',
              style: TextStyle(color: vert),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.transparent,
                child: Icon(Icons.person_pin, size: 80, color: vert),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Icon(Icons.person_pin, color: vert, size: 30),
                  const SizedBox(width: 15),
                  Text(
                    'Non: ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: vert,
                    ),
                  ),
                  Text(
                    _name,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Icon(Icons.email, color: vert, size: 30),
                  const SizedBox(width: 15),
                  Text(
                    'Imel: ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: vert,
                    ),
                  ),
                  Text(
                    _email,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Dekoneksyon'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vert,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 200,
                    child: OutlinedButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete),
                      label: const Text('Siprime kont lan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: vert,
                        side: BorderSide(color: vert, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class Task {
  int id;
  String title;
  String description;
  String startDate;
  String endDate;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.completed,
  });
}

class TodoAppWithRoutes extends StatelessWidget {
  const TodoAppWithRoutes({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TachFLOW',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: beige,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}