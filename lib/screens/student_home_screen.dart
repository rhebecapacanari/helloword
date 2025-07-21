import 'package:escoladeingles/main.dart';
import 'package:escoladeingles/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../services/enrollment_service.dart';
import 'student_enrollment_screen.dart';
import 'assignment_upload_screen.dart'; 


class StudentHomeScreen extends StatefulWidget {
  final Student student;


  const StudentHomeScreen({Key? key, required this.student}) : super(key: key);


  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}


class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  List<ClassSchedule> _enrolledClasses = [];
  bool _isLoading = true;
  String _errorMessage = '';


  @override
  void initState() {
    super.initState();
    _loadEnrolledClasses();
  }


  Future<void> _loadEnrolledClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });


    try {
      final classes = await _enrollmentService.getStudentEnrolledClasses(
        widget.student.id.toString(),
      );


      classes.sort((a, b) {
        final dayOrder = {
          'Segunda': 1,
          'Terça': 2,
          'Quarta': 3,
          'Quinta': 4,
          'Sexta': 5,
          'Sábado': 6,
          'Domingo': 7,
        };


        final dayCompare = (dayOrder[a.dayOfWeek] ?? 8).compareTo(
          dayOrder[b.dayOfWeek] ?? 8,
        );
        if (dayCompare != 0) return dayCompare;


        return a.startTime.compareTo(b.startTime);
      });


      setState(() {
        _enrolledClasses = classes;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar aulas matriculadas: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _unenrollFromClass(String classId) async {
    setState(() => _isLoading = true);
    try {
      
      final enrollments = await _enrollmentService
          .getEnrollmentsByClassAndStudent(
            classId,
            widget.student.id.toString(),
          );


      if (enrollments.isEmpty) {
        throw Exception('Matrícula não encontrada');
      }


      
      final success = await _enrollmentService.cancelEnrollment(
        enrollments.first.id,
      );


      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desmatrícula realizada com sucesso!')),
        );
        await _loadEnrolledClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao realizar desmatrícula')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }


  String _formatTime(String time) {
    try {
      final parsedTime = DateFormat('HH:mm').parse(time);
      return DateFormat('h:mm a').format(parsedTime);
    } catch (e) {
      return time;
    }
  }


  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (Route<dynamic> route) => false,
    );
  }


  void _showProfile(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Meu Perfil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nome: ${widget.student.name}'),
                Text('Email: ${widget.student.email}'),
                Text('Nível: ${widget.student.level}'),
                Text(
                  'Matriculado em: ${DateFormat('dd/MM/yyyy').format(widget.student.registrationDate)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Fechar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }


  
  void _navigateToAssignmentUpload(BuildContext context) {
    if (_enrolledClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não está matriculado em nenhuma aula'),
        ),
      );
      return;
    }


    
    final classItem = _enrolledClasses.first;


    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AssignmentUploadScreen(
              studentId: widget.student.id.toString(),
              studentName: widget.student.name,
              classId: classItem.id,
              className: classItem.className,
              teacherId: classItem.teacherId,
            ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'fotos/fundoinicial.jpg',
            fit: BoxFit.cover,
          ),
        ),
      Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 183, 59, 98),
        title: Text('HELLO, ${widget.student.name}',
         style: const TextStyle( 
    color: Colors.white,
    fontWeight: FontWeight.bold,
  ),
  ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEnrolledClasses,
          ),
        

          /*PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (String result) {
              switch (result) {
                case 'logout':
                  _logout(context);
                  break;
                case 'profile':
                  _showProfile(context);
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Text('Meu Perfil'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Sair'),
                  ),
                ],
          ),*/
         Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),
          ],
        ),
      endDrawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 183, 59, 98),
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About School'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SchoolInformationScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 210, 198, 33),
                          foregroundColor: Colors.black,
        onPressed: () => _navigateToAssignmentUpload(context),
        child: const Icon(Icons.upload_file),
        tooltip: 'Enviar Trabalho',
      ),
      body: Column(
  children: [
    const SizedBox(height: 40),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            'Check your class\nschedule:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ), 
     const SizedBox(height: 16),
      Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _enrolledClasses.isEmpty
                  ? const Center(
                      child: Text(
                        'Você não está matriculado em nenhuma aula',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    )
                    
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.blue[100]),
                        dataRowColor: MaterialStateProperty.all(Colors.white),
                        columns: const [
                          DataColumn(label: Text('Day')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Time')),
                      DataColumn(label: Text('Class')),
                          DataColumn(label: Text('Teacher')),
                          DataColumn(label: Text('Ações')),
                        ],
                        rows: _enrolledClasses.map((classItem) {
                          return DataRow(
                            cells: [
                              DataCell(Text(classItem.dayOfWeek)),
                              DataCell(Text(
                                  '${classItem.date.day}/${classItem.date.month}')),
                              DataCell(Text(_formatTime(classItem.startTime))),
                              DataCell(Text(classItem.className)),
                              DataCell(
                                FutureBuilder<String>(
                                  future: _getTeacherName(classItem.teacherId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    }
                                    return Text(snapshot.data ?? 'Professor');
                                  },
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(
                                    Icons.exit_to_app,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _showUnenrollDialog(classItem.id),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
    ),
    Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  StudentEnrollmentScreen(student: widget.student),
            ),
          ).then((_) => _loadEnrolledClasses());
        },
        style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 210, 198, 33),
      foregroundColor: Colors.black,
    ),
        child: const Text('Matricular em Novas Aulas'),
      ),
    ),
  ],
),

      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 23, 61, 131),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.school, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: () {}),
            IconButton(
  icon: const Icon(Icons.person,color: Colors.white),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(student: widget.student),
      ),
    );
  },
),
          ],
        ),
      ),
    ),
      ]
    );
  }


  Future<void> _showUnenrollDialog(String classId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Desmatrícula'),
          content: const Text(
            'Tem certeza que deseja se desmatricular desta aula?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _unenrollFromClass(classId);
              },
            ),
          ],
        );
      },
    );
  }


  Future<String> _getTeacherName(String teacherId) async {
    
    return 'Professor $teacherId';
  }
}


