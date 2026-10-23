import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routes/routes_constants.dart';
import '../../../../core/utils/size_utils.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  int _currentStep = 0;
  final int _totalSteps = 8;
  bool _isSaving = false;

  // Form State
  final _usernameController = TextEditingController();
  String? _usernameError;
  bool _isCheckingUsername = false;

  String? _selectedGender;
  String? _selectedSexualOrientation;
  DateTime _selectedBirthday = DateTime(2001, 9, 17);
  String? _selectedEthnicity;

  // Myers-Briggs 16-Personalities Dimensions
  String? _personalityIE = 'I'; // 'I' or 'E'
  String? _personalitySN = 'S'; // 'S' or 'N'
  String? _personalityFT = 'F'; // 'F' or 'T'
  String? _personalityPJ = 'P'; // 'P' or 'J'

  String? _selectedRelationshipStatus;
  String? _selectedEducationLevel;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submitRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _validateAndAdvanceUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _usernameError = 'Please enter a username');
      return;
    }
    if (username.length < 3) {
      setState(() => _usernameError = 'Username must be at least 3 characters');
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    final repo = sl<AuthRepository>();
    final isAvailable = await repo.isUsernameAvailable(username);

    if (!mounted) return;
    setState(() => _isCheckingUsername = false);

    if (!isAvailable) {
      setState(() => _usernameError = 'Username is already taken');
      return;
    }

    _nextStep();
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSaving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please sign in again.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, Routes.kLogin, (r) => false);
      return;
    }

    final profile = UserProfile(
      id: user.id,
      username: _usernameController.text.trim(),
      email: user.email ?? '',
      gender: _selectedGender,
      sexualOrientation: _selectedSexualOrientation,
      birthday: _selectedBirthday,
      ethnicity: _selectedEthnicity,
      personalityIe: _personalityIE,
      personalitySn: _personalitySN,
      personalityFt: _personalityFT,
      personalityPj: _personalityPJ,
      relationshipStatus: _selectedRelationshipStatus,
      educationLevel: _selectedEducationLevel,
    );

    try {
      final repo = sl<AuthRepository>();
      await repo.saveUserProfile(profile);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.kBottomNavBar,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: AppColors.coralRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurface,
            size: 20.adaptSize,
          ),
          onPressed: _previousStep,
        ),
        title: Text(
          'Sign Up',
          style: AppTextStyles.text18Semibold(context),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.h),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF0F0F0),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            minHeight: 3.h,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _buildCurrentStepContent(context),
                ),
              ),
              _buildBottomActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildUsernameStep(context);
      case 1:
        return _buildGenderStep(context);
      case 2:
        return _buildSexualOrientationStep(context);
      case 3:
        return _buildBirthdayStep(context);
      case 4:
        return _buildEthnicityStep(context);
      case 5:
        return _buildPersonalityStep(context);
      case 6:
        return _buildRelationshipStep(context);
      case 7:
        return _buildEducationStep(context);
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Username ────────────────────────────────────────────────────────
  Widget _buildUsernameStep(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          "What's your Username?",
          style: AppTextStyles.wizardTitle(context),
        ),
        SizedBox(height: 28.h),
        TextFormField(
          controller: _usernameController,
          style: AppTextStyles.inputText(context),
          decoration: InputDecoration(
            hintText: 'Username',
            hintStyle: AppTextStyles.inputHint(context),
            filled: true,
            fillColor: isDark ? AppColors.darkCard : const Color(0xFFF7F8FA),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.adaptSize),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.adaptSize),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.adaptSize),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            errorText: _usernameError,
          ),
          onChanged: (_) {
            if (_usernameError != null) setState(() => _usernameError = null);
          },
        ),
        SizedBox(height: 12.h),
        Text(
          'This will be shown on your profile. Username cannot be changed',
          style: AppTextStyles.disclaimer(context),
        ),
      ],
    );
  }

  // ── Step 2: Gender ──────────────────────────────────────────────────────────
  Widget _buildGenderStep(BuildContext context) {
    final mainGenders = ['Male', 'Female', 'Others'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          'What gender do you identify as?',
          style: AppTextStyles.wizardTitle(context),
        ),
        SizedBox(height: 28.h),
        ...mainGenders.map((g) {
          final isOthers = g == 'Others';
          final isSelected = _selectedGender == g ||
              (isOthers &&
                  _selectedGender != null &&
                  _selectedGender != 'Male' &&
                  _selectedGender != 'Female');

          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildSelectableOption(
              context: context,
              label: isOthers && isSelected ? _selectedGender! : g,
              hasArrow: isOthers,
              isSelected: isSelected,
              onTap: () {
                if (isOthers) {
                  _showDetailedGenderPicker(context);
                } else {
                  setState(() => _selectedGender = g);
                }
              },
            ),
          );
        }),
      ],
    );
  }

  void _showDetailedGenderPicker(BuildContext context) {
    final list = [
      'Agender',
      'Androgyne',
      'Bigender',
      'Cis Man',
      'Cis Woman',
      'Gender Fluid',
      'Gender Nonconforming',
      'Genderqueer',
      'Hijra',
      'Intersex',
      'Neutrois',
      'Non-binary',
      'Pangender',
      'Poligender',
      'Trans Man',
      'Trans Woman',
      'Two-Spirit',
      'Other',
    ];

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.adaptSize)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.adaptSize),
                  child: Text(
                    'Select Gender',
                    style: AppTextStyles.text18Semibold(context),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: list.length,
                    itemBuilder: (context, idx) {
                      final item = list[idx];
                      final isSelected = _selectedGender == item;
                      return ListTile(
                        title: Text(
                          item,
                          style: isSelected
                              ? AppTextStyles.text15Semibold(
                                  context,
                                  textColor: theme.colorScheme.primary,
                                )
                              : AppTextStyles.text15Normal(context),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: theme.colorScheme.primary)
                            : null,
                        onTap: () {
                          setState(() => _selectedGender = item);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Step 3: Sexual Orientation ──────────────────────────────────────────────
  Widget _buildSexualOrientationStep(BuildContext context) {
    final orientations = [
      'Heterosexual',
      'Bisexual',
      'Gay',
      'Lesbian',
      'Queer',
      'Asexual',
      'Demisexual',
      'Pansexual',
      'Others',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          "What's your sexual orientation?",
          style: AppTextStyles.wizardTitle(context),
        ),
        SizedBox(height: 28.h),
        ...orientations.map((item) {
          final isSelected = _selectedSexualOrientation == item;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildSelectableOption(
              context: context,
              label: item,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedSexualOrientation = item);
              },
            ),
          );
        }),
      ],
    );
  }

  // ── Step 4: Birthday ────────────────────────────────────────────────────────
  Widget _buildBirthdayStep(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatted = DateFormat('MMMM dd, yyyy').format(_selectedBirthday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          "What's your birthday?",
          style: AppTextStyles.wizardTitle(context),
        ),
        SizedBox(height: 28.h),
        InkWell(
          onTap: () => _showCupertinoDatePicker(context),
          borderRadius: BorderRadius.circular(12.adaptSize),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12.adaptSize),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
                  size: 20.adaptSize,
                ),
                SizedBox(width: 12.w),
                Text(
                  formatted,
                  style: AppTextStyles.inputText(context),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Your age will be used for profile matching. Your profile will show your age, not your date of birth. This cannot be changed later.',
          style: AppTextStyles.disclaimer(context),
        ),
      ],
    );
  }

  void _showCupertinoDatePicker(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.adaptSize)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: 280.h,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Birthday',
                      style: AppTextStyles.text16Semibold(context),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Done',
                        style: AppTextStyles.linkText(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedBirthday,
                  maximumDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
                  minimumYear: 1940,
                  maximumYear: DateTime.now().year - 13,
                  onDateTimeChanged: (newDate) {
                    setState(() => _selectedBirthday = newDate);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Step 5: Ethnicity ───────────────────────────────────────────────────────
  Widget _buildEthnicityStep(BuildContext context) {
    final ethnicities = [
      'Asian',
      'Black/African descent',
      'Hispanic/Latino',
      'Native American',
      'Pacific Islander',
      'White/Caucasian',
      'Others',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          "What's your ethnicity?",
          style: AppTextStyles.wizardTitle(context),
        ),
        SizedBox(height: 28.h),
        ...ethnicities.map((item) {
          final isSelected = _selectedEthnicity == item;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildSelectableOption(
              context: context,
              label: item,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedEthnicity = item);
              },
            ),
          );
        }),
      ],
    );
  }

  // ── Step 6: MBTI Personality Type ───────────────────────────────────────────
  Widget _buildPersonalityStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          "What's your personality type?",
          style: AppTextStyles.wizardTitle(context),
        ),
        SizedBox(height: 32.h),

        // 4 MBTI Segmented dimension selectors
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMbtiSegment(
              context: context,
              opt1: 'I',
              opt2: 'E',
              selected: _personalityIE,
              onSelect: (v) => setState(() => _personalityIE = v),
            ),
            _buildMbtiSegment(
              context: context,
              opt1: 'S',
              opt2: 'N',
              selected: _personalitySN,
              onSelect: (v) => setState(() => _personalitySN = v),
            ),
            _buildMbtiSegment(
              context: context,
              opt1: 'F',
              opt2: 'T',
              selected: _personalityFT,
              onSelect: (v) => setState(() => _personalityFT = v),
            ),
            _buildMbtiSegment(
              context: context,
              opt1: 'P',
              opt2: 'J',
              selected: _personalityPJ,
              onSelect: (v) => setState(() => _personalityPJ = v),
            ),
          ],
        ),
        SizedBox(height: 32.h),
        Text(
          'The personality type used follows the 16 Personalities. It will be used as a filter for more accurate matching.',
          style: AppTextStyles.helperText(context),
        ),
      ],
    );
  }

  Widget _buildMbtiSegment({
    required BuildContext context,
    required String opt1,
    required String opt2,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10.adaptSize),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMbtiChip(context, opt1, selected == opt1, () => onSelect(opt1)),
          _buildMbtiChip(context, opt2, selected == opt2, () => onSelect(opt2)),
        ],
      ),
    );
  }

  Widget _buildMbtiChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w,
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.adaptSize),
        ),
        child: Text(
          label,
          style: AppTextStyles.text16Bold(
            context,
            textColor: isSelected
                ? AppColors.white
                : (isDark ? AppColors.darkTextPrimary : const Color(0xFF2C2C2E)),
          ),
        ),
      ),
    );
  }

  // ── Step 7: Relationship Status ─────────────────────────────────────────────
  Widget _buildRelationshipStep(BuildContext context) {
    final list = [
      'Single',
      'Seeing someone/dating',
      'Married',
      'Divorced',
      'Widowed',
      'Others',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          "What's your relationship status?",
          style: AppTextStyles.wizardTitle(context),
        ),
        SizedBox(height: 28.h),
        ...list.map((item) {
          final isSelected = _selectedRelationshipStatus == item;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildSelectableOption(
              context: context,
              label: item,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedRelationshipStatus = item);
              },
            ),
          );
        }),
        SizedBox(height: 8.h),
        Text(
          'Your relationship status will be used as a filter for more accurate matching.',
          style: AppTextStyles.helperText(context),
        ),
      ],
    );
  }

  // ── Step 8: Education Level ─────────────────────────────────────────────────
  Widget _buildEducationStep(BuildContext context) {
    final list = [
      'Middle School',
      'High school',
      "Bachelor's",
      "Master's/MBA/JD",
      'PhD',
      'Others',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          "What's your highest education level?",
          style: AppTextStyles.wizardTitle(context),
        ),
        SizedBox(height: 28.h),
        ...list.map((item) {
          final isSelected = _selectedEducationLevel == item;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildSelectableOption(
              context: context,
              label: item,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedEducationLevel = item);
              },
            ),
          );
        }),
        SizedBox(height: 8.h),
        Text(
          'Your education level will be used as a filter for more accurate matching.',
          style: AppTextStyles.helperText(context),
        ),
      ],
    );
  }

  // ── Shared Option Box ───────────────────────────────────────────────────────
  Widget _buildSelectableOption({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasArrow = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.adaptSize),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.darkCard : const Color(0xFFF7F8FA)),
          borderRadius: BorderRadius.circular(12.adaptSize),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.wizardOption(context, isSelected: isSelected),
            ),
            if (hasArrow)
              Icon(
                Icons.chevron_right,
                color: isSelected
                    ? AppColors.white
                    : (isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93)),
                size: 20.adaptSize,
              ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Action Buttons ───────────────────────────────────────────────────
  Widget _buildBottomActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSkippable = _currentStep >= 5; // Personality, Relationship, Education

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: _isSaving || _isCheckingUsername
                ? null
                : () {
                    if (_currentStep == 0) {
                      _validateAndAdvanceUsername();
                    } else {
                      _nextStep();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
            ),
            child: _isSaving || _isCheckingUsername
                ? SizedBox(
                    width: 22.adaptSize,
                    height: 22.adaptSize,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2.5.w,
                    ),
                  )
                : Text(
                    _currentStep == _totalSteps - 1 ? 'Complete' : 'Continue',
                    style: AppTextStyles.primaryButton(context),
                  ),
          ),
        ),
        if (isSkippable) ...[
          SizedBox(height: 8.h),
          TextButton(
            onPressed: _isSaving ? null : _nextStep,
            child: Text(
              'Skip',
              style: AppTextStyles.text15Semibold(
                context,
                textColor: isDark ? AppColors.darkTextMuted : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
