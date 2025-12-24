import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../widgets/meddra_selector_dialog.dart';

class YellowCardScreen extends StatefulWidget {
  const YellowCardScreen({super.key});

  @override
  State<YellowCardScreen> createState() => _YellowCardScreenState();
}

class _YellowCardScreenState extends State<YellowCardScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Toggle for showing only required fields
  bool _showOnlyRequired = false;

  // SECTION 1: GENERAL INFORMATION
  String? _messageType;
  String? _messageKind;
  DateTime? _messageDate = DateTime.now();
  final _orgNameController = TextEditingController(); // REQUIRED
  String? _orgCity;
  final _orgAddressController = TextEditingController();
  final _orgPhoneController = TextEditingController();
  final _orgEmailController = TextEditingController();
  String? _sourceType;
  final _sourceNameController = TextEditingController();
  final _sourcePhoneController = TextEditingController();
  final _sourceEmailController = TextEditingController();

  // SECTION 2: PATIENT INFORMATION
  final _patientNameController = TextEditingController(); // REQUIRED
  final _medRecordController = TextEditingController();
  DateTime? _patientBirthdate;
  final _patientAgeController = TextEditingController(); // REQUIRED
  String? _patientSex; // REQUIRED
  final _patientHeightController = TextEditingController();
  final _patientWeightController = TextEditingController();
  final _additionalPatientInfoController = TextEditingController();
  String? _patientNationality;
  final _diagnosisPrimaryController = TextEditingController(); // REQUIRED
  final _diagnosisSecondaryController = TextEditingController();

  // SECTION 3: PREGNANCY INFORMATION
  bool? _isPregnant;
  DateTime? _lastMenstrualDate;
  DateTime? _expectedDueDate;
  final _fetusCountController = TextEditingController();
  String? _conceivingType;
  String? _pregnancyOutcome;
  DateTime? _actualDueDate;
  DateTime? _gestationalDate;
  String? _deliveryType;
  final _childWeightController = TextEditingController();
  final _childHeightController = TextEditingController();
  String? _childSex;
  final _apgar1MinController = TextEditingController();
  final _apgar5MinController = TextEditingController();
  final _apgar10MinController = TextEditingController();

  // SECTION 4: SUSPECTED DRUGS
  final List<SuspectedDrug> _suspectedDrugs = [SuspectedDrug()];

  // SECTION 5: SIDE EFFECTS
  final List<SideEffect> _sideEffects = [SideEffect()];
  bool? _areSideEffectsSerious;
  String? _seriousReason;
  final _causeOfDeathController = TextEditingController();

  // SECTION 6: ACCOMPANYING MEDICATIONS
  final List<AccompanyingDrug> _accompanyingDrugs = [AccompanyingDrug()];

  // SECTION 7: MEDICAL HISTORY
  final List<MedicalHistory> _medicalHistory = [MedicalHistory()];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orgNameController.dispose();
    _orgAddressController.dispose();
    _orgPhoneController.dispose();
    _orgEmailController.dispose();
    _sourceNameController.dispose();
    _sourcePhoneController.dispose();
    _sourceEmailController.dispose();
    _patientNameController.dispose();
    _medRecordController.dispose();
    _patientAgeController.dispose();
    _patientHeightController.dispose();
    _patientWeightController.dispose();
    _additionalPatientInfoController.dispose();
    _diagnosisPrimaryController.dispose();
    _diagnosisSecondaryController.dispose();
    _fetusCountController.dispose();
    _childWeightController.dispose();
    _childHeightController.dispose();
    _apgar1MinController.dispose();
    _apgar5MinController.dispose();
    _apgar10MinController.dispose();
    _causeOfDeathController.dispose();

    for (var drug in _suspectedDrugs) {
      drug.dispose();
    }
    for (var effect in _sideEffects) {
      effect.dispose();
    }
    for (var drug in _accompanyingDrugs) {
      drug.dispose();
    }
    for (var history in _medicalHistory) {
      history.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Желтая карта - Сообщение о побочных действиях ЛС'),
        actions: [
          // Toggle switch for required fields only
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Text(
                  'Только обязательные',
                  style: TextStyle(fontSize: 12),
                ),
                Switch(
                  value: _showOnlyRequired,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyRequired = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '1. Общая информация'),
            Tab(text: '2. Пациент'),
            Tab(text: '3. Беременность'),
            Tab(text: '4. Препарат'),
            Tab(text: '5. Побочные действия'),
            Tab(text: '6. Сопутствующие ЛС'),
            Tab(text: '7. Анамнез'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralInfoTab(),
            _buildPatientInfoTab(),
            _buildPregnancyTab(),
            _buildDrugTab(),
            _buildSideEffectsTab(),
            _buildAccompanyingDrugsTab(),
            _buildMedicalHistoryTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_tabController.index > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                child: const Text('Назад'),
              ),
            ),
          if (_tabController.index > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_tabController.index < 6) {
                  _tabController.animateTo(_tabController.index + 1);
                } else {
                  _submitForm();
                }
              },
              child: Text(_tabController.index < 6 ? 'Далее' : 'Сохранить'),
            ),
          ),
        ],
      ),
    );
  }

  // ============ TAB 1: GENERAL INFORMATION ============
  Widget _buildGeneralInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_showOnlyRequired) ...[
          _buildDropdown(
            label: 'Тип сообщения',
            value: _messageType,
            items: const [
              'Клиническое исследование',
              'Литературное',
              'Постмаркетинговое исследование',
              'Спонтанный',
            ],
            onChanged: (value) => setState(() => _messageType = value),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Вид сообщения',
            value: _messageKind,
            items: const ['Начальное сообщение', 'Последующее сообщение'],
            onChanged: (value) => setState(() => _messageKind = value),
          ),
          const SizedBox(height: 16),
          _buildDateField(
            label: 'Дата сообщения',
            value: _messageDate,
            onChanged: (date) => setState(() => _messageDate = date),
          ),
          const SizedBox(height: 24),
        ],

        const Text(
          'Сведения об организации',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _orgNameController,
          label: 'Наименование',
          required: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Обязательное поле';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        if (!_showOnlyRequired) ...[
          _buildDropdown(
            label: 'Город',
            value: _orgCity,
            items: const [
              'Алматы',
              'Астана',
              'Атырау',
              'Актау',
              'Актобе',
              'Усть-Каменогорск',
              'Тараз',
              'Караганда',
              'Костанай',
              'Петропавловск',
              'Павлодар',
              'Уральск',
              'Алматинская область',
              'Семипалатинск',
              'Кокшетау',
              'Талдыкорган',
              'Кызылорда',
              'Шымкент',
              'СНГ',
              'Туркистан',
            ],
            onChanged: (value) => setState(() => _orgCity = value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _orgAddressController,
            label: 'Адрес',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _orgPhoneController,
            label: 'Телефон',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _orgEmailController,
            label: 'Эл.почта',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),

          const Text(
            'Данные об источнике информации',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildDropdown(
            label: 'Лицо, заполнившее карту',
            value: _sourceType,
            items: const [
              'Врач',
              'Медсестра',
              'Фармацевт',
              'Пациент/Потребитель (Представитель)',
              'Представитель держателя РУ',
            ],
            onChanged: (value) => setState(() => _sourceType = value),
          ),
          const SizedBox(height: 16),
          _buildTextField(controller: _sourceNameController, label: 'Имя'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _sourcePhoneController,
            label: 'Телефон',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _sourceEmailController,
            label: 'Эл.почта',
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ],
    );
  }

  // ============ TAB 2: PATIENT INFORMATION ============
  Widget _buildPatientInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Информация о пациенте',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _patientNameController,
          label: 'Ф.И.О.(инициалы)',
          required: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Обязательное поле';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        if (!_showOnlyRequired) ...[
          _buildTextField(
            controller: _medRecordController,
            label: 'Номер медицинской карты',
          ),
          const SizedBox(height: 16),
          _buildDateField(
            label: 'Дата рождения',
            value: _patientBirthdate,
            onChanged: (date) => setState(() => _patientBirthdate = date),
          ),
          const SizedBox(height: 16),
        ],

        _buildTextField(
          controller: _patientAgeController,
          label: 'Возраст, лет',
          required: true,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Обязательное поле';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        _buildDropdown(
          label: 'Пол',
          value: _patientSex,
          required: true,
          items: const ['Мужской', 'Женский', 'Неизвестно'],
          onChanged: (value) => setState(() => _patientSex = value),
        ),
        const SizedBox(height: 16),

        if (!_showOnlyRequired) ...[
          _buildTextField(
            controller: _patientHeightController,
            label: 'Рост, см',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _patientWeightController,
            label: 'Вес, кг',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _additionalPatientInfoController,
            label: 'Дополнительные сведения',
            hint: 'Если возраст неизвестен или неизвестная дата рождения',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Национальность',
            value: _patientNationality,
            items: const ['Азиат', 'Азиат(Восточная Азия)', 'Европеец'],
            onChanged: (value) => setState(() => _patientNationality = value),
          ),
          const SizedBox(height: 24),
        ],

        const Text(
          'Клинический диагноз',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _buildMedDraTextField(
          controller: _diagnosisPrimaryController,
          label: 'Основной диагноз',
          required: true,
          hint: 'Справочник MedDRA',
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Обязательное поле';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        if (!_showOnlyRequired) ...[
          _buildMedDraTextField(
            controller: _diagnosisSecondaryController,
            label: 'Сопутствующий диагноз',
            hint: 'Справочник MedDRA',
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  // ============ TAB 3: PREGNANCY INFORMATION ============
  Widget _buildPregnancyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Информация о беременности',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _buildDropdown(
          label: 'Беременность?',
          value: _isPregnant == null ? null : (_isPregnant! ? 'Да' : 'Нет'),
          items: const ['Да', 'Нет'],
          onChanged: (value) => setState(() => _isPregnant = value == 'Да'),
        ),
        const SizedBox(height: 16),

        if (_isPregnant == true) ...[
          _buildDateField(
            label: 'Дата последней менструации',
            value: _lastMenstrualDate,
            onChanged: (date) => setState(() => _lastMenstrualDate = date),
          ),
          const SizedBox(height: 16),

          _buildDateField(
            label: 'Предполагаемая дата родов',
            value: _expectedDueDate,
            onChanged: (date) => setState(() => _expectedDueDate = date),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _fetusCountController,
            label: 'Количество плодов',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          _buildDropdown(
            label: 'Вид зачатия',
            value: _conceivingType,
            items: const ['Нормальное(включая приём лекарств)', 'Invitro'],
            onChanged: (value) => setState(() => _conceivingType = value),
          ),
          const SizedBox(height: 16),

          _buildDropdown(
            label: 'Исход беременности',
            value: _pregnancyOutcome,
            items: const [
              'Беременность продолжается',
              'Живой плод без врождённой патологии',
              'Живой плод с врождённой патологией',
              'Прерывание без видимой врождённой патологии',
              'Прерывание с врождённой патологией',
              'Спонтанный аборт без видимой врождённой патологии (<22 недель)',
              'Спонтанный аборт с врождённой патологией (<22 недель)',
              'Мёртвый плод без видимой врождённой патологии (>22 недель)',
              'Мёртвый плод с врождённой патологией (>22 недель)',
              'Внематочная беременность',
              'Пузырный занос',
              'Дальнейшее наблюдение не возможно',
              'Неизвестно',
            ],
            onChanged: (value) => setState(() => _pregnancyOutcome = value),
          ),
          const SizedBox(height: 16),

          _buildDateField(
            label: 'Фактическая дата родов',
            value: _actualDueDate,
            onChanged: (date) => setState(() => _actualDueDate = date),
          ),
          const SizedBox(height: 16),

          _buildDateField(
            label: 'Гестационный срок',
            value: _gestationalDate,
            onChanged: (date) => setState(() => _gestationalDate = date),
          ),
          const SizedBox(height: 16),

          _buildDropdown(
            label: 'Тип родов',
            value: _deliveryType,
            items: const [
              'Нормальный вагинальный',
              'Кесарево сечение',
              'Патологические вагинальные (щипцы, вакуум-экстракция)',
            ],
            onChanged: (value) => setState(() => _deliveryType = value),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _childWeightController,
            label: 'Вес ребёнка, кг',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _childHeightController,
            label: 'Рост ребёнка, см',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          _buildDropdown(
            label: 'Пол ребёнка',
            value: _childSex,
            items: const ['Мужской', 'Женский', 'Неизвестно'],
            onChanged: (value) => setState(() => _childSex = value),
          ),
          const SizedBox(height: 16),

          const Text(
            'Шкала Апгар',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _apgar1MinController,
                  label: '1 минута',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _apgar5MinController,
                  label: '5 минута',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _apgar10MinController,
                  label: '10 минута',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ] else if (_isPregnant == false) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Информация о беременности не требуется',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============ TAB 4: SUSPECTED DRUGS ============
  Widget _buildDrugTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Подозреваемые препараты/вакцины',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        ...List.generate(_suspectedDrugs.length, (index) {
          return _buildSuspectedDrugCard(index);
        }),

        if (_suspectedDrugs.length < 10)
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _suspectedDrugs.add(SuspectedDrug());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Добавить препарат'),
          ),
      ],
    );
  }

  Widget _buildSuspectedDrugCard(int index) {
    final drug = _suspectedDrugs[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. Подозреваемый препарат/вакцина',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_suspectedDrugs.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        drug.dispose();
                        _suspectedDrugs.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: drug.nameController,
              label: 'Наименование',
              required: index == 0,
              validator: index == 0
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Обязательное поле';
                      }
                      return null;
                    }
                  : null,
            ),
            const SizedBox(height: 16),

            if (!_showOnlyRequired) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Дата начала приёма',
                      value: drug.startDate,
                      onChanged: (date) =>
                          setState(() => drug.startDate = date),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      label: 'Дата завершения приёма',
                      value: drug.endDate,
                      onChanged: (date) => setState(() => drug.endDate = date),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildDropdown(
                label: 'Путь введения/частота',
                value: drug.route,
                items: const [
                  'ПЕРОРАЛЬНЫЙ',
                  'ВНУТРИВЕННЫЙ',
                  'ВНУТРИМЫШЕЧНЫЙ',
                  'ПОДКОЖНЫЙ',
                  'РЕКТАЛЬНЫЙ',
                  'ИНГАЛЯЦИОННЫЙ',
                  'ИНТРАНАЗАЛЬНЫЙ',
                  'ТРАНСДЕРМАЛЬНЫЙ',
                  'СУБЛИНГВАЛЬНЫЙ',
                ],
                onChanged: (value) => setState(() => drug.route = value),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: drug.batchController,
                label: 'Серия/партия №, срок годности',
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: drug.indicationsController,
                label: 'Показания',
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _buildDropdown(
                label: 'Предпринятые меры',
                value: drug.action,
                items: const [
                  'Препарат отменён',
                  'Курс остановлен',
                  'Доза снижена',
                  'Доза увеличена',
                  'Без изменений',
                  'Неизвестно',
                ],
                onChanged: (value) => setState(() => drug.action = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============ TAB 5: SIDE EFFECTS ============
  Widget _buildSideEffectsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Побочные действия',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        ...List.generate(_sideEffects.length, (index) {
          return _buildSideEffectCard(index);
        }),

        if (_sideEffects.length < 10)
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _sideEffects.add(SideEffect());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Добавить побочное действие'),
          ),

        const SizedBox(height: 24),

        if (!_showOnlyRequired) ...[
          _buildDropdown(
            label: 'Рассматриваете ли Вы эти побочные действия как серьёзные',
            value: _areSideEffectsSerious == null
                ? null
                : (_areSideEffectsSerious! ? 'Да' : 'Нет'),
            items: const ['Да', 'Нет'],
            onChanged: (value) =>
                setState(() => _areSideEffectsSerious = value == 'Да'),
          ),
          const SizedBox(height: 16),

          if (_areSideEffectsSerious == true) ...[
            _buildDropdown(
              label: 'Если да, то почему',
              value: _seriousReason,
              items: const [
                'Угроза для жизни',
                'Стойкая либо выраженная нетрудоспособность или инвалидность',
                'Госпитализация пациента или ее продления',
                'Врожденные аномалии или пороки развития',
                'Смерть',
              ],
              onChanged: (value) => setState(() => _seriousReason = value),
            ),
            const SizedBox(height: 16),

            if (_seriousReason == 'Смерть')
              _buildTextField(
                controller: _causeOfDeathController,
                label: 'Если пациент умер, что явилось причиной смерти',
                maxLines: 2,
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildSideEffectCard(int index) {
    final effect = _sideEffects[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. Действие',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_sideEffects.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        effect.dispose();
                        _sideEffects.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _buildMedDraTextField(
              controller: effect.effectController,
              label: 'Действие (справочник MedDRA)',
              hint: 'Описание побочного действия',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            if (!_showOnlyRequired) ...[
              _buildDropdown(
                label: 'Исход',
                value: effect.outcome,
                items: const [
                  'Выздоровление',
                  'Вр.аномалии',
                  'Улучшение',
                  'ППД',
                  'Нетрудоспособность',
                  'Ухудшение',
                  'Госпитализация',
                  'Смерть',
                ],
                onChanged: (value) => setState(() => effect.outcome = value),
              ),
              const SizedBox(height: 16),

              _buildDropdown(
                label: 'Связь с ЛС',
                value: effect.relation,
                items: const [
                  'Достоверная',
                  'Вероятная',
                  'Возможная',
                  'Сомнительная',
                  'Условная',
                  'Не связано',
                  'Неизвестно',
                  'Неподдающаяся классификация',
                  'Снижение дозы',
                  'Отмена ЛС',
                ],
                onChanged: (value) => setState(() => effect.relation = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============ TAB 6: ACCOMPANYING DRUGS ============
  Widget _buildAccompanyingDrugsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Сопутствующие ЛС',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        ...List.generate(_accompanyingDrugs.length, (index) {
          return _buildAccompanyingDrugCard(index);
        }),

        if (_accompanyingDrugs.length < 10)
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _accompanyingDrugs.add(AccompanyingDrug());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Добавить сопутствующее ЛС'),
          ),
      ],
    );
  }

  Widget _buildAccompanyingDrugCard(int index) {
    final drug = _accompanyingDrugs[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. Сопутствующее ЛС',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_accompanyingDrugs.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        drug.dispose();
                        _accompanyingDrugs.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: drug.nameController,
              label: 'Наименование',
            ),

            if (!_showOnlyRequired) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: drug.dosageFormController,
                label: 'Лекарственная форма/номер серии',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: drug.doseController,
                label: 'Общая суточная доза/путь назначения/сторона',
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Дата начала приёма',
                      value: drug.startDate,
                      onChanged: (date) =>
                          setState(() => drug.startDate = date),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      label: 'Дата завершения',
                      value: drug.endDate,
                      onChanged: (date) => setState(() => drug.endDate = date),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: drug.indicationsController,
                label: 'Показания',
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _buildDropdown(
                label: 'Предпринятые меры',
                value: drug.action,
                items: const [
                  'Препарат отменён',
                  'Курс остановлен',
                  'Доза снижена',
                  'Доза увеличена',
                  'Без изменений',
                  'Неизвестно',
                ],
                onChanged: (value) => setState(() => drug.action = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============ TAB 7: MEDICAL HISTORY ============
  Widget _buildMedicalHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Данные анамнеза',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Значимые данные анамнеза, сопутствующие заболевания, аллергия (включая курение и употребление алкоголя)',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        ...List.generate(_medicalHistory.length, (index) {
          return _buildMedicalHistoryCard(index);
        }),

        if (_medicalHistory.length < 10)
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _medicalHistory.add(MedicalHistory());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Добавить данные анамнеза'),
          ),
      ],
    );
  }

  Widget _buildMedicalHistoryCard(int index) {
    final history = _medicalHistory[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. Данные анамнеза',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_medicalHistory.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        history.dispose();
                        _medicalHistory.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: history.nameController,
              label: 'Наименование',
              maxLines: 2,
            ),

            if (!_showOnlyRequired) ...[
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Продолжается?',
                value: history.continues == null
                    ? null
                    : (history.continues! ? 'Да' : 'Нет'),
                items: const ['Да', 'Нет'],
                onChanged: (value) =>
                    setState(() => history.continues = value == 'Да'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============ HELPER WIDGETS ============

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(color: required ? Colors.red : null),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildMedDraTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: required ? '$label *' : label,
              hintText: hint,
              border: const OutlineInputBorder(),
              labelStyle: TextStyle(color: required ? Colors.red : null),
            ),
            maxLines: maxLines,
            validator: validator,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton.filled(
            onPressed: () async {
              final selected = await showMedDraSelector(context, title: label);
              if (selected != null) {
                controller.text = selected;
              }
            },
            icon: const Icon(Icons.search),
            tooltip: 'Выбрать из справочника MedDRA',
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool required = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(color: required ? Colors.red : null),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Обязательное поле';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required void Function(DateTime?) onChanged,
    bool required = false,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          labelStyle: TextStyle(color: required ? Colors.red : null),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? DateFormat('dd.MM.yyyy').format(value)
              : 'Выберите дату',
          style: TextStyle(color: value != null ? Colors.black : Colors.grey),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Форма успешно сохранена'),
          backgroundColor: Colors.green,
        ),
      );
      // TODO: Implement actual submission logic
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните все обязательные поля'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ============ DATA CLASSES ============

class SuspectedDrug {
  final nameController = TextEditingController();
  final batchController = TextEditingController();
  final indicationsController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  String? route;
  String? action;

  void dispose() {
    nameController.dispose();
    batchController.dispose();
    indicationsController.dispose();
  }
}

class SideEffect {
  final effectController = TextEditingController();
  String? outcome;
  String? relation;

  void dispose() {
    effectController.dispose();
  }
}

class AccompanyingDrug {
  final nameController = TextEditingController();
  final dosageFormController = TextEditingController();
  final doseController = TextEditingController();
  final indicationsController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  String? action;

  void dispose() {
    nameController.dispose();
    dosageFormController.dispose();
    doseController.dispose();
    indicationsController.dispose();
  }
}

class MedicalHistory {
  final nameController = TextEditingController();
  bool? continues;

  void dispose() {
    nameController.dispose();
  }
}
