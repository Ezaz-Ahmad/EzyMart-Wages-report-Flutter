import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:open_file/open_file.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Hours and Wages Calculator for Ezymart',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 5), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MainScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtain screen size and orientation
    var screenSize = MediaQuery.of(context).size;
    var orientation = MediaQuery.of(context).orientation;

    // Adjust text size based on screen size and orientation
    double textSize = orientation == Orientation.portrait
        ? screenSize.width * 0.05 // Smaller text in portrait mode
        : screenSize.width * 0.04; // Slightly larger text in landscape mode

    // Ensure text size is not too small on larger screens
    textSize = textSize.clamp(18.0, 32.0);

    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              'Welcome to the EzyMart Wages Calculator',
              textStyle: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              speed: Duration(milliseconds: 100),
            ),
          ],
          totalRepeatCount: 1,
          pause: Duration(milliseconds: 1000),
        ),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    // Adjust font size based on screen width
    double fontSize = screenSize.width * 0.02;
    fontSize = fontSize.clamp(
        12.0, 18.0); // Ensure font size is within a reasonable range

    return Scaffold(
      body: Stack(
        children: <Widget>[
          WorkHoursCalculator(), // main app content
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Container(
              alignment: Alignment.bottomCenter,
              child: Text(
                'Developed by Ezaz Ahmad. Version: 1.0.2V',
                style: TextStyle(fontSize: fontSize, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkHoursCalculator extends StatefulWidget {
  @override
  _WorkHoursCalculatorState createState() => _WorkHoursCalculatorState();
}

class WageDetail {
  String day;
  List<ShiftDetail> shifts;
  double earnings;

  WageDetail({
    required this.day,
    required this.shifts,
    this.earnings = 0.0,
  });
}

class ShiftDetail {
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String location;

  ShiftDetail({
    this.startTime,
    this.endTime,
    this.location = 'Gosford',
  });
}

List<WageDetail> _wageDetails = [];

class _WorkHoursCalculatorState extends State<WorkHoursCalculator> {
  Future<void> _saveAsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          double totalHoursGosford = 0;
          double totalHoursIslington = 0;
          double totalHoursAdamstown = 0;
          double totalEarnings = 0;

          // Calculate total hours and earnings for all shifts
          _wageDetails.forEach((wageDetail) {
            wageDetail.shifts.forEach((shift) {
              double duration =
                  _calculateDuration(shift.startTime, shift.endTime);
              double earnings = duration *
                  _getHourlyRate(
                      shift.location, wageDetail.day, shift.startTime);

              // Sum up hours and earnings based on location
              switch (shift.location) {
                case 'Gosford':
                  totalHoursGosford += duration;
                  break;
                case 'Islington':
                  totalHoursIslington += duration;
                  break;
                case 'Adamstown':
                  totalHoursAdamstown += duration;
                  break;
              }

              totalEarnings += earnings;
            });
          });

          return pw.Column(
            children: [
              pw.Text(
                'EzyMart Work Hours and Wages Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor(0.0, 0.0, 0.55),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Date: $_date',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red,
                ),
              ), // Adds space after the title
              pw.Text(
                'Employee Name: $_employeeName',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.Text('Employee Address: $_employeeAddress'),
              pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 10)),
              ..._wageDetails.expand((wageDetail) {
                return wageDetail.shifts.map((shift) {
                  String startTime = _formatTimeOfDay(shift.startTime);
                  String endTime = _formatTimeOfDay(shift.endTime);
                  double duration =
                      _calculateDuration(shift.startTime, shift.endTime);

                  return pw.Text(
                      '${wageDetail.day}: Start - $startTime, End - $endTime, Location - ${shift.location}, Hours: ${duration.toStringAsFixed(2)}, Earnings - \$${(duration * _getHourlyRate(shift.location, wageDetail.day, shift.startTime)).toStringAsFixed(2)}');
                });
              }).toList(),
              pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 10)),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Gosford Weekdays Hourly Rate: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(
                      text: '\$${_gosfordWeekdayRate.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Gosford Weekends Hourly Rate: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(
                      text: '\$${_gosfordWeekendRate.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Islington Weekdays Hourly Rate: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(
                      text: '\$${_islingtonRate.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Adamstown Weekdays Hourly Rate: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(
                      text: '\$${_adamstownRate.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Fuel Cost per Trip to Gosford: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(
                      text: '\$${_fuelCost.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Other /covered shift: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(
                      text: '\$${others.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Expense Explanation: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.TextSpan(
                      text: expenseExplanation,
                    ),
                  ],
                ),
              ),
              pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 10)),
              pw.Text(
                  'Total Hours in Gosford (Weekdays): $_totalHoursGosfordWeekday'),
              pw.Text(
                  'Total Hours in Gosford (Weekends): $_totalHoursGosfordWeekend'),
              pw.Text('Total Hours in Islington: $_totalHoursIslington'),
              pw.Text('Total Hours in Adamstown: $_totalHoursadamstown'),
              pw.Text(
                  'Fuel Cost for Gosford: \$${_totalFuelCost.toStringAsFixed(2)}'),
              pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 10)),
              pw.Text(
                  'Grand Total Wages (Before deducting TAX amount): \$${_grandtotalbeforeTax.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  )),
              pw.Text('Amount Paid on Tax: \$${_taxAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  )),
              pw.Text(
                  'Grand Total Wages (After deducting TAX amount): \$${_grandTotalWages.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  )),
              pw.Spacer(), // Use Spacer to push the footer to the bottom
              // Footer text (developer signature)
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Developed by Ezaz Ahmad. Version: 1.0.2V',
                  style: pw.TextStyle(
                    fontSize: 12, // Smaller font size for footer
                    color: PdfColors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save the document
    await savePdfFile(pdf);
  }

//working with saving the PDF file both android and windows platform
  Future<void> savePdfFile(pw.Document pdf) async {
    String directoryPath;
    File file;

    try {
      if (Platform.isAndroid) {
        // Check and request permission
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
        directoryPath = '/storage/emulated/0/Download';
      } else {
        // For desktop platforms, use the path_provider package
        final downloadsDirectory = await getDownloadsDirectory();
        directoryPath = downloadsDirectory?.path ?? '';
      }

      // Create the file path
      file = File('$directoryPath/${_employeeName}_WagesReport.pdf');

      // Write the file
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved in $directoryPath')),
      );
      // Open the file after saving
      OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: $e')),
      );
    }
  }

  double _calculateDuration(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return 0.0;

    final today = DateTime.now();
    final startTime =
        DateTime(today.year, today.month, today.day, start.hour, start.minute);
    var endTime =
        DateTime(today.year, today.month, today.day, end.hour, end.minute);

    if (endTime.isBefore(startTime)) {
      endTime = endTime.add(Duration(days: 1));
    }

    return endTime.difference(startTime).inMinutes / 60.0;
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Not Set';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

  final _formKey = GlobalKey<FormState>();
  Map<String, bool> _workedDays = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };
  // New variables for employee details
  String _date = '';
  String _employeeName = '';
  String _employeeAddress = '';

  Map<String, TimeOfDay?> _startTime = {};
  Map<String, TimeOfDay?> _endTime = {};
  Map<String, String> _locations = {};
  double _gosfordWeekdayRate = 0;
  double _gosfordWeekendRate = 0;
  double _islingtonRate = 0;
  double _adamstownRate = 0; //for adamstown
  double _fuelCost = 0;
  double _taxAmount = 0; // New variable for tax amount
  double _totalHoursGosfordWeekday = 0;
  double _totalHoursGosfordWeekend = 0;
  double _totalHoursIslington = 0;
  double _totalHoursadamstown = 0; //for adamstown
  double _totalFuelCost = 0;
  double _grandTotalWages = 0;
  double _grandtotalbeforeTax = 0;
  double others = 0;
  String expenseExplanation = '';
  bool isExpenseExplanationEnabled = false;

  TextEditingController _dateController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (var day in _workedDays.keys) {
      _startTime[day] = null;
      _endTime[day] = null;
      _locations[day] = 'Gosford'; // Default value
    }
  }

  void _pickTime(BuildContext context, String day, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime[day] = picked;
        } else {
          _endTime[day] = picked;
        }
      });
    }
  }

  // Initialize _wageDetails with every day having an empty list of shifts
  List<WageDetail> _wageDetails = List.generate(
      7,
      (index) => WageDetail(
          day: DateFormat('EEEE')
              .format(DateTime.now().add(Duration(days: index))),
          shifts: []));

  void _addNewShift(String day) {
    setState(() {
      final wageDetail = _wageDetails.firstWhere((detail) => detail.day == day);
      wageDetail.shifts.add(ShiftDetail());
    });
  }

  double _getHourlyRate(String location, String day, TimeOfDay? startTime) {
    bool isWeekend = (day == 'Friday') || // Entire Friday
        (day == 'Saturday') || // Entire Saturday
        (day == 'Sunday' &&
            (startTime == null || startTime.hour < 6)); // Sunday until 6:00 AM

    if (location == 'Gosford') {
      return isWeekend ? _gosfordWeekendRate : _gosfordWeekdayRate;
    } else if (location == 'Islington') {
      return _islingtonRate;
    } else if (location == 'Adamstown') {
      return _adamstownRate;
    }
    return 0.0; // Default rate if location is not recognized
  }

  void _calculateWages() {
    _totalHoursGosfordWeekday = 0;
    _totalHoursGosfordWeekend = 0;
    _totalHoursIslington = 0;
    _totalHoursadamstown = 0;
    _totalFuelCost = 0;
    _grandTotalWages = 0;

    // Iterate over each day's wage details
    for (var wageDetail in _wageDetails) {
      double dailyWages = 0.0;

      // Iterate over each shift for the current day
      for (var shift in wageDetail.shifts) {
        if (shift.startTime != null && shift.endTime != null) {
          DateTime startDateTime =
              DateTime(0, 0, 0, shift.startTime!.hour, shift.startTime!.minute);
          DateTime endDateTime =
              DateTime(0, 0, 0, shift.endTime!.hour, shift.endTime!.minute);

          if (endDateTime.isBefore(startDateTime)) {
            endDateTime = endDateTime.add(Duration(days: 1));
          }

          double duration =
              endDateTime.difference(startDateTime).inMinutes / 60.0;
          double hourlyRate;
          bool isWeekend = (wageDetail.day == 'Friday') || // Entire Friday
              (wageDetail.day == 'Saturday') || // Entire Saturday
              (wageDetail.day == 'Sunday' &&
                  shift.startTime!.hour < 6); // Sunday until 6:00 AM

          // Set the hourly rate based on location
          switch (shift.location) {
            case 'Gosford':
              hourlyRate =
                  isWeekend ? _gosfordWeekendRate : _gosfordWeekdayRate;
              _totalFuelCost += _fuelCost;
              break;
            case 'Islington':
              hourlyRate = _islingtonRate;
              break;
            case 'Adamstown':
              hourlyRate = _adamstownRate;
              break;
            default:
              hourlyRate = 0.0; // Default rate if location is not recognized
              break;
          }

          // Calculate and sum wages for each shift
          dailyWages += hourlyRate * duration;

          // Sum up total hours for the report based on location and weekend
          if (isWeekend) {
            _totalHoursGosfordWeekend += duration;
          } else {
            switch (shift.location) {
              case 'Gosford':
                _totalHoursGosfordWeekday += duration;
                break;
              case 'Islington':
                _totalHoursIslington += duration;
                break;
              case 'Adamstown':
                _totalHoursadamstown += duration;
                break;
            }
          }
        }
      }

      // Update the earnings for the current day
      wageDetail.earnings += dailyWages;

      // Sum up the grand total wages
      _grandTotalWages += dailyWages;
    }

    // Final calculations for grand total wages
    _grandTotalWages += _totalFuelCost;
    _grandTotalWages += others;
    _grandTotalWages -= _taxAmount;

    // Ensure the grand total is not negative
    if (_grandTotalWages < 0) {
      _grandTotalWages = 0;
    }

    // Calculate the grand total before tax
    _grandtotalbeforeTax = _grandTotalWages + _taxAmount;

    // Show the total wages dialog
    _showTotalWagesDialog();
  }

  void _showTotalWagesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Obtain screen size for responsive design
        var screenSize = MediaQuery.of(context).size;

        // Dynamic text size based on screen width, within a reasonable range
        double textSize = screenSize.width * 0.04;
        textSize = textSize.clamp(14.0, 18.0);

        return AlertDialog(
          title: Text(
            'Total Wages Breakdown for $_employeeName',
            style: TextStyle(fontSize: textSize),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Date: $_date', style: TextStyle(fontSize: textSize)),
                Text('Employee Name: $_employeeName',
                    style: TextStyle(fontSize: textSize)),
                Text('Employee Address: $_employeeAddress',
                    style: TextStyle(fontSize: textSize)),
                Text(
                    'Total Hours in Gosford (Weekdays): $_totalHoursGosfordWeekday',
                    style: TextStyle(fontSize: textSize)),
                Text(
                    'Total Hours in Gosford (Weekends): $_totalHoursGosfordWeekend',
                    style: TextStyle(fontSize: textSize)),
                Text('Total Hours in Islington: $_totalHoursIslington',
                    style: TextStyle(fontSize: textSize)),
                Text('Total Hours in Adamstown: $_totalHoursadamstown',
                    style: TextStyle(fontSize: textSize)),
                Text(
                    'Fuel Cost for Gosford: \$${_totalFuelCost.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: textSize)),
                Text('Other/covered shift: \$${others.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: textSize)),
                Text(
                    'Grand Total Wages (Before deducting TAX amount): \$${_grandtotalbeforeTax.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: textSize)),
                Text('Amount Paid on Tax: \$${_taxAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: textSize)),
                Text(
                    'Grand Total Wages (After deducting TAX amount): \$${_grandTotalWages.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: textSize)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(fontSize: textSize)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Save as PDF', style: TextStyle(fontSize: textSize)),
              onPressed: _saveAsPdf,
            ),
          ],
        );
      },
    );
  }

  Future<void> saveAsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Date: $_date'),
              pw.Text('Employee Name: $_employeeName'),
              pw.Text('Employee Address: $_employeeAddress'),
              pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 10)),
              ..._wageDetails.expand((wageDetail) {
                return wageDetail.shifts.map((shift) {
                  String startTime = _formatTimeOfDay(shift.startTime);
                  String endTime = _formatTimeOfDay(shift.endTime);
                  return pw.Text(
                    '${wageDetail.day}: Start - $startTime, End - $endTime, Location - ${shift.location}, Earnings - \$${wageDetail.earnings.toStringAsFixed(2)}',
                  );
                });
              }).toList(),
            ],
          );
        },
      ),
    );

    // Save the document
    await savePdfFile(pdf);
  }

  String formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Not Set';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size; // Get screen size

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EzyMart Wages Calculator',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Makes the text bold
            color: Colors.red, // Sets the text color to red
          ),
        ),
        centerTitle: true, // Centers the title
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding:
                EdgeInsets.all(screenSize.width * 0.05), // Responsive padding
            child: Column(
              children: <Widget>[
                // Date field
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(labelText: 'Date'),
                  readOnly: true, // Make the text field read-only
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2025),
                    );
                    if (pickedDate != null) {
                      _dateController.text =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                    }
                  },
                  onSaved: (value) {
                    _date = value ?? '';
                  },
                ),
                // Employee Name field
                TextFormField(
                  decoration: InputDecoration(labelText: 'Employee Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the employee name';
                    }
                    return null; // Return null to indicate no error
                  },
                  onSaved: (value) {
                    _employeeName = value ?? '';
                  },
                ),

                // Employee Address field
                TextFormField(
                  decoration: InputDecoration(labelText: 'Employee Address'),
                  onSaved: (value) {
                    _employeeAddress = value ?? '';
                  },
                ),
                // Days of the week
                // Iterating over each WageDetail for each day
                ..._wageDetails.map((wageDetail) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Checkbox to indicate if the user worked on that day
                      CheckboxListTile(
                        title: Text(wageDetail.day),
                        value: wageDetail.shifts.isNotEmpty,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value ?? false) {
                              if (wageDetail.shifts.isEmpty) {
                                wageDetail.shifts.add(ShiftDetail());
                              }
                            } else {
                              wageDetail.shifts.clear();
                            }
                          });
                        },
                      ),

                      // Displaying shifts
                      ...wageDetail.shifts.map((shift) {
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  shift.startTime != null
                                      ? 'Start Time: ${shift.startTime!.format(context)}'
                                      : 'Start Time',
                                ),
                                onTap: () async {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        shift.startTime ?? TimeOfDay.now(),
                                  );
                                  if (pickedTime != null) {
                                    setState(
                                        () => shift.startTime = pickedTime);
                                  }
                                },
                              ),
                              ListTile(
                                title: Text(
                                  shift.endTime != null
                                      ? 'End Time: ${shift.endTime!.format(context)}'
                                      : 'End Time',
                                ),
                                onTap: () async {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        shift.endTime ?? TimeOfDay.now(),
                                  );
                                  if (pickedTime != null) {
                                    setState(() => shift.endTime = pickedTime);
                                  }
                                },
                              ),
                              DropdownButtonFormField<String>(
                                value: shift.location,
                                items: ['Gosford', 'Islington', 'Adamstown']
                                    .map((location) => DropdownMenuItem(
                                          value: location,
                                          child: Text(location),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => shift.location = value!);
                                },
                                decoration: InputDecoration(
                                  labelText: 'Location',
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      // Button to add a new shift
                      if (wageDetail.shifts.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() {
                            wageDetail.shifts.add(ShiftDetail());
                          }),
                          child: Text('Add Another Shift'),
                        ),
                    ],
                  );
                }).toList(),
                // Rates and costs
                TextFormField(
                  decoration:
                      InputDecoration(labelText: 'Gosford Weekday Rate'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) {
                    _gosfordWeekdayRate = double.tryParse(value ?? '') ?? 0;
                  },
                ),
                TextFormField(
                  decoration:
                      InputDecoration(labelText: 'Gosford Weekend Rate'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) {
                    _gosfordWeekendRate = double.tryParse(value ?? '') ?? 0;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Islington Rate'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) {
                    _islingtonRate = double.tryParse(value ?? '') ?? 0;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Adamstown Rate'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) {
                    _adamstownRate = double.tryParse(value ?? '') ?? 0;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                      labelText: 'Fuel Cost per Day (Only for Gosford)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the fuel cost';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _fuelCost = double.tryParse(value ?? '') ?? 0;
                  },
                ),
                TextFormField(
                  decoration:
                      InputDecoration(labelText: 'Others /covered shift'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      others = double.tryParse(value ?? '') ?? 0;
                      isExpenseExplanationEnabled = others != 0;
                    });
                  },
                  onSaved: (value) {
                    others = double.tryParse(value ?? '') ?? 0;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Expense Explanation'),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  enabled: isExpenseExplanationEnabled,
                  onSaved: (value) {
                    expenseExplanation = value ?? '';
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Amount Paid on TAX'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a tax amount';
                    }
                    final number = double.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Please enter a positive tax amount';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _taxAmount = double.tryParse(value ?? '') ?? 0;
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            _calculateWages();
                          }
                        },
                        child: Text('Calculate'),
                      ),
                      ElevatedButton(
                        onPressed: _clearForm,
                        child: Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors
                              .red, // Differentiate from the Calculate button
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _formKey.currentState!.reset();
      _date = '';
      _employeeName = '';
      _employeeAddress = '';
      _totalHoursGosfordWeekday = 0;
      _totalHoursGosfordWeekend = 0;
      _totalHoursIslington = 0;
      _totalFuelCost = 0;
      _grandTotalWages = 0;
      _gosfordWeekdayRate = 0;
      _gosfordWeekendRate = 0;
      _islingtonRate = 0;
      _fuelCost = 0;
      _taxAmount = 0;
      others = 0;
      _workedDays.updateAll((key, value) => false);
      _startTime.updateAll((key, value) => null);
      _endTime.updateAll((key, value) => null);
      _locations.updateAll((key, value) => 'Gosford');
      _wageDetails.clear();
    });
  }
}
