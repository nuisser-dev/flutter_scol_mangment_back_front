import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:tp70/entities/absence.dart';
import 'package:tp70/entities/classe.dart';
import 'package:tp70/entities/matier.dart';
import 'package:tp70/screen/studentsscreen.dart';

class Absence_count_Screen extends StatefulWidget {
  @override
  AbsenceScreenState createState() => AbsenceScreenState();
}

class AbsenceScreenState extends State<Absence_count_Screen> {
  List<Classe> classes = [];
  Classe? selectedClass;
  Matier? selectedMatier;
  DateTime? startDate;
  DateTime? endDate;
  Map<Absence, double> emptyMap = Map<Absence, double>();

  @override
  void initState() {
    super.initState();
    getAllClasses().then((result) {
      setState(() {
        classes = result;
      });
    });
  }

  Future<void> fetchAbsencesByMatiereIdAndDateRange(
      Matier? matier, DateTime? startDate, DateTime? endDate) async {
    if (matier != null && startDate != null && endDate != null) {
      try {
        final url = Uri.parse(
            'http://10.0.2.2:8088/absence/getByMatiereId/${matier.matiereId}');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final List<dynamic> responseData = json.decode(response.body);
          final List<Absence> fetchedAbsences =
              responseData.map((absence) => Absence.fromJson(absence)).toList();

          List<Absence> filteredAbsences = fetchedAbsences.where((absence) {
            DateTime? parsedDate = DateTime.tryParse(absence.date!);
            return parsedDate != null &&
                parsedDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                parsedDate.isBefore(endDate.add(Duration(days: 1)));
          }).toList();

          double sum = 0;
          for (Absence i in filteredAbsences) {
            sum = sum + i.absenceNb!;
          }
          for (Absence i in filteredAbsences) {
            emptyMap[i] = (i.absenceNb! / sum) * 100;
          }

          showEmptyMapDataDialog();

          if (filteredAbsences.isEmpty) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('No Absences'),
                  content: Text(
                      'There are no absences within the selected date range.'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }
        } else {
          print('Failed to fetch absences: ${response.statusCode}');
        }
      } catch (error) {
        print('Error fetching absences: $error');
      }
    } else {
      print('Select a Matier and Date Range');
    }
  }

  void showEmptyMapDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('table of absent student with pourcentage of the absences'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: emptyMap.entries.map((entry) {
                Absence absence = entry.key;
                double value = entry.value;
                String studentName =
                    '${absence.etudiant?.nom ?? "Unknown"} ${absence.etudiant?.prenom ?? ""}';
                return ListTile(
                  title: Text('Student Name: $studentName'),
                  subtitle: Text('poucentage for absences %: $value'),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Absences Management'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Classe>(
              value: selectedClass,
              onChanged: (Classe? value) {
                setState(() {
                  selectedClass = value;
                  selectedMatier = null;
                });
              },
              items: classes.map((Classe classe) {
                return DropdownMenuItem<Classe>(
                  value: classe,
                  child: Text(classe.nomClass),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: "Select a Class"),
            ),
            const SizedBox(height: 20),
            if (selectedClass != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<Matier>(
                    value: selectedMatier,
                    onChanged: (Matier? value) async {
                      setState(() {
                        selectedMatier = value;
                      });

                      if (selectedMatier != null &&
                          startDate != null &&
                          endDate != null) {
                        await fetchAbsencesByMatiereIdAndDateRange(
                            selectedMatier!, startDate!, endDate!);
                      }
                    },
                    items: selectedClass!.matieres?.map((Matier matier) {
                          return DropdownMenuItem<Matier>(
                            value: matier,
                            child: Text(matier.matiereName),
                          );
                        }).toList() ??
                        [],
                    decoration:
                        const InputDecoration(labelText: "Select a Matier"),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null) {
                            setState(() {
                              startDate = pickedDate;
                            });
                          }
                        },
                        child: Text(startDate != null
                            ? 'Start Date: ${DateFormat('yyyy-MM-dd').format(startDate!)}'
                            : 'Select Start Date'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null) {
                            setState(() {
                              endDate = pickedDate;
                            });
                          }
                        },
                        child: Text(endDate != null
                            ? 'End Date: ${DateFormat('yyyy-MM-dd').format(endDate!)}'
                            : 'Select End Date'),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (startDate != null && endDate != null) {
                        if (startDate!.isAfter(endDate!)) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Invalid Date Range'),
                                content: Text(
                                    'Start date cannot be after the end date.'),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('OK'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          if (selectedMatier != null) {
                            await fetchAbsencesByMatiereIdAndDateRange(
                                selectedMatier!, startDate!, endDate!);
                          }
                        }
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Select Dates'),
                              content: Text(
                                  'Please select both start and end dates.'),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: Text('Fetch Data'),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purpleAccent,
        onPressed: () async {
          // Add functionality for the FAB here
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
