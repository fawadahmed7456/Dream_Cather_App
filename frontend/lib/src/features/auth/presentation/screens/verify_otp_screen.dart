import 'package:flutter/material.dart';
import '../../../../core/routes/routes_constants.dart';
import '../bloc/auth_cubit.dart';

class VerifyOTPArgs {
  final String phoneNumber;
  final AuthCubit? cubit;
  const VerifyOTPArgs({required this.phoneNumber, this.cubit});
}

/// Legacy VerifyOTPScreen maintained for route compatibility.
class VerifyOTPScreen extends StatelessWidget {
  final String phoneNumber;
  final AuthCubit? existingCubit;

  const VerifyOTPScreen({
    super.key,
    required this.phoneNumber,
    this.existingCubit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, Routes.kHouseRules);
          },
          child: const Text('Continue to House Rules'),
        ),
      ),
    );
  }
}
