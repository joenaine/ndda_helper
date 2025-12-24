import 'package:dio/dio.dart';
import 'dio_helper.dart';

class YellowCardService {
  static const String _submitUrl =
      'https://www.ndda.kz/register.php/sideeffects/new/lang/ru';
  static const String _baseUrl = 'https://www.ndda.kz';
  
  static final DioHelper _dioHelper = DioHelper.instance;

  static Future<YellowCardSubmissionResponse> submitYellowCard(
      YellowCardSubmissionData data) async {
    try {
      // Check if user is logged in first
      final uri = Uri.parse(_baseUrl);
      final cookies = await _dioHelper.getCookies(uri);
      final hasAuthCookie = cookies.any((c) => 
        c.name.contains('70df632a8fb0cc0c01ee88db4be8c9eb') ||
        c.name == 'PHPSESSID'
      );
      
      if (!hasAuthCookie) {
        return YellowCardSubmissionResponse(
          success: false,
          message: 'Вы должны войти в систему NDDA перед отправкой формы',
          statusCode: 401,
        );
      }
      
      print('=== YELLOW CARD SUBMISSION DEBUG ===');
      print('URL: $_submitUrl');
      print('Cookies found: ${cookies.length}');
      for (var cookie in cookies) {
        print('  - ${cookie.name}: ${cookie.value.substring(0, cookie.value.length > 20 ? 20 : cookie.value.length)}...');
      }
      
      // Build form data
      final formData = _buildFormData(data);
      
      print('Data length: ${formData.length}');
      print('');
      print('=== FULL FORM DATA (URL decoded) ===');
      final decoded = Uri.decodeComponent(formData);
      for (int i = 0; i < decoded.length; i += 500) {
        final end = (i + 500) < decoded.length ? (i + 500) : decoded.length;
        print(decoded.substring(i, end));
      }
      print('=== END FULL FORM DATA ===');
      print('');
      
      // Submit using Dio (automatically includes cookies)
      final response = await _dioHelper.post(
        _submitUrl,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0',
            'Origin': _baseUrl,
            'Referer': _submitUrl,
            'Sec-Fetch-Dest': 'iframe',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'same-origin',
          },
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response data length: ${response.data?.toString().length ?? 0}');
      
      print('=== END DEBUG ===');

      if (response.statusCode == 200 || response.statusCode == 302) {
        return YellowCardSubmissionResponse(
          success: true,
          message: 'Форма успешно отправлена в NDDA',
          responseBody: response.data?.toString(),
        );
      } else {
        return YellowCardSubmissionResponse(
          success: false,
          message: 'Ошибка отправки: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: response.data?.toString(),
        );
      }
    } on DioException catch (e) {
      print('DioException during submission: $e');
      return YellowCardSubmissionResponse(
        success: false,
        message: 'Ошибка при отправке формы: ${e.message}',
      );
    } catch (e) {
      print('Exception during submission: $e');
      return YellowCardSubmissionResponse(
        success: false,
        message: 'Ошибка при отправке формы: $e',
      );
    }
  }

