import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routes/routes_constants.dart';
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
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: _previousStep,
        ),
        title: Text(
          'Sign Up',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF0F0F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF289CEB)),
            minHeight: 3,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _buildCurrentStepContent(),
                ),
              ),
              _buildBottomActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildUsernameStep();
      case 1:
        return _buildGenderStep();
      case 2:
        return _buildSexualOrientationStep();
      case 3:
        return _buildBirthdayStep();
      case 4:
        return _buildEthnicityStep();
      case 5:
        return _buildPersonalityStep();
      case 6:
        return _buildRelationshipStep();
      case 7:
        return _buildEducationStep();
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Username ────────────────────────────────────────────────────────
  Widget _buildUsernameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "What's your Username?",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 28),
        TextFormField(
          controller: _usernameController,
          style: GoogleFonts.outfit(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Username',
            hintStyle: GoogleFonts.outfit(color: const Color(0xFFB1B1B1)),
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF289CEB), width: 1.5),
            ),
            errorText: _usernameError,
          ),
          onChanged: (_) {
            if (_usernameError != null) setState(() => _usernameError = null);
          },
        ),
        const SizedBox(height: 12),
        Text(
          'This will be shown on your profile. Username cannot be changed',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: const Color(0xFFEF3826),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Gender ──────────────────────────────────────────────────────────
  Widget _buildGenderStep() {
    final mainGenders = ['Male', 'Female', 'Others'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'What gender do you identify as?',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 28),
        ...mainGenders.map((g) {
          final isOthers = g == 'Others';
          final isSelected = _selectedGender == g ||
              (isOthers &&
                  _selectedGender != null &&
                  _selectedGender != 'Male' &&
                  _selectedGender != 'Female');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildSelectableOption(
              label: isOthers && isSelected ? _selectedGender! : g,
              hasArrow: isOthers,
              isSelected: isSelected,
              onTap: () {
                if (isOthers) {
                  _showDetailedGenderPicker();
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

  void _showDetailedGenderPicker() {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select Gender',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? const Color(0xFF289CEB) : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Color(0xFF289CEB))
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
  Widget _buildSexualOrientationStep() {
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
        const SizedBox(height: 16),
        Text(
          "What's your sexual orientation?",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 28),
        ...orientations.map((item) {
          final isSelected = _selectedSexualOrientation == item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildSelectableOption(
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
  Widget _buildBirthdayStep() {
    final formatted = DateFormat('MMMM dd, yyyy').format(_selectedBirthday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "What's your birthday?",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 28),
        InkWell(
          onTap: _showCupertinoDatePicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: Color(0xFF8E8E93), size: 20),
                const SizedBox(width: 12),
                Text(
                  formatted,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your age will be used for profile matching. Your profile will show your age, not your date of birth. This cannot be changed later.',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: const Color(0xFFEF3826),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  void _showCupertinoDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Birthday',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Done',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF289CEB),
                        ),
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
  Widget _buildEthnicityStep() {
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
        const SizedBox(height: 16),
        Text(
          "What's your ethnicity?",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 28),
        ...ethnicities.map((item) {
          final isSelected = _selectedEthnicity == item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildSelectableOption(
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
  Widget _buildPersonalityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "What's your personality type?",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 32),

        // 4 MBTI Segmented dimension selectors
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMbtiSegment(
              opt1: 'I',
              opt2: 'E',
              selected: _personalityIE,
              onSelect: (v) => setState(() => _personalityIE = v),
            ),
            _buildMbtiSegment(
              opt1: 'S',
              opt2: 'N',
              selected: _personalitySN,
              onSelect: (v) => setState(() => _personalitySN = v),
            ),
            _buildMbtiSegment(
              opt1: 'F',
              opt2: 'T',
              selected: _personalityFT,
              onSelect: (v) => setState(() => _personalityFT = v),
            ),
            _buildMbtiSegment(
              opt1: 'P',
              opt2: 'J',
              selected: _personalityPJ,
              onSelect: (v) => setState(() => _personalityPJ = v),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'The personality type used follows the 16 Personalities. It will be used as a filter for more accurate matching.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF8E8E93),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildMbtiSegment({
    required String opt1,
    required String opt2,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMbtiChip(opt1, selected == opt1, () => onSelect(opt1)),
          _buildMbtiChip(opt2, selected == opt2, () => onSelect(opt2)),
        ],
      ),
    );
  }

  Widget _buildMbtiChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF289CEB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF2C2C2E),
          ),
        ),
      ),
    );
  }

  // ── Step 7: Relationship Status ─────────────────────────────────────────────
  Widget _buildRelationshipStep() {
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
        const SizedBox(height: 16),
        Text(
          "What's your relationship status?",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 28),
        ...list.map((item) {
          final isSelected = _selectedRelationshipStatus == item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildSelectableOption(
              label: item,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedRelationshipStatus = item);
              },
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          'Your relationship status will be used as a filter for more accurate matching.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  // ── Step 8: Education Level ─────────────────────────────────────────────────
  Widget _buildEducationStep() {
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
        const SizedBox(height: 16),
        Text(
          "What's your highest education level?",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 28),
        ...list.map((item) {
          final isSelected = _selectedEducationLevel == item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildSelectableOption(
              label: item,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedEducationLevel = item);
              },
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          'Your education level will be used as a filter for more accurate matching.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  // ── Shared Option Box ───────────────────────────────────────────────────────
  Widget _buildSelectableOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF289CEB) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF289CEB) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            if (hasArrow)
              Icon(
                Icons.chevron_right,
                color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Action Buttons ───────────────────────────────────────────────────
  Widget _buildBottomActionButtons() {
    final isSkippable = _currentStep >= 5; // Personality, Relationship, Education

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
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
              backgroundColor: const Color(0xFF289CEB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving || _isCheckingUsername
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _currentStep == _totalSteps - 1 ? 'Complete' : 'Continue',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        if (isSkippable) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isSaving ? null : _nextStep,
            child: Text(
              'Skip',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8E8E93),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
