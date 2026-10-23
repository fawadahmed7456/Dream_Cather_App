import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../src.dart';

/// One-time profile completion shown after OTP verification when the
/// caller's `public.users` row has no `full_name`. Required: name.
/// Optional: email, avatar. "Skip" routes straight to the bottom nav —
/// the user can fill these later from Edit Profile.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  static const String _tag = 'CompleteProfile';

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _picker = ImagePicker();

  File? _pickedAvatar;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _pickedAvatar = File(picked.path));
      }
    } catch (e) {
      Log.w(_tag, 'pickAvatar failed: $e');
      if (mounted) AppSnackbar.error(context, 'Could not pick image.');
    }
  }

  void _skip() {
    Navigator.pushNamedAndRemoveUntil(
        context, Routes.kBottomNavBar, (_) => false);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final repo = sl<ProfileRepository>();
      String? avatarUrl;

      if (_pickedAvatar != null) {
        final userId = SupabaseAuthBridge.instance.userId;
        if (userId == null) {
          throw StateError('No Supabase session — cannot upload avatar.');
        }
        avatarUrl = await sl<SupabaseStorageService>().uploadProfilePhoto(
          file: _pickedAvatar!,
          userId: userId,
        );
      }

      final email = _emailCtrl.text.trim();
      final changes = <String, dynamic>{
        'full_name': _nameCtrl.text.trim(),
        if (email.isNotEmpty) 'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      final result = await repo.updateCurrent(changes);
      if (!mounted) return;

      result.fold(
        (failure) {
          AppSnackbar.error(context, failure.message);
        },
        (_) {
          AppSnackbar.success(context, 'Welcome to SafarShare!');
          Navigator.pushNamedAndRemoveUntil(
              context, Routes.kBottomNavBar, (_) => false);
        },
      );
    } catch (e, st) {
      Log.e(_tag, 'save threw', e, st);
      if (mounted) AppSnackbar.error(context, 'Could not save profile: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: Sizes.paddingXL.w, vertical: Sizes.paddingXL.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: Sizes.paddingM.h),
                Text(
                  'Complete your profile',
                  style:
                      Styles.text24Semibold(context, textColor: cs.onSurface),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Just a few details so other riders know who they\'re sharing with.',
                  style: Styles.text13Medium(context,
                      textColor: cs.onSurfaceVariant),
                ),
                SizedBox(height: Sizes.paddingXXL.h),
                Center(child: _avatarPicker(cs)),
                SizedBox(height: Sizes.paddingXXL.h),
                _labeled('Full name', required: true),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _nameCtrl,
                  inputFormatters: [
                    AppInputFormatters.name,
                    LengthLimitingTextInputFormatter(50),
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('e.g. Asad Khan'),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Please enter your name.';
                    if (t.length < 2) return 'Name is too short.';
                    return null;
                  },
                ),
                SizedBox(height: Sizes.paddingL.h),
                _labeled('Email (optional)'),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _emailCtrl,
                  inputFormatters: [
                    AppInputFormatters.email,
                    LengthLimitingTextInputFormatter(100),
                  ],
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration('you@example.com'),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    final ok =
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
                    return ok ? null : 'Enter a valid email.';
                  },
                ),
                SizedBox(height: Sizes.paddingXXL.h),
                CustomButton(
                  text: _saving ? 'Saving…' : 'Save & Continue',
                  onTap: _saving ? null : _save,
                ),
                SizedBox(height: Sizes.paddingM.h),
                TextButton(
                  onPressed: _saving ? null : _skip,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeled(String text, {bool required = false}) {
    return Row(
      children: [
        Text(text,
            style: Styles.text13Medium(context,
                textColor: Theme.of(context).colorScheme.onSurface)),
        if (required)
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: const Text('*', style: TextStyle(color: AppColors.red)),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
      filled: true,
      fillColor: Theme.of(context).cardTheme.color ?? cs.surface,
      contentPadding:
          EdgeInsets.symmetric(horizontal: Sizes.paddingL.w, vertical: 14.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.adaptSize),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.adaptSize),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.adaptSize),
        borderSide: BorderSide(color: cs.error),
      ),
    );
  }

  Widget _avatarPicker(ColorScheme cs) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _saving ? null : _pickAvatar,
      child: Stack(
        children: [
          Container(
            width: 96.w,
            height: 96.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surface,
              border: Border.all(color: cs.outlineVariant, width: 1.5),
              image: _pickedAvatar != null
                  ? DecorationImage(
                      image: FileImage(_pickedAvatar!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _pickedAvatar == null
                ? Icon(Icons.person_outline_rounded,
                    size: 44.adaptSize, color: cs.onSurfaceVariant)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt_rounded,
                  size: 16.adaptSize, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