  static String _buildFormData(YellowCardSubmissionData data) {
    final params = <String, String>{};

    // Section 1: General Information (PDLScard)
    params['PDLScard[id]'] = '';
    params['PDLScard[message_type]'] = data.messageType ?? '';
    params['PDLScard[message_kind]'] = data.messageKind ?? '';
    params['PDLScard[message_date]'] = data.messageDate ?? '';
    params['PDLScard[org_name]'] = data.orgName ?? '';
    params['PDLScard[dept_id]'] = data.orgCity ?? '';
    params['PDLScard[org_address]'] = data.orgAddress ?? '';
    params['PDLScard[org_phone]'] = data.orgPhone ?? '';
    params['PDLScard[org_email]'] = data.orgEmail ?? '';
    params['PDLScard[source]'] = data.sourceType ?? '';
    params['PDLScard[source_name]'] = data.sourceName ?? '';
    params['PDLScard[source_phone]'] = data.sourcePhone ?? '';
    params['PDLScard[source_email]'] = data.sourceEmail ?? '';

    // Section 2: Patient Information (PDLScard)
    params['PDLScard[patient_name]'] = data.patientName ?? '';
    params['PDLScard[medrecord_number]'] = data.medRecordNumber ?? '';
    params['PDLScard[patient_birthdate]'] = data.patientBirthdate ?? '';
    params['PDLScard[patient_age]'] = data.patientAge ?? '';
    params['PDLScard[patient_sex]'] = data.patientSex ?? '';
    params['PDLScard[patient_growth]'] = data.patientHeight ?? '';
    params['PDLScard[patient_weight]'] = data.patientWeight ?? '';
    params['PDLScard[additional_information_patient]'] =
        data.additionalPatientInfo ?? '';
    params['PDLScard[patient_nation]'] = data.patientNationality ?? '';
    params['PDLScard[diagnosis_primary]'] = data.diagnosisPrimary ?? '';
    params['PDLScard[diagnosis_secondary]'] = data.diagnosisSecondary ?? '';

    // Section 3: Pregnancy Information (PDLScard)
    params['PDLScard[pregnancy]'] = data.isPregnant ?? '';
    params['PDLScard[last_menstrual_date]'] = data.lastMenstrualDate ?? '';
    params['PDLScard[due_date]'] = data.expectedDueDate ?? '';
    params['PDLScard[fetus_count]'] = data.fetusCount ?? '';
    params['PDLScard[conceiving_type]'] = data.conceivingType ?? '';
    params['PDLScard[pregnancy_outcome]'] = data.pregnancyOutcome ?? '';
    params['PDLScard[fact_due_date]'] = data.actualDueDate ?? '';
    params['PDLScard[gestational_date]'] = data.gestationalDate ?? '';
    params['PDLScard[due_type]'] = data.deliveryType ?? '';
    params['PDLScard[child_weight]'] = data.childWeight ?? '';
    params['PDLScard[child_growth]'] = data.childHeight ?? '';
    params['PDLScard[child_sex]'] = data.childSex ?? '';
    params['PDLScard[apar_1min]'] = data.apgar1Min ?? '';
    params['PDLScard[apar_5min]'] = data.apgar5Min ?? '';
    params['PDLScard[apar_10min]'] = data.apgar10Min ?? '';

    // Section 4: Suspected Drugs (PdlsDrugs) - MUST send all 10 slots like browser
    for (int i = 0; i < 10; i++) {
      if (i < data.suspectedDrugs.length) {
        final drug = data.suspectedDrugs[i];
        params['PdlsDrugs[suspect_drug][$i]'] = drug.name ?? '';
        params['PdlsDrugs[suspect_drug_begin_date][$i]'] = drug.startDate ?? '';
        params['PdlsDrugs[suspect_drug_end_date][$i]'] = drug.endDate ?? '';
        params['PdlsDrugs[suspect_drug_use_method][$i]'] = drug.route ?? '';
        params['PdlsDrugs[suspect_drug_description][$i]'] = drug.batch ?? '';
        params['PdlsDrugs[suspect_drug_indications][$i]'] = drug.indications ?? '';
        params['PdlsDrugs[suspect_drug_remedy][$i]'] = drug.action ?? '';
      } else {
        // Empty slots
        params['PdlsDrugs[suspect_drug][$i]'] = '';
        params['PdlsDrugs[suspect_drug_begin_date][$i]'] = '';
        params['PdlsDrugs[suspect_drug_end_date][$i]'] = '';
        params['PdlsDrugs[suspect_drug_use_method][$i]'] = '';
        params['PdlsDrugs[suspect_drug_description][$i]'] = '';
        params['PdlsDrugs[suspect_drug_indications][$i]'] = '';
        params['PdlsDrugs[suspect_drug_remedy][$i]'] = '';
      }
    }

    // Section 5: Side Effects (PDLSsideeffects) - MUST send all 10 slots like browser
    for (int i = 0; i < 10; i++) {
      if (i < data.sideEffects.length) {
        final effect = data.sideEffects[i];
        params['PDLSsideeffects[side_effect][$i]'] = effect.effect ?? '';
        params['PDLSsideeffects[outcome][$i]'] = effect.outcome ?? '';
        params['PDLSsideeffects[relation][$i]'] = effect.relation ?? '';
      } else {
        // Empty slots
        params['PDLSsideeffects[side_effect][$i]'] = '';
        params['PDLSsideeffects[outcome][$i]'] = '';
        params['PDLSsideeffects[relation][$i]'] = '';
      }
    }

    // Side effects additional info
    params['PDLScard[sideeffects_serious]'] = data.areSideEffectsSerious ?? '';
    params['PDLScard[sideeffects_reason]'] = data.seriousReason ?? '';
    params['PDLScard[sideeffects_causeofdeath]'] = data.causeOfDeath ?? '';

    // Section 6: Accompanying Drugs (PDLSaccompaying) - MUST send all 10 slots like browser
    for (int i = 0; i < 10; i++) {
      if (i < data.accompanyingDrugs.length) {
        final drug = data.accompanyingDrugs[i];
        params['PDLSaccompaying[drug][$i]'] = drug.name ?? '';
        params['PDLSaccompaying[dosage_form][$i]'] = drug.dosageForm ?? '';
        params['PDLSaccompaying[injection_comment][$i]'] = drug.dose ?? '';
        params['PDLSaccompaying[begin_date][$i]'] = drug.startDate ?? '';
        params['PDLSaccompaying[end_date][$i]'] = drug.endDate ?? '';
        params['PDLSaccompaying[indications][$i]'] = drug.indications ?? '';
        params['PDLSaccompaying[remedy][$i]'] = drug.action ?? '';
      } else {
        // Empty slots
        params['PDLSaccompaying[drug][$i]'] = '';
        params['PDLSaccompaying[dosage_form][$i]'] = '';
        params['PDLSaccompaying[injection_comment][$i]'] = '';
        params['PDLSaccompaying[begin_date][$i]'] = '';
        params['PDLSaccompaying[end_date][$i]'] = '';
        params['PDLSaccompaying[indications][$i]'] = '';
        params['PDLSaccompaying[remedy][$i]'] = '';
      }
    }

    // Section 7: Medical History (PDLShistory) - MUST send all 10 slots like browser
    for (int i = 0; i < 10; i++) {
      if (i < data.medicalHistory.length) {
        final history = data.medicalHistory[i];
        params['PDLShistory[name][$i]'] = history.name ?? '';
        params['PDLShistory[continues][$i]'] = history.continues ?? '';
      } else {
        // Empty slots
        params['PDLShistory[name][$i]'] = '';
        params['PDLShistory[continues][$i]'] = '';
      }
    }

    // Submit button and completion flag
    // Note: complete_sign must be sent twice (0 then 1) as per the form behavior
    params['ls'] = 'Сохранить';
    
    // Build the query string manually to handle duplicate keys
    final queryParts = <String>[];
    params.forEach((key, value) {
      queryParts.add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
    });
    
    // Add complete_sign twice (hidden field pattern in HTML forms)
    queryParts.add('PDLScard%5Bcomplete_sign%5D=0');
    queryParts.add('PDLScard%5Bcomplete_sign%5D=1');
    
    return queryParts.join('&');
  }
}

