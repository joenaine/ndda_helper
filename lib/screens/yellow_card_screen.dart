import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/yellow_card_model.dart';
import '../services/ndda_auth_service.dart';
import '../widgets/app_hide_keyboard_widget.dart';

class YellowCardScreen extends StatefulWidget {
  const YellowCardScreen({super.key});

  @override
  State<YellowCardScreen> createState() => _YellowCardScreenState();
}

class _YellowCardScreenState extends State<YellowCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nddaAuthService = NddaAuthService();

  // Login credentials
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggedIn = false;
  bool _isCheckingLogin = true;
  bool _isSubmitting = false;

  // Form data
  final YellowCardModel _formData = YellowCardModel();

  // Controllers for form fields
  final _organizationNameController = TextEditingController();
  final _organizationAddressController = TextEditingController();
  final _organizationPhoneController = TextEditingController();
  final _organizationEmailController = TextEditingController();
  final _sourceNameController = TextEditingController();
  final _sourcePhoneController = TextEditingController();
  final _sourceEmailController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _medicalRecordController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _clinicalDiagnosisController = TextEditingController();
  final _suspectedDrugNameController = TextEditingController();
  final _drugFormController = TextEditingController();
  final _drugBatchController = TextEditingController();
  final _drugDoseController = TextEditingController();
  final _drugIndicationController = TextEditingController();

  String? _selectedMessageType;
  String? _selectedMessageKind;
  String? _selectedOrganizationCity;
  String? _selectedSourcePerson;
  String? _selectedGender;
  String? _selectedNationality;
  DateTime? _dateOfBirth;
  DateTime? _drugStartDate;
  DateTime? _drugEndDate;
  String? _selectedDrugRoute;
  bool _isPregnant = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _organizationNameController.dispose();
    _organizationAddressController.dispose();
    _organizationPhoneController.dispose();
    _organizationEmailController.dispose();
    _sourceNameController.dispose();
    _sourcePhoneController.dispose();
    _sourceEmailController.dispose();
    _patientNameController.dispose();
    _medicalRecordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _additionalInfoController.dispose();
    _clinicalDiagnosisController.dispose();
    _suspectedDrugNameController.dispose();
    _drugFormController.dispose();
    _drugBatchController.dispose();
    _drugDoseController.dispose();
    _drugIndicationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _isCheckingLogin = true;
    });

    final isLoggedIn = await _nddaAuthService.isLoggedIn();
    
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isCheckingLogin = false;
    });
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter username and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await _nddaAuthService.login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() {
      _isSubmitting = false;
      _isLoggedIn = success;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please check your credentials'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Populate form data
    _formData.messageType = _selectedMessageType;
    _formData.messageKind = _selectedMessageKind;
    _formData.organizationName = _organizationNameController.text;
    _formData.organizationCity = _selectedOrganizationCity;
    _formData.organizationAddress = _organizationAddressController.text;
    _formData.organizationPhone = _organizationPhoneController.text;
    _formData.organizationEmail = _organizationEmailController.text;
    _formData.sourcePerson = _selectedSourcePerson;
    _formData.sourceName = _sourceNameController.text;
    _formData.sourcePhone = _sourcePhoneController.text;
    _formData.sourceEmail = _sourceEmailController.text;
    _formData.patientName = _patientNameController.text;
    _formData.medicalRecordNumber = _medicalRecordController.text;
    _formData.dateOfBirth = _dateOfBirth;
    _formData.age = int.tryParse(_ageController.text);
    _formData.gender = _selectedGender;
    _formData.height = double.tryParse(_heightController.text);
    _formData.weight = double.tryParse(_weightController.text);
    _formData.additionalInfo = _additionalInfoController.text;
    _formData.nationality = _selectedNationality;
    _formData.clinicalDiagnosis = _clinicalDiagnosisController.text;
    _formData.isPregnant = _isPregnant;
    _formData.suspectedDrugName = _suspectedDrugNameController.text;
    _formData.drugStartDate = _drugStartDate;
    _formData.drugEndDate = _drugEndDate;
    _formData.drugRoute = _selectedDrugRoute;
    _formData.drugForm = _drugFormController.text;
    _formData.drugBatchNumber = _drugBatchController.text;
    _formData.drugDailyDose = _drugDoseController.text;
    _formData.drugIndication = _drugIndicationController.text;

    final formDataMap = _formData.toFormData();
    final success = await _nddaAuthService.submitYellowCard(formDataMap);

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yellow card submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form
        _formKey.currentState!.reset();
        _clearForm();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit yellow card. Please try again'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {
    _organizationNameController.clear();
    _organizationAddressController.clear();
    _organizationPhoneController.clear();
    _organizationEmailController.clear();
    _sourceNameController.clear();
    _sourcePhoneController.clear();
    _sourceEmailController.clear();
    _patientNameController.clear();
    _medicalRecordController.clear();
    _ageController.clear();
    _heightController.clear();
    _weightController.clear();
    _additionalInfoController.clear();
    _clinicalDiagnosisController.clear();
    _suspectedDrugNameController.clear();
    _drugFormController.clear();
    _drugBatchController.clear();
    _drugDoseController.clear();
    _drugIndicationController.clear();
    setState(() {
      _selectedMessageType = null;
      _selectedMessageKind = null;
      _selectedOrganizationCity = null;
      _selectedSourcePerson = null;
      _selectedGender = null;
      _selectedNationality = null;
      _dateOfBirth = null;
      _drugStartDate = null;
      _drugEndDate = null;
      _selectedDrugRoute = null;
      _isPregnant = false;
    });
  }

  Future<void> _selectDate(BuildContext context, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLogin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Yellow Card Registration'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppHideKeyBoardWidget(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yellow Card Registration'),
          actions: [
            if (_isLoggedIn)
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await _nddaAuthService.logout();
                  setState(() {
                    _isLoggedIn = false;
                  });
                },
                tooltip: 'Logout',
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Login Section
              if (!_isLoggedIn) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Login Required',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password *',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Login'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // General Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. General Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedMessageType,
                        decoration: const InputDecoration(
                          labelText: 'Message Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'clinical', child: Text('Clinical Study')),
                          DropdownMenuItem(value: 'literature', child: Text('Literature')),
                          DropdownMenuItem(value: 'postmarketing', child: Text('Postmarketing Study')),
                          DropdownMenuItem(value: 'spontaneous', child: Text('Spontaneous')),
                        ],
                        onChanged: _isLoggedIn
                            ? (value) => setState(() => _selectedMessageType = value)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedMessageKind,
                        decoration: const InputDecoration(
                          labelText: 'Message Kind *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'initial', child: Text('Initial Message')),
                          DropdownMenuItem(value: 'followup', child: Text('Follow-up Message')),
                        ],
                        onChanged: _isLoggedIn
                            ? (value) => setState(() => _selectedMessageKind = value)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Organization Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2. Organization Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _organizationNameController,
                        decoration: const InputDecoration(
                          labelText: 'Organization Name *',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        validator: (value) {
                          if (_isLoggedIn && (value == null || value.isEmpty)) {
                            return 'Please enter organization name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedOrganizationCity,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Almaty', child: Text('Almaty')),
                          DropdownMenuItem(value: 'Astana', child: Text('Astana')),
                          DropdownMenuItem(value: 'Atyrau', child: Text('Atyrau')),
                          DropdownMenuItem(value: 'Aktau', child: Text('Aktau')),
                          DropdownMenuItem(value: 'Aktobe', child: Text('Aktobe')),
                          DropdownMenuItem(value: 'Ust-Kamenogorsk', child: Text('Ust-Kamenogorsk')),
                          DropdownMenuItem(value: 'Taraz', child: Text('Taraz')),
                          DropdownMenuItem(value: 'Karaganda', child: Text('Karaganda')),
                          DropdownMenuItem(value: 'Kostanay', child: Text('Kostanay')),
                          DropdownMenuItem(value: 'Petropavlovsk', child: Text('Petropavlovsk')),
                          DropdownMenuItem(value: 'Pavlodar', child: Text('Pavlodar')),
                          DropdownMenuItem(value: 'Uralsk', child: Text('Uralsk')),
                          DropdownMenuItem(value: 'Semey', child: Text('Semey')),
                          DropdownMenuItem(value: 'Kokshetau', child: Text('Kokshetau')),
                          DropdownMenuItem(value: 'Taldykorgan', child: Text('Taldykorgan')),
                          DropdownMenuItem(value: 'Kyzylorda', child: Text('Kyzylorda')),
                          DropdownMenuItem(value: 'Shymkent', child: Text('Shymkent')),
                          DropdownMenuItem(value: 'Turkestan', child: Text('Turkestan')),
                        ],
                        onChanged: _isLoggedIn
                            ? (value) => setState(() => _selectedOrganizationCity = value)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _organizationAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _organizationPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _organizationEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Source Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3. Source Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedSourcePerson,
                        decoration: const InputDecoration(
                          labelText: 'Source Person *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                          DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
                          DropdownMenuItem(value: 'pharmacist', child: Text('Pharmacist')),
                          DropdownMenuItem(value: 'patient', child: Text('Patient/Consumer')),
                          DropdownMenuItem(value: 'representative', child: Text('Representative')),
                        ],
                        onChanged: _isLoggedIn
                            ? (value) => setState(() => _selectedSourcePerson = value)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sourceNameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        validator: (value) {
                          if (_isLoggedIn && (value == null || value.isEmpty)) {
                            return 'Please enter name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sourcePhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sourceEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Patient Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '4. Patient Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _patientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name (Initials) *',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        validator: (value) {
                          if (_isLoggedIn && (value == null || value.isEmpty)) {
                            return 'Please enter patient name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _medicalRecordController,
                        decoration: const InputDecoration(
                          labelText: 'Medical Record Number',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          _dateOfBirth == null
                              ? 'Date of Birth'
                              : 'Date of Birth: ${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _isLoggedIn
                            ? () => _selectDate(context, (date) {
                                  setState(() => _dateOfBirth = date);
                                })
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age (years) *',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (_isLoggedIn && (value == null || value.isEmpty)) {
                            return 'Please enter age';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
                        ],
                        onChanged: _isLoggedIn
                            ? (value) => setState(() => _selectedGender = value)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _additionalInfoController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Information',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedNationality,
                        decoration: const InputDecoration(
                          labelText: 'Nationality',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'asian', child: Text('Asian')),
                          DropdownMenuItem(value: 'asian_east', child: Text('Asian (East Asia)')),
                          DropdownMenuItem(value: 'european', child: Text('European')),
                        ],
                        onChanged: _isLoggedIn
                            ? (value) => setState(() => _selectedNationality = value)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Clinical Diagnosis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '5. Clinical Diagnosis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clinicalDiagnosisController,
                        decoration: const InputDecoration(
                          labelText: 'Clinical Diagnosis',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Pregnancy Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '6. Pregnancy Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Is Patient Pregnant?'),
                        value: _isPregnant,
                        onChanged: _isLoggedIn
                            ? (value) => setState(() => _isPregnant = value ?? false)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Suspected Drug
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '7. Suspected Drug/Vaccine',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _suspectedDrugNameController,
                        decoration: const InputDecoration(
                          labelText: 'Drug Name *',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        validator: (value) {
                          if (_isLoggedIn && (value == null || value.isEmpty)) {
                            return 'Please enter drug name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          _drugStartDate == null
                              ? 'Start Date'
                              : 'Start Date: ${_drugStartDate!.year}-${_drugStartDate!.month.toString().padLeft(2, '0')}-${_drugStartDate!.day.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _isLoggedIn
                            ? () => _selectDate(context, (date) {
                                  setState(() => _drugStartDate = date);
                                })
                            : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          _drugEndDate == null
                              ? 'End Date'
                              : 'End Date: ${_drugEndDate!.year}-${_drugEndDate!.month.toString().padLeft(2, '0')}-${_drugEndDate!.day.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _isLoggedIn
                            ? () => _selectDate(context, (date) {
                                  setState(() => _drugEndDate = date);
                                })
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDrugRoute,
                        decoration: const InputDecoration(
                          labelText: 'Route of Administration',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'oral', child: Text('Oral')),
                          DropdownMenuItem(value: 'intravenous', child: Text('Intravenous')),
                          DropdownMenuItem(value: 'intramuscular', child: Text('Intramuscular')),
                          DropdownMenuItem(value: 'subcutaneous', child: Text('Subcutaneous')),
                          DropdownMenuItem(value: 'topical', child: Text('Topical')),
                          DropdownMenuItem(value: 'inhalation', child: Text('Inhalation')),
                        ],
                        onChanged: _isLoggedIn
                            ? (value) => setState(() => _selectedDrugRoute = value)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _drugFormController,
                        decoration: const InputDecoration(
                          labelText: 'Drug Form / Batch Number',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _drugBatchController,
                        decoration: const InputDecoration(
                          labelText: 'Batch Number',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _drugDoseController,
                        decoration: const InputDecoration(
                          labelText: 'Daily Dose',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _drugIndicationController,
                        decoration: const InputDecoration(
                          labelText: 'Indication',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isLoggedIn,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              if (_isLoggedIn)
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit Yellow Card'),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

