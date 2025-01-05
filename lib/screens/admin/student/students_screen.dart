import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({Key? key}) : super(key: key);

  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentCodeController = TextEditingController();

  QuerySnapshot? students;
  List<QueryDocumentSnapshot<Object?>>? filteredStudents;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> getStudents() async {
    students = await FirebaseFirestore.instance
        .collection('students')
        .where('deleted_at', isNull: true)
        .get();
    setState(() {
      filteredStudents = students?.docs;
    });
  }

  void getFilteredStudents(String value) {
    if (value.isEmpty) {
      setState(() {
        filteredStudents = students?.docs;
      });
      return;
    }

    setState(() {
      filteredStudents = students?.docs
          .where((doc) =>
              doc['name']
                  .toString()
                  .toLowerCase()
                  .contains(value.toLowerCase()) ||
              doc['studentCode']
                  .toString()
                  .toLowerCase()
                  .contains(value.toLowerCase()))
          .toList();
    });
  }

  Future<void> softDeleteStudent(String studentId) async {
    await FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .update({'deleted_at': FieldValue.serverTimestamp()});
    final userDocs = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: studentId)
        .get();
    for (var element in userDocs.docs) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(element.id)
          .update({'deleted_at': FieldValue.serverTimestamp()});
    }
    refresh();
  }

  Future<void> addStudent(String name, String studentCode) async {
    try {
      if (name.isEmpty || studentCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name and student code are required.'),
          ),
        );
        return;
      }
      if (studentCode.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student code must be 10 characters long.'),
          ),
        );
        return;
      }
      final student = await FirebaseFirestore.instance
          .collection('students')
          .where('studentCode', isEqualTo: studentCode)
          .get();
      if (student.docs.isNotEmpty) return;

      await FirebaseFirestore.instance.collection('students').add({
        'name': name,
        'studentCode': studentCode,
        'created_at': FieldValue.serverTimestamp(),
        'deleted_at': null,
      });
      await FirebaseFirestore.instance.collection('users').add({
        'email': null,
        'username': studentCode,
        'role': 'student',
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print(e);
    }
    refresh();
  }

  void refresh() {
    getStudents();
    getFilteredStudents(_searchController.text);
  }

  Future<void> importStudentsFromExcel() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true, // Make sure to get the file data
      );

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
        return;
      }

      final PlatformFile file = result.files.first;
      final Uint8List? bytes = file.bytes;

      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read file')),
        );
        return;
      }

      // Decode Excel
      final excel = Excel.decodeBytes(bytes);

      // Get first sheet
      final String? firstTable = excel.tables.keys.firstOrNull;
      if (firstTable == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel file is empty')),
        );
        return;
      }

      final sheet = excel.tables[firstTable]!;
      final rows = sheet.rows;

      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data found in sheet')),
        );
        return;
      }

      // Process each row
      int successCount = 0;
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 2) continue;

        final studentCode = row[0]?.value?.toString().trim() ?? '';
        final name = row[1]?.value?.toString().trim() ?? '';

        if (name.isNotEmpty && studentCode.isNotEmpty) {
          await addStudent(name, studentCode);
          successCount++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully imported $successCount students')),
      );
    } catch (e) {
      print('Excel import error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Error importing students. Please check the file format.')),
      );
    } finally {
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              onSubmitted: getFilteredStudents,
              controller: _searchController,
              decoration: const InputDecoration(
                  hintText: 'Search students', border: InputBorder.none),
            ),
          ),
        ),
      ),
      body: filteredStudents == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: filteredStudents!.length,
              itemBuilder: (context, index) {
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(filteredStudents![index]['name']),
                    subtitle: Text(filteredStudents![index]['studentCode']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _nameController.text =
                                filteredStudents![index]['name'];
                            _studentCodeController.text =
                                filteredStudents![index]['studentCode'];

                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Edit Student'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                          labelText: 'Name'),
                                    ),
                                    TextField(
                                      controller: _studentCodeController,
                                      decoration: const InputDecoration(
                                          labelText: 'Student Code'),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      _nameController.clear();
                                      _studentCodeController.clear();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('students')
                                          .doc(filteredStudents![index].id)
                                          .update({
                                        'name': _nameController.text,
                                        'studentCode':
                                            _studentCodeController.text,
                                      });
                                      _nameController.clear();
                                      _studentCodeController.clear();
                                      Navigator.pop(context);
                                      refresh();
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Student'),
                                content: const Text(
                                    'Are you sure you want to delete this student?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      softDeleteStudent(
                                          filteredStudents![index].id);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Add Student'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // button import students from excel
                    ElevatedButton(
                      onPressed: importStudentsFromExcel,
                      child: const Text('Import Students from Excel'),
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Name'),
                    ),
                    TextField(
                      // chỉ cho phép nhập số
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        // giới hạn số ký tự nhập vào
                        LengthLimitingTextInputFormatter(10),
                      ],
                      keyboardType: TextInputType.number,
                      controller: _studentCodeController,
                      decoration:
                          const InputDecoration(hintText: 'Student Code'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _nameController.clear();
                      _studentCodeController.clear();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      addStudent(
                          _nameController.text, _studentCodeController.text);
                      _nameController.clear();
                      _studentCodeController.clear();
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