// Data classes for submission
class YellowCardSubmissionData {
  // Section 1: General Information
  final String? messageType;
  final String? messageKind;
  final String? messageDate;
  final String? orgName;
  final String? orgCity;
  final String? orgAddress;
  final String? orgPhone;
  final String? orgEmail;
  final String? sourceType;
  final String? sourceName;
  final String? sourcePhone;
  final String? sourceEmail;

  // Section 2: Patient Information
  final String? patientName;
  final String? medRecordNumber;
  final String? patientBirthdate;
  final String? patientAge;
  final String? patientSex;
  final String? patientHeight;
  final String? patientWeight;
  final String? additionalPatientInfo;
  final String? patientNationality;
  final String? diagnosisPrimary;
  final String? diagnosisSecondary;

  // Section 3: Pregnancy Information
  final String? isPregnant;
  final String? lastMenstrualDate;
  final String? expectedDueDate;
  final String? fetusCount;
  final String? conceivingType;
  final String? pregnancyOutcome;
  final String? actualDueDate;
  final String? gestationalDate;
  final String? deliveryType;
  final String? childWeight;
  final String? childHeight;
  final String? childSex;
  final String? apgar1Min;
  final String? apgar5Min;
  final String? apgar10Min;

  // Section 4: Suspected Drugs
  final List<SuspectedDrugData> suspectedDrugs;