class EditProfileScreen extends StatefulWidget {
  final Student student;

  const EditProfileScreen({super.key, required this.student});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  
  final _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.student.name;
    _emailController.text = widget.student.email;
    _phoneController.text = widget.student.phone;
    _passwordController.text = widget.student.password;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedUser = Student(
        id: widget.student.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        level: widget.student.level,
        registrationDate: widget.student.registrationDate,
        isApproved: widget.student.isApproved,
      );

      try {
        await _databaseService.updateUser(updatedUser);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentHomeScreen(student: widget.student),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar perfil: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Edit Profile',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 183, 59, 98),
        ),
        backgroundColor: const Color.fromARGB(255, 166, 116, 150),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  decoration: const InputDecoration(labelText: 'Name', 
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Digite seu nome' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  decoration: const InputDecoration(labelText: 'Email',
                     labelStyle: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Digite seu email' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  decoration: const InputDecoration(labelText: 'Phone',
                   labelStyle: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Digite seu telefone' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password',
                   labelStyle: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Digite sua senha' : null,
                ),
                const SizedBox(height: 40),
                Center(
                  child: SizedBox(
                    width: 170,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 210, 198, 33),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        'SAVE',
                        style: TextStyle(
                            fontSize: 23, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SchoolInformationScreen extends StatelessWidget {
  const SchoolInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('School Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 183, 59, 98),
      ),
     backgroundColor: const Color.fromARGB(255, 166, 116, 150),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.location_on,
                size: 100,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              const SizedBox(height: 16),
              const Text(
                'Campus Boituva',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(221, 255, 255, 255),
                ),
              ),
              const SizedBox(height: 32),
              const InfoRow(
                label: 'ADDRESS',
                value: 'Street X, 20 - Boituva/SP',
              ),
              const SizedBox(height: 16),
              const InfoRow(
                label: 'PHONE',
                value: '(15) 99999-0000',
              ),
              const SizedBox(height: 16),
              const InfoRow(
                label: 'EMAIL',
                value: 'englishschool@email.com',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            color: Color.fromARGB(221, 230, 230, 230),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
