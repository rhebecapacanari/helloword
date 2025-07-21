import 'package:escoladeingles/main.dart';
import 'package:escoladeingles/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class_model.dart';
import '../services/schedule_service.dart';
import '../models/teacher_model.dart';
import '../services/auth_service.dart';


class TeacherHomeScreen extends StatefulWidget {
  final Teacher teacher;


  const TeacherHomeScreen({Key? key, required this.teacher}) : super(key: key);


  @override
  _TeacherHomeScreenState createState() => _TeacherHomeScreenState();
}


class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  final AuthService _authService = AuthService();
  List<ClassSchedule> _schedules = [];
  bool _isLoading = true;
  bool _isDeleteMode = false;
  List<String> _selectedSchedules = [];
  ClassSchedule? _scheduleToEdit;


  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }


  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await _scheduleService.getTeacherSchedules(
        widget.teacher.id.toString(),
      );
      schedules.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        return a.startTime.compareTo(b.startTime);
      });
      setState(() => _schedules = schedules);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar aulas: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _deleteSelectedSchedules() async {
    if (_selectedSchedules.isEmpty) return;


    try {
      for (final id in _selectedSchedules) {
        await _scheduleService.deleteClassSchedule(id);
      }
      await _loadSchedules();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedSchedules.length} aulas removidas com sucesso!',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao remover aulas: $e')));
    } finally {
      setState(() {
        _selectedSchedules.clear();
        _isDeleteMode = false;
      });
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


  void _showAddClassDialog() {
    _showClassDialog(isEditing: false);
  }


  void _showEditClassDialog(ClassSchedule schedule) {
    _scheduleToEdit = schedule;
    _showClassDialog(isEditing: true);
  }


  void _showClassDialog({required bool isEditing}) {
    final _formKey = GlobalKey<FormState>();
    final _classNameController = TextEditingController(
      text: isEditing ? _scheduleToEdit?.className ?? '' : '',
    );
    final _descriptionController = TextEditingController(
      text: isEditing ? _scheduleToEdit?.description ?? '' : '',
    );
    String _selectedDay = isEditing ? _scheduleToEdit!.dayOfWeek : 'Segunda';
    TimeOfDay _selectedTime =
        isEditing
            ? TimeOfDay(
              hour: int.parse(_scheduleToEdit!.startTime.split(':')[0]),
              minute: int.parse(_scheduleToEdit!.startTime.split(':')[1]),
            )
            : const TimeOfDay(hour: 9, minute: 0);
    DateTime _selectedDate =
        isEditing
            ? _scheduleToEdit!.date
            : DateTime.now().add(const Duration(days: 1));
    List<String> _selectedClasses =
        isEditing ? List.from(_scheduleToEdit!.classes) : ['A1'];


    final availableClasses = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];


    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(isEditing ? 'Editar Aula' : 'Adicionar Nova Aula'),
                content: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _classNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da Aula*',
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição (opcional)',
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedDay,
                          items:
                              ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta']
                                  .map(
                                    (day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(day),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setState(() => _selectedDay = value!),
                          decoration: const InputDecoration(
                            labelText: 'Dia da Semana*',
                          ),
                        ),
                        ListTile(
                          title: const Text('Data da Aula*'),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                        ),
                        ListTile(
                          title: const Text('Horário*'),
                          subtitle: Text(_selectedTime.format(context)),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (time != null) {
                              setState(() => _selectedTime = time);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Turmas*', style: TextStyle(fontSize: 16)),
                        Wrap(
                          spacing: 8,
                          children:
                              availableClasses.map((classItem) {
                                final isSelected = _selectedClasses.contains(
                                  classItem,
                                );
                                return FilterChip(
                                  label: Text(classItem),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedClasses.add(classItem);
                                      } else {
                                        _selectedClasses.remove(classItem);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                        if (_selectedClasses.isEmpty)
                          const Text(
                            'Selecione pelo menos uma turma',
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _scheduleToEdit = null;
                      Navigator.pop(context);
                    },
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (_selectedClasses.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Selecione pelo menos uma turma'),
                            ),
                          );
                          return;
                        }


                        final schedule = ClassSchedule(
                          id:
                              isEditing
                                  ? _scheduleToEdit!.id
                                  : DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                          teacherId: widget.teacher.id.toString(),
                          dayOfWeek: _selectedDay,
                          date: _selectedDate,
                          startTime:
                              '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          className: _classNameController.text,
                          description:
                              _descriptionController.text.isNotEmpty
                                  ? _descriptionController.text
                                  : null,
                          classes: _selectedClasses,
                        );


                        try {
                          if (isEditing) {
                            await _scheduleService.updateClassSchedule(
                              schedule,
                            );
                          } else {
                            await _scheduleService.addClassSchedule(schedule);
                          }
                          await _loadSchedules();
                          _scheduleToEdit = null;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Aula ${isEditing ? 'atualizada' : 'adicionada'} com sucesso!',
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao ${isEditing ? 'atualizar' : 'adicionar'} aula: $e',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(isEditing ? 'Atualizar' : 'Salvar'),
                  ),
                ],
              );
            },
          ),
    );
  }


  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remover Aulas'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isDeleteMode = true;
                    _selectedSchedules.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecione as aulas que deseja remover'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar Aula'),
                onTap: () {
                  Navigator.pop(context);
                  _showSelectClassToEdit();
                },
              ),
            ],
          ),
    );
  }


  void _showSelectClassToEdit() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Selecione a aula para editar'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  final schedule = _schedules[index];
                  return ListTile(
                    title: Text(schedule.className),
                    subtitle: Text(
                      '${schedule.dayOfWeek} - ${DateFormat('dd/MM').format(schedule.date)} às ${_formatTime(schedule.startTime)}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditClassDialog(schedule);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }


  Widget _buildScheduleTable() {
    if (_schedules.isEmpty) {
      return const Center(child: Text('Nenhuma aula agendada',
      style: TextStyle(color: Colors.white, fontSize: 20)
      )
      );
    }


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.blue[100]),
        dataRowColor: MaterialStateProperty.all(Colors.white),
        columns: [
          if (_isDeleteMode) const DataColumn(label: Text('Select')),
          const DataColumn(label: Text('Day')),
          const DataColumn(label: Text('Date')),
          const DataColumn(label: Text('Time')),
          const DataColumn(label: Text('Class')),
        ],
        rows:
            _schedules.map((schedule) {
              return DataRow(
                cells: [
                  if (_isDeleteMode)
                    DataCell(
                      Checkbox(
                        value: _selectedSchedules.contains(schedule.id),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedSchedules.add(schedule.id);
                            } else {
                              _selectedSchedules.remove(schedule.id);
                            }
                          });
                        },
                      ),
                    ),
                  DataCell(Text(schedule.dayOfWeek)),
                  DataCell(Text('${schedule.date.day}/${schedule.date.month}')),
                  DataCell(Text(_formatTime(schedule.startTime))),
                  DataCell(Text(schedule.classes.join(', '))),
                ],
              );
            }).toList(),
      ),
      )
    );
  }


  Future<void> _performLogout(BuildContext context) async {
    try {
      await _authService.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao sair: $e')));
    }
  }


  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Saída'),
            content: const Text('Tem certeza que deseja sair do aplicativo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performLogout(context);
                },
                child: const Text('Sair', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }


  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurações'),
                onTap: () {
                  Navigator.pop(ctx);
                  
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Sair'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmLogout(context);
                },
              ),
            ],
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
        title: Text('HELLO, ${widget.teacher.name.toUpperCase()}',
         style: const TextStyle( 
    color: Colors.white,
    fontWeight: FontWeight.bold,
  ),
  ),
        actions: [
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
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Check your class schedule',
                           textAlign: TextAlign.center,
                             style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(child: _buildScheduleTable()),
                      ],
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child:
                  _isDeleteMode
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed:
                                _selectedSchedules.isEmpty
                                    ? null
                                    : () {
                                      _deleteSelectedSchedules();
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 255, 19, 2),
                            ),
                            child: const Text('Confirmar Exclusão',
                                style: TextStyle(
                              color: Colors.white
                                )
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isDeleteMode = false;
                                _selectedSchedules.clear();
                              });
                            },
                            child: const Text('Cancelar', 
                            style: TextStyle(
                              color: Colors.white
                            ),
                            ),
                          ),
                        ],
                      )
                      : ElevatedButton.icon(
                        onPressed: () => _showEditOptions(context),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar Aulas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 210, 198, 33),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
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
               builder: (context) => EditProfileScreen(teacher: widget.teacher),
      ),
    );
  },
),
          ],
        ),
      ),
    )
      ]
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

class EditProfileScreen extends StatefulWidget {
  final Teacher teacher;

  const EditProfileScreen({super.key, required this.teacher});
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
    _nameController.text = widget.teacher.name;
    _emailController.text = widget.teacher.email;
    _phoneController.text = widget.teacher.phone;
    _passwordController.text = widget.teacher.password;
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
      final updatedUser = Teacher(
        id: widget.teacher.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        classes: widget.teacher.classes,
       // level: widget.teacher.level,
        //registrationDate: widget.teacher.registrationDate,
        isApproved: widget.teacher.isApproved,
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
            builder: (context) => TeacherHomeScreen(teacher: widget.teacher),
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