  // Section 5: Side Effects
  final List<SideEffectData> sideEffects;
  final String? areSideEffectsSerious;
  final String? seriousReason;
  final String? causeOfDeath;

  // Section 6: Accompanying Drugs
  final List<AccompanyingDrugData> accompanyingDrugs;

  // Section 7: Medical History
  final List<MedicalHistoryData> medicalHistory;

  YellowCardSubmissionData({
    this.messageType,
    this.messageKind,
    this.messageDate,
    this.orgName,
    this.orgCity,
    this.orgAddress,
    this.orgPhone,
    this.orgEmail,
    this.sourceType,
    this.sourceName,
    this.sourcePhone,
    this.sourceEmail,
    this.patientName,
    this.medRecordNumber,
    this.patientBirthdate,
    this.patientAge,
    this.patientSex,
    this.patientHeight,
    this.patientWeight,
    this.additionalPatientInfo,
    this.patientNationality,
    this.diagnosisPrimary,
    this.diagnosisSecondary,
    this.isPregnant,
    this.lastMenstrualDate,
    this.expectedDueDate,
    this.fetusCount,
    this.conceivingType,
    this.pregnancyOutcome,
    this.actualDueDate,
    this.gestationalDate,
    this.deliveryType,
    this.childWeight,
    this.childHeight,
    this.childSex,
    this.apgar1Min,
    this.apgar5Min,
    this.apgar10Min,
    required this.suspectedDrugs,
    required this.sideEffects,
    this.areSideEffectsSerious,
    this.seriousReason,
    this.causeOfDeath,
    required this.accompanyingDrugs,
    required this.medicalHistory,
  });
}

class SuspectedDrugData {
  final String? name;
  final String? startDate;
  final String? endDate;
  final String? route;
  final String? batch;
  final String? indications;
  final String? action;

  SuspectedDrugData({
    this.name,
    this.startDate,
    this.endDate,
    this.route,
    this.batch,
    this.indications,
    this.action,
  });
}

class SideEffectData {
  final String? effect;
  final String? outcome;
  final String? relation;

  SideEffectData({
    this.effect,
    this.outcome,
    this.relation,
  });
}

class AccompanyingDrugData {
  final String? name;
  final String? dosageForm;
  final String? dose;
  final String? startDate;
  final String? endDate;
  final String? indications;
  final String? action;

  AccompanyingDrugData({
    this.name,
    this.dosageForm,
    this.dose,
    this.startDate,
    this.endDate,
    this.indications,
    this.action,
  });
}

class MedicalHistoryData {
  final String? name;
  final String? continues;

  MedicalHistoryData({
    this.name,
    this.continues,
  });
}

class YellowCardSubmissionResponse {
  final bool success;
  final String message;
  final int? statusCode;
  final String? responseBody;

  YellowCardSubmissionResponse({
    required this.success,
    required this.message,
    this.statusCode,
    this.responseBody,
  });
}

