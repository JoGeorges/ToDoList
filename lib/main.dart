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
  void initState() { super.initState(); _navigateAfterDelay(); }
  
  void _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final isLoggedIn = (await SharedPreferences.getInstance()).getBool('isLoggedIn') ?? false;
    Navigator.of(context).pushReplacementNamed(isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [vert, beige], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle, size: 80, color: Colors.white),
        const SizedBox(height: 20),
        const Text('TachFLOW', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 40),
        const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
      ])),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(), _password = TextEditingController();
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _login() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tous les champs sont requis')));
      return;
    }
    if (!_isValidEmail(_email.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Format d\'email invalide')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = prefs.getStringList('users') ?? [];
      bool found = false;
      
      for (var u in users) {
        final user = jsonDecode(u);
        if (user['email'] == _email.text && user['password'] == _password.text) {
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userId', user['id'].toString());
          await prefs.setString('userName', user['name']);
          await prefs.setString('userEmail', user['email']);
          found = true;
          break;
        }
      }
      
      if (found) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }

      final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/users'));
      if (response.statusCode == 200) {
        for (var apiUser in jsonDecode(response.body)) {
          if (apiUser['email'] == _email.text) {
            final newUser = {'id': apiUser['id'].toString(), 'name': apiUser['name'], 'email': apiUser['email'], 'password': _password.text};
            users.add(jsonEncode(newUser));
            await prefs.setStringList('users', users);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('userId', apiUser['id'].toString());
            await prefs.setString('userName', apiUser['name']);
            await prefs.setString('userEmail', apiUser['email']);
            if (!mounted) return;
            Navigator.of(context).pushReplacementNamed('/home');
            return;
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email ou mot de passe incorrect')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: beige,
    appBar: AppBar(title: const Text('TachFLOW'), backgroundColor: vert, centerTitle: false),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_person, size: 60, color: Color(0xFF427A43)),
        const SizedBox(height: 10),
        const Text('KONEKSYON', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF427A43))),
        const SizedBox(height: 40),
        TextField(
          controller: _email, 
          style: TextStyle(color: vert),
          decoration: InputDecoration(
            labelText: 'Imel', 
            labelStyle: TextStyle(color: vert),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)),
            filled: true, 
            fillColor: beige
          )
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _password, 
          style: TextStyle(color: vert),
          decoration: InputDecoration(
            labelText: 'Modpas', 
            labelStyle: TextStyle(color: vert),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)),
            filled: true, 
            fillColor: beige
          ), 
          obscureText: true
        ),
        const SizedBox(height: 30),
        _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _login, child: const Text('Konekte'), style: ElevatedButton.styleFrom(backgroundColor: vert)),
        const SizedBox(height: 20),
        TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen())), child: const Text('Kreye yon kont', style: TextStyle(color: vert))),
      ]),
    ),
  );
  
  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController(), _email = TextEditingController(), _password = TextEditingController();

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _signup() async {
    if (_name.text.isEmpty || _email.text.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tout chan yon obligatwa !')));
      return;
    }
    if (!_isValidEmail(_email.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foma imel la envalid !')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList('users') ?? [];
    
    for (var u in users) {
      if (jsonDecode(u)['email'] == _email.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imel sa deja itilize !')));
        return;
      }
    }
    
    users.add(jsonEncode({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _name.text,
      'email': _email.text,
      'password': _password.text,
    }));
    await prefs.setStringList('users', users);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kont ou an kreye ak sikse !')));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: beige,
    appBar: AppBar(title: const Text('TachFLOW'), backgroundColor: vert, centerTitle: false),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_person, size: 60, color: Color(0xFF427A43)),
        const SizedBox(height: 10),
        const Text('ENSKRIPSYON', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF427A43))),
        const SizedBox(height: 40),
        TextField(
          controller: _name, 
          style: TextStyle(color: vert),
          decoration: InputDecoration(
            labelText: 'Non konple', 
            labelStyle: TextStyle(color: vert),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)),
            filled: true, 
            fillColor: beige
          )
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _email, 
          style: TextStyle(color: vert),
          decoration: InputDecoration(
            labelText: 'Imel', 
            labelStyle: TextStyle(color: vert),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)),
            filled: true, 
            fillColor: beige
          ), 
          keyboardType: TextInputType.emailAddress
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _password, 
          style: TextStyle(color: vert),
          decoration: InputDecoration(
            labelText: 'Modpas', 
            labelStyle: TextStyle(color: vert),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)),
            filled: true, 
            fillColor: beige
          ), 
          obscureText: true
        ),
        const SizedBox(height: 30),
        ElevatedButton(onPressed: _signup, child: const Text('Kreye yon kont'), style: ElevatedButton.styleFrom(backgroundColor: vert)),
      ]),
    ),
  );
  
  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  List<Task> _tasks = [], _completed = [];

  @override
  void initState() { super.initState(); _loadTasks(); }

  void _loadTasks() async {
    final userId = (await SharedPreferences.getInstance()).getString('userId') ?? '1';
    try {
      final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/todos?userId=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _tasks = data.where((t) => !t['completed']).map((t) => Task(id: t['id'], title: t['title'], description: '', startDate: '', endDate: '', completed: false)).toList();
          _completed = data.where((t) => t['completed']).map((t) => Task(id: t['id'], title: t['title'], description: '', startDate: '', endDate: '', completed: true)).toList();
        });
      }
    } catch (e) { print('Ere: $e'); }
  }

  void _logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('isLoggedIn'); await p.remove('userId'); await p.remove('userName'); await p.remove('userEmail');
    if (!mounted) return; Navigator.of(context).pushReplacementNamed('/login');
  }

  void _toggle(Task t) {
    setState(() {
      if (t.completed) {
        _completed.remove(t);
        t.completed = false;
        _tasks.add(t);
      } else {
        _tasks.remove(t);
        t.completed = true;
        _completed.add(t);
      }
    });
  }
  
  void _delete(Task t) => setState(() { _tasks.remove(t); _completed.remove(t); });
  
  void _edit(Task t) {
    final title = TextEditingController(text: t.title), desc = TextEditingController(text: t.description);
    final start = TextEditingController(text: t.startDate), end = TextEditingController(text: t.endDate);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: beige,
      title: const Text('Modifye', style: TextStyle(color: vert)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, style: TextStyle(color: vert), decoration: InputDecoration(labelText: 'Tit tach', labelStyle: TextStyle(color: vert), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)), filled: true, fillColor: beige)),
        const SizedBox(height: 10),
        TextField(controller: desc, style: TextStyle(color: vert), decoration: InputDecoration(labelText: 'Deskripsyon', labelStyle: TextStyle(color: vert), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)), filled: true, fillColor: beige)),
        const SizedBox(height: 10),
        TextField(controller: start, style: TextStyle(color: vert), decoration: InputDecoration(labelText: 'Dat komansman', labelStyle: TextStyle(color: vert), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)), filled: true, fillColor: beige), readOnly: true, onTap: () async {
          DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (picked != null) start.text = "${picked.day}/${picked.month}/${picked.year}";
        }),
        const SizedBox(height: 10),
        TextField(controller: end, style: TextStyle(color: vert), decoration: InputDecoration(labelText: 'Dat fen', labelStyle: TextStyle(color: vert), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)), filled: true, fillColor: beige), readOnly: true, onTap: () async {
          DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (picked != null) end.text = "${picked.day}/${picked.month}/${picked.year}";
        }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anile', style: TextStyle(color: vert))), 
                TextButton(onPressed: () { setState(() { t.title = title.text; t.description = desc.text; t.startDate = start.text; t.endDate = end.text; }); Navigator.pop(context); }, child: const Text('Sauvegarder', style: TextStyle(color: vert)))],
    ));
  }

  void _add() {
    final title = TextEditingController(), desc = TextEditingController(), start = TextEditingController(), end = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: beige,
      title: const Text('Ajoute', style: TextStyle(color: vert)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, style: TextStyle(color: vert), decoration: InputDecoration(labelText: 'Tit tach', labelStyle: TextStyle(color: vert), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)), filled: true, fillColor: beige)),
        const SizedBox(height: 10),
        TextField(controller: desc, style: TextStyle(color: vert), decoration: InputDecoration(labelText: 'Deskripsyon', labelStyle: TextStyle(color: vert), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)), filled: true, fillColor: beige)),
        const SizedBox(height: 10),
        TextField(controller: start, style: TextStyle(color: vert), decoration: InputDecoration(labelText: 'Dat komansman', labelStyle: TextStyle(color: vert), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)), filled: true, fillColor: beige), readOnly: true, onTap: () async {
          DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (picked != null) start.text = "${picked.day}/${picked.month}/${picked.year}";
        }),
        const SizedBox(height: 10),
        TextField(controller: end, style: TextStyle(color: vert), decoration: InputDecoration(labelText: 'Dat fen', labelStyle: TextStyle(color: vert), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: vert, width: 2)), filled: true, fillColor: beige), readOnly: true, onTap: () async {
          DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (picked != null) end.text = "${picked.day}/${picked.month}/${picked.year}";
        }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anile', style: TextStyle(color: vert))), 
                TextButton(onPressed: () { if (title.text.isNotEmpty) setState(() => _tasks.add(Task(id: _tasks.length+1, title: title.text, description: desc.text, startDate: start.text, endDate: end.text, completed: false))); Navigator.pop(context); }, child: const Text('Ajoute', style: TextStyle(color: vert)))],
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: beige,
    appBar: AppBar(title: const Text('TachFLOW'), backgroundColor: vert,
           actions: _index == 0 ? [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)] : null),
    body: [
      TaskListScreen(tasks: _tasks, onToggle: _toggle, onDelete: _delete, onEdit: _edit, onAdd: _add),
      CompletedTasksScreen(tasks: _completed, onToggle: _toggle),
      const ProfileScreen()
    ][_index],
    bottomNavigationBar: BottomNavigationBar(currentIndex: _index, onTap: (i) => setState(() => _index = i), 
      backgroundColor: vert,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.add_home_outlined), label: 'Tach'),
        BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Konplete'),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: 'Pwofil'),
      ]),
  );
}

