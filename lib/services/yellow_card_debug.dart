import 'yellow_card_service.dart';

/// Debug helper for Yellow Card submission
class YellowCardDebug {
  /// Generate minimal test data (only required fields)
  static YellowCardSubmissionData getMinimalTestData() {
    return YellowCardSubmissionData(
      // Required fields only
      orgName: 'Test Organization',
      patientName: 'T.T.T',
      patientAge: '30',
      patientSex: '1', // Male
      diagnosisPrimary: 'Test Diagnosis',
      
      // At least one suspected drug (first one is required)
      suspectedDrugs: [
        SuspectedDrugData(name: 'Test Drug'),
      ],
      
      // Empty arrays for other sections
      sideEffects: [],
      accompanyingDrugs: [],
      medicalHistory: [],
      
      // Message date
      messageDate: '25.12.2025',
    );
  }
  
  /// Generate complete test data
  static YellowCardSubmissionData getCompleteTestData() {
    return YellowCardSubmissionData(
      // Section 1: General Information
      messageType: 'Спонтанный',
      messageKind: 'Начальное сообщение',
      messageDate: '25.12.2025',
      orgName: 'Test Medical Center',
      orgCity: 'Алматы',
      orgAddress: 'Test Address 123',
      orgPhone: '+7 777 123 4567',
      orgEmail: 'test@example.com',
      sourceType: 'Врач',
      sourceName: 'Dr. Test',
      sourcePhone: '+7 777 123 4567',
      sourceEmail: 'doctor@example.com',
      
      // Section 2: Patient Information
      patientName: 'T.T.T',
      medRecordNumber: '12345',
      patientBirthdate: '01.01.1990',
      patientAge: '33',
      patientSex: '1',
      patientHeight: '175',
      patientWeight: '70',
      additionalPatientInfo: 'No additional info',
      patientNationality: 'Азиат',
      diagnosisPrimary: 'Test Primary Diagnosis',
      diagnosisSecondary: 'Test Secondary Diagnosis',
      
      // Section 3: Pregnancy - Not pregnant
      isPregnant: '0',
      
      // Section 4: Suspected Drugs
      suspectedDrugs: [
        SuspectedDrugData(
          name: 'Test Drug 1',
          startDate: '01.12.2025',
          endDate: '20.12.2025',
          route: 'ПЕРОРАЛЬНЫЙ',
          batch: 'Batch 123',
          indications: 'Test indication',
          action: 'Препарат отменён',
        ),
      ],
      
      // Section 5: Side Effects
      sideEffects: [
        SideEffectData(
          effect: 'Test Side Effect',
          outcome: 'Выздоровление',
          relation: 'Вероятная',
        ),
      ],
      areSideEffectsSerious: '0',
      
      // Section 6: Accompanying Drugs - empty
      accompanyingDrugs: [],
      
      // Section 7: Medical History - empty
      medicalHistory: [],
    );
  }
  
  /// Print formatted data for debugging
  static void printFormData(YellowCardSubmissionData data) {
    print('=== YELLOW CARD DATA DEBUG ===');
    print('Required Fields:');
    print('  org_name: ${data.orgName}');
    print('  patient_name: ${data.patientName}');
    print('  patient_age: ${data.patientAge}');
    print('  patient_sex: ${data.patientSex}');
    print('  diagnosis_primary: ${data.diagnosisPrimary}');
    print('  suspect_drug[0]: ${data.suspectedDrugs.isNotEmpty ? data.suspectedDrugs[0].name : "EMPTY"}');
    print('');
    print('Optional Fields:');
    print('  message_type: ${data.messageType}');
    print('  message_kind: ${data.messageKind}');
    print('  message_date: ${data.messageDate}');
    print('  org_city: ${data.orgCity}');
    print('  side_effects count: ${data.sideEffects.length}');
    print('  suspected_drugs count: ${data.suspectedDrugs.length}');
    print('=== END DEBUG ===');
  }
}

