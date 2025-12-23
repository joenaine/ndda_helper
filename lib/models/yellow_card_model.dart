class YellowCardModel {
  // General Information
  String? messageType; // 'clinical', 'literature', 'postmarketing', 'spontaneous'
  String? messageKind; // 'initial', 'followup'

  // Organization Information
  String? organizationName;
  String? organizationCity;
  String? organizationAddress;
  String? organizationPhone;
  String? organizationEmail;

  // Source Information
  String? sourcePerson; // 'doctor', 'nurse', 'pharmacist', 'patient', 'representative'
  String? sourceName;
  String? sourcePhone;
  String? sourceEmail;

  // Patient Information
  String? patientName;
  String? medicalRecordNumber;
  DateTime? dateOfBirth;
  int? age;
  String? gender; // 'female', 'male', 'unknown'
  double? height; // cm
  double? weight; // kg
  String? additionalInfo;
  String? nationality; // 'asian', 'asian_east', 'european'

  // Clinical Diagnosis
  String? clinicalDiagnosis;
  String? concomitantDiagnosis;

  // Pregnancy Information
  bool? isPregnant;
  DateTime? lastMenstrualPeriod;
  DateTime? expectedDeliveryDate;
  int? numberOfFetuses;
  String? conceptionType; // 'invitro', 'normal'
  String? pregnancyOutcome;
  DateTime? actualDeliveryDate;
  int? gestationalAge;
  String? deliveryType;
  double? childWeight;
  double? childHeight;
  String? childGender;
  int? apgarScore1Min;
  int? apgarScore5Min;
  int? apgarScore10Min;

  // Suspected Drug/Vaccine
  String? suspectedDrugName;
  DateTime? drugStartDate;
  DateTime? drugEndDate;
  String? drugRoute; // route of administration
  String? drugForm;
  String? drugBatchNumber;
  String? drugDailyDose;
  String? drugIndication;

  // Side Effects
  List<String>? sideEffects;

  // Concomitant Drugs (up to 10)
  List<ConcomitantDrug>? concomitantDrugs;

  // Medical History
  List<MedicalHistoryItem>? medicalHistory;

  YellowCardModel({
    this.messageType,
    this.messageKind,
    this.organizationName,
    this.organizationCity,
    this.organizationAddress,
    this.organizationPhone,
    this.organizationEmail,
    this.sourcePerson,
    this.sourceName,
    this.sourcePhone,
    this.sourceEmail,
    this.patientName,
    this.medicalRecordNumber,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.additionalInfo,
    this.nationality,
    this.clinicalDiagnosis,
    this.concomitantDiagnosis,
    this.isPregnant,
    this.lastMenstrualPeriod,
    this.expectedDeliveryDate,
    this.numberOfFetuses,
    this.conceptionType,
    this.pregnancyOutcome,
    this.actualDeliveryDate,
    this.gestationalAge,
    this.deliveryType,
    this.childWeight,
    this.childHeight,
    this.childGender,
    this.apgarScore1Min,
    this.apgarScore5Min,
    this.apgarScore10Min,
    this.suspectedDrugName,
    this.drugStartDate,
    this.drugEndDate,
    this.drugRoute,
    this.drugForm,
    this.drugBatchNumber,
    this.drugDailyDose,
    this.drugIndication,
    this.sideEffects,
    this.concomitantDrugs,
    this.medicalHistory,
  });

  /// Convert model to form data map for POST request
  Map<String, dynamic> toFormData() {
    final formData = <String, dynamic>{};

    // General Information
    if (messageType != null) {
      formData['message_type'] = messageType;
    }
    if (messageKind != null) {
      formData['message_kind'] = messageKind;
    }

    // Organization Information
    if (organizationName != null) {
      formData['organization_name'] = organizationName;
    }
    if (organizationCity != null) {
      formData['organization_city'] = organizationCity;
    }
    if (organizationAddress != null) {
      formData['organization_address'] = organizationAddress;
    }
    if (organizationPhone != null) {
      formData['organization_phone'] = organizationPhone;
    }
    if (organizationEmail != null) {
      formData['organization_email'] = organizationEmail;
    }

    // Source Information
    if (sourcePerson != null) {
      formData['source_person'] = sourcePerson;
    }
    if (sourceName != null) {
      formData['source_name'] = sourceName;
    }
    if (sourcePhone != null) {
      formData['source_phone'] = sourcePhone;
    }
    if (sourceEmail != null) {
      formData['source_email'] = sourceEmail;
    }

    // Patient Information
    if (patientName != null) {
      formData['patient_name'] = patientName;
    }
    if (medicalRecordNumber != null) {
      formData['medical_record_number'] = medicalRecordNumber;
    }
    if (dateOfBirth != null) {
      formData['date_of_birth'] = 
          '${dateOfBirth!.year}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}';
    }
    if (age != null) {
      formData['age'] = age.toString();
    }
    if (gender != null) {
      formData['gender'] = gender;
    }
    if (height != null) {
      formData['height'] = height.toString();
    }
    if (weight != null) {
      formData['weight'] = weight.toString();
    }
    if (additionalInfo != null) {
      formData['additional_info'] = additionalInfo;
    }
    if (nationality != null) {
      formData['nationality'] = nationality;
    }

    // Clinical Diagnosis
    if (clinicalDiagnosis != null) {
      formData['clinical_diagnosis'] = clinicalDiagnosis;
    }
    if (concomitantDiagnosis != null) {
      formData['concomitant_diagnosis'] = concomitantDiagnosis;
    }

    // Pregnancy Information
    if (isPregnant != null) {
      formData['is_pregnant'] = isPregnant! ? '1' : '0';
    }
    if (lastMenstrualPeriod != null) {
      formData['last_menstrual_period'] = 
          '${lastMenstrualPeriod!.year}-${lastMenstrualPeriod!.month.toString().padLeft(2, '0')}-${lastMenstrualPeriod!.day.toString().padLeft(2, '0')}';
    }
    if (expectedDeliveryDate != null) {
      formData['expected_delivery_date'] = 
          '${expectedDeliveryDate!.year}-${expectedDeliveryDate!.month.toString().padLeft(2, '0')}-${expectedDeliveryDate!.day.toString().padLeft(2, '0')}';
    }
    if (numberOfFetuses != null) {
      formData['number_of_fetuses'] = numberOfFetuses.toString();
    }
    if (conceptionType != null) {
      formData['conception_type'] = conceptionType;
    }
    if (pregnancyOutcome != null) {
      formData['pregnancy_outcome'] = pregnancyOutcome;
    }
    if (actualDeliveryDate != null) {
      formData['actual_delivery_date'] = 
          '${actualDeliveryDate!.year}-${actualDeliveryDate!.month.toString().padLeft(2, '0')}-${actualDeliveryDate!.day.toString().padLeft(2, '0')}';
    }
    if (gestationalAge != null) {
      formData['gestational_age'] = gestationalAge.toString();
    }
    if (deliveryType != null) {
      formData['delivery_type'] = deliveryType;
    }
    if (childWeight != null) {
      formData['child_weight'] = childWeight.toString();
    }
    if (childHeight != null) {
      formData['child_height'] = childHeight.toString();
    }
    if (childGender != null) {
      formData['child_gender'] = childGender;
    }
    if (apgarScore1Min != null) {
      formData['apgar_1min'] = apgarScore1Min.toString();
    }
    if (apgarScore5Min != null) {
      formData['apgar_5min'] = apgarScore5Min.toString();
    }
    if (apgarScore10Min != null) {
      formData['apgar_10min'] = apgarScore10Min.toString();
    }

    // Suspected Drug
    if (suspectedDrugName != null) {
      formData['suspected_drug_name'] = suspectedDrugName;
    }
    if (drugStartDate != null) {
      formData['drug_start_date'] = 
          '${drugStartDate!.year}-${drugStartDate!.month.toString().padLeft(2, '0')}-${drugStartDate!.day.toString().padLeft(2, '0')}';
    }
    if (drugEndDate != null) {
      formData['drug_end_date'] = 
          '${drugEndDate!.year}-${drugEndDate!.month.toString().padLeft(2, '0')}-${drugEndDate!.day.toString().padLeft(2, '0')}';
    }
    if (drugRoute != null) {
      formData['drug_route'] = drugRoute;
    }
    if (drugForm != null) {
      formData['drug_form'] = drugForm;
    }
    if (drugBatchNumber != null) {
      formData['drug_batch_number'] = drugBatchNumber;
    }
    if (drugDailyDose != null) {
      formData['drug_daily_dose'] = drugDailyDose;
    }
    if (drugIndication != null) {
      formData['drug_indication'] = drugIndication;
    }

    // Side Effects
    if (sideEffects != null && sideEffects!.isNotEmpty) {
      for (int i = 0; i < sideEffects!.length; i++) {
        formData['side_effect_$i'] = sideEffects![i];
      }
    }

    // Concomitant Drugs
    if (concomitantDrugs != null) {
      for (int i = 0; i < concomitantDrugs!.length; i++) {
        final drug = concomitantDrugs![i];
        formData['concomitant_drug_${i}_name'] = drug.name;
        formData['concomitant_drug_${i}_form'] = drug.form;
        formData['concomitant_drug_${i}_dose'] = drug.dailyDose;
        formData['concomitant_drug_${i}_route'] = drug.route;
        if (drug.startDate != null) {
          formData['concomitant_drug_${i}_start_date'] = 
              '${drug.startDate!.year}-${drug.startDate!.month.toString().padLeft(2, '0')}-${drug.startDate!.day.toString().padLeft(2, '0')}';
        }
        if (drug.endDate != null) {
          formData['concomitant_drug_${i}_end_date'] = 
              '${drug.endDate!.year}-${drug.endDate!.month.toString().padLeft(2, '0')}-${drug.endDate!.day.toString().padLeft(2, '0')}';
        }
        if (drug.indication != null) {
          formData['concomitant_drug_${i}_indication'] = drug.indication;
        }
        if (drug.actionTaken != null) {
          formData['concomitant_drug_${i}_action'] = drug.actionTaken;
        }
      }
    }

    // Medical History
    if (medicalHistory != null) {
      for (int i = 0; i < medicalHistory!.length; i++) {
        final history = medicalHistory![i];
        formData['medical_history_${i}_name'] = history.name;
        formData['medical_history_${i}_ongoing'] = history.isOngoing ? '1' : '0';
      }
    }

    return formData;
  }
}

class ConcomitantDrug {
  String? name;
  String? form;
  String? dailyDose;
  String? route;
  DateTime? startDate;
  DateTime? endDate;
  String? indication;
  String? actionTaken; // 'discontinued', 'stopped', 'dose_reduced', 'dose_increased', 'unchanged', 'unknown'

  ConcomitantDrug({
    this.name,
    this.form,
    this.dailyDose,
    this.route,
    this.startDate,
    this.endDate,
    this.indication,
    this.actionTaken,
  });
}

class MedicalHistoryItem {
  String name;
  bool isOngoing;

  MedicalHistoryItem({
    required this.name,
    required this.isOngoing,
  });
}

