import 'package:escoladeingles/models/student_model.dart';
import 'package:escoladeingles/screens/admin_screen.dart';
import 'package:escoladeingles/screens/student_enrollment_screen.dart';
import 'package:escoladeingles/screens/student_home_screen.dart';
import 'package:escoladeingles/screens/teacher_home_screen.dart';
import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/schedule_service.dart';
import 'models/user_model.dart';
import 'models/teacher_model.dart';
import 'models/class_model.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = DatabaseService();
  await dbService.database; 
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escola de Inglês',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => LoginScreen(), 
        '/student-home': (context) {
          final student = ModalRoute.of(context)!.settings.arguments as Student;
          return StudentHomeScreen(student: student);
        },
        '/student-enrollment': (context) {
          final student = ModalRoute.of(context)!.settings.arguments as Student;
          return StudentEnrollmentScreen(student: student);
        },
        '/teacher-home': (context) {
          final teacher = ModalRoute.of(context)!.settings.arguments as Teacher;
          return TeacherHomeScreen(teacher: teacher);
        },
        '/admin': (context) => AdminScreen(),
        '/register':
            (context) => RegisterScreen(
              userType: ModalRoute.of(context)!.settings.arguments as String,
            ),
        '/registration-sent': (context) => CadastroEnviadoScreen(),
      },
      
      onUnknownRoute:
          (settings) => MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
  int _tapCount = 0;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;


  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);


      try {
        final user = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );


        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Email ou senha incorretos')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('fotos/fotoprova.jpg', fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 100),
                    Text(
                      'HELLO WORLD',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 0.8,
                      ),
                    ),
                    Text(
                      'ENGLISH SCHOOL',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'EMAIL',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(44, 255, 255, 255),
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextFormField(
                        controller: _emailController,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Digite seu email' : null,
                        decoration: InputDecoration(
                          hintText: 'HELLO@EXAMPLE.COM',
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'PASSWORD',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(52, 255, 255, 255),
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Digite sua senha' : null,
                        decoration: InputDecoration(border: InputBorder.none),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 50),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              210,
                              198,
                              33,
                            ),
                            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                          ),
                          child:
                              _isLoading
                                  ? CircularProgressIndicator(
                                    color: Colors.black,
                                  )
                                  : Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OpcaoRegistro()),
                          );
                        },
                        child: Text(
                          'REGISTRAR-SE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () {
                          _tapCount++;
                          if (_tapCount >= 3) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminScreen(),
                              ),
                            );
                            _tapCount = 0;
                          }
                        },
                        child: Text(
                          'Acesso Administrativo',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class OpcaoRegistro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('fotos/fotoprova.jpg', fit: BoxFit.cover),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'CADASTRAR-SE',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: Text(
                    'Qual seu tipo de usuário?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 300,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/register',
                          arguments: 'student',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          240,
                          153,
                          39,
                        ),
                        foregroundColor: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ),
                      ),
                      child: Text(
                        'SOU ALUNO',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 300,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/register',
                          arguments: 'teacher',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          240,
                          153,
                          39,
                        ),
                        foregroundColor: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ),
                      ),
                      child: Text(
                        'SOU PROFESSOR(A)',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class RegisterScreen extends StatefulWidget {
  final String userType;


  const RegisterScreen({super.key, required this.userType});


  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}


class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;


  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);


      try {
        final user = await _authService.registerUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
          type: widget.userType,
        );


        if (user != null) {
          Navigator.pushReplacementNamed(context, '/registration-sent');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro no registro: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('fotos/fotoprova.jpg', fit: BoxFit.cover),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 100),
                        Text(
                          'CADASTRAR-SE',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'NOME',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(44, 255, 255, 255),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextFormField(
                            controller: _nameController,
                            validator:
                                (value) =>
                                    value!.isEmpty ? 'Digite seu nome' : null,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'EMAIL',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(44, 255, 255, 255),
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextFormField(
                      controller: _emailController,
                      validator:
                          (value) => value!.isEmpty ? 'Digite seu email' : null,
                      decoration: InputDecoration(border: InputBorder.none),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'TELEFONE',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(44, 255, 255, 255),
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextFormField(
                      controller: _phoneController,
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Digite seu telefone' : null,
                      decoration: InputDecoration(border: InputBorder.none),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SENHA',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(44, 255, 255, 255),
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      validator:
                          (value) => value!.isEmpty ? 'Digite sua senha' : null,
                      decoration: InputDecoration(border: InputBorder.none),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 80),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 250,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            210,
                            198,
                            33,
                          ),
                          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                        ),
                        child:
                            _isLoading
                                ? CircularProgressIndicator(color: Colors.black)
                                : Text(
                                  'CADASTRE-SE',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class CadastroEnviadoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('fotos/fotoprova.jpg', fit: BoxFit.cover),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Seu cadastro foi enviado para análise.\n'
                    'Você será notificado assim que for aprovado.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'THANKS!!!',
                  style: TextStyle(
                    fontSize: 30,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 90),
                SizedBox(
                  width: 250,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 210, 198, 33),
                      foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                    ),
                    child: Text(
                      'OKAY',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class HomeScreen extends StatelessWidget {
  final User user;


  const HomeScreen({super.key, required this.user});


  @override
  Widget build(BuildContext context) {
    if (user.type == 'teacher') {
      final teacher = Teacher(
        id: user.id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        password: '',
        classes: [],
        isApproved: user.isApproved,
      );
      return TeacherHomeScreen(teacher: teacher);
    }


    if (user.type == 'student') {
      final student = Student(
        id: user.id,
        name: user.name,
        email: user.email,
        password: '',
        phone: user.phone,
        level: 'Básico',
        registrationDate: DateTime.now(),
        enrolledClasses: [],
      );
      return StudentHomeScreen(student: student);
    }


    return Scaffold(
      appBar: AppBar(
        title: Text('Bem-vindo, ${user.name}'),
        actions: [
          if (user.type == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.pushNamed(context, '/admin'),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Email: ${user.email}'), Text('Tipo: ${user.type}')],
        ),
      ),
    );
  }
}