class TaskListScreen extends StatelessWidget {
  final List<Task> tasks; final Function(Task) onToggle, onDelete, onEdit; final Function() onAdd;
  const TaskListScreen({required this.tasks, required this.onToggle, required this.onDelete, required this.onEdit, required this.onAdd});
  
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: beige,
    body: tasks.isEmpty 
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_off, size: 80, color: vert),
              const SizedBox(height: 16),
              const Text('Pa genyen okenn tach !'),
            ],
          ),
        )
      : Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (c, i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: vert, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: CircleAvatar(child: Text('${i+1}'), backgroundColor: vert),
                title: Text(tasks[i].title), 
                subtitle: Text(tasks[i].description),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => onEdit(tasks[i])),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => onDelete(tasks[i])),
                  Checkbox(value: tasks[i].completed, onChanged: (_) => onToggle(tasks[i]), activeColor: vert),
                ]),
              ),
            ),
          ),
        ),
    floatingActionButton: FloatingActionButton(onPressed: onAdd, child: const Icon(Icons.add), backgroundColor: vert),
  );
}

class CompletedTasksScreen extends StatelessWidget {
  final List<Task> tasks; final Function(Task) onToggle;
  const CompletedTasksScreen({required this.tasks, required this.onToggle});
  
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: beige,
    body: tasks.isEmpty 
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_off, size: 80, color: vert),
              const SizedBox(height: 16),
              const Text('Pa genyen okenn tach !'),
            ],
          ),
        )
      : Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (c, i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: vert, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: CircleAvatar(child: Text('${i+1}'), backgroundColor: vert),
                title: Text(tasks[i].title, style: const TextStyle(decoration: TextDecoration.lineThrough)),
                subtitle: Text(tasks[i].description, style: const TextStyle(decoration: TextDecoration.lineThrough)),
                trailing: Checkbox(value: tasks[i].completed, onChanged: (_) => onToggle(tasks[i]), activeColor: vert),
              ),
            ),
          ),
        ),
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '', _email = '';

  @override
  void initState() { super.initState(); _load(); }
  
  void _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() { 
      _name = p.getString('userName') ?? ''; 
      _email = p.getString('userEmail') ?? ''; 
    });
  }

  void _logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('isLoggedIn'); await p.remove('userId'); await p.remove('userName'); await p.remove('userEmail');
    if (!mounted) return; Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _deleteAccount() => showDialog(context: context, builder: (_) => AlertDialog(
    backgroundColor: beige,
    title: const Text('Konfime', style: TextStyle(color: vert)),
    content: const Text('Siprime kont lan ?', style: TextStyle(color: vert)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anile', style: TextStyle(color: vert))),
      TextButton(onPressed: () async {
        final p = await SharedPreferences.getInstance();
        final email = p.getString('userEmail');
        if (email != null) {
          final users = p.getStringList('users') ?? [];
          users.removeWhere((u) => jsonDecode(u)['email'] == email);
          await p.setStringList('users', users);
        }
        await p.remove('isLoggedIn'); await p.remove('userId'); await p.remove('userName'); await p.remove('userEmail');
        if (!mounted) return; Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }, child: const Text('Siprime', style: TextStyle(color: vert))),
    ],
  ));

  @override
  Widget build(BuildContext context) => Scaffold(
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
              child: Icon(Icons.person_pin, size: 100, color: vert),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Row(
              children: [
                Icon(Icons.person, color: vert, size: 30),
                const SizedBox(width: 15),
                Text('Non: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vert)),
                Text(_name, style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Row(
              children: [
                Icon(Icons.email, color: vert, size: 30),
                const SizedBox(width: 15),
                Text('Imel: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vert)),
                Text(_email, style: const TextStyle(fontSize: 18)),
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

class Task {
  int id; String title, description, startDate, endDate; bool completed;
  Task({required this.id, required this.title, required this.description, required this.startDate, required this.endDate, required this.completed});
}

class TodoAppWithRoutes extends StatelessWidget {
  const TodoAppWithRoutes({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TACH ',
    theme: ThemeData(primarySwatch: Colors.green, scaffoldBackgroundColor: beige),
    home: const SplashScreen(),
    routes: {'/login': (c) => const LoginScreen(), '/home': (c) => const HomeScreen()},
    debugShowCheckedModeBanner: false
  );
}
