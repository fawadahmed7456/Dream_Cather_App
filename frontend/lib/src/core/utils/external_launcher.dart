import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared_widgets/state/app_snackbar.dart';
import 'logger_utils.dart';

/// Thin wrapper over `url_launcher` that never throws into the UI and
/// degrades gracefully when no handler app is installed — common on bare
/// AOSP emulators with no mail client, browser or WhatsApp. When a launch
/// can't be satisfied it copies the useful value to the clipboard and tells
/// the user, instead of the button silently doing nothing.
class ExternalLauncher {
  const ExternalLauncher._();

  static const _tag = 'ExternalLauncher';

  /// Opens the device dialer pre-filled with [phone] (E.164, e.g. +9230…).
  static Future<void> phone(BuildContext context, String phone) => _launch(
        context,
        Uri(scheme: 'tel', path: phone),
        copyValue: phone,
        copyLabel: 'Phone number copied',
      );

  /// Opens the mail composer addressed to [address] with an optional
  /// [subject] line.
  static Future<void> email(
    BuildContext context,
    String address, {
    String? subject,
  }) =>
      _launch(
        context,
        Uri(
          scheme: 'mailto',
          path: address,
          query: subject == null
              ? null
              : 'subject=${Uri.encodeComponent(subject)}',
        ),
        copyValue: address,
        copyLabel: 'Email address copied',
      );

  /// Opens a WhatsApp chat with [phoneDigits] (digits only, country code
  /// first, no '+', e.g. 9230…) via the wa.me deep link, optionally
  /// pre-filling [text].
  static Future<void> whatsApp(
    BuildContext context,
    String phoneDigits, {
    String? text,
  }) =>
      _launch(
        context,
        Uri.parse(
          'https://wa.me/$phoneDigits'
          '${text == null ? '' : '?text=${Uri.encodeComponent(text)}'}',
        ),
        copyValue: '+$phoneDigits',
        copyLabel: 'WhatsApp number copied',
      );

  /// Opens [url] in the browser / appropriate external app.
  static Future<void> web(BuildContext context, String url) => _launch(
        context,
        Uri.parse(url),
        copyValue: url,
        copyLabel: 'Link copied',
      );

  static Future<void> _launch(
    BuildContext context,
    Uri uri, {
    required String copyValue,
    required String copyLabel,
  }) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (e) {
      Log.w(_tag, 'launch failed for $uri: $e');
    }
    // No app could handle it (or it refused) — make the value usable anyway.
    if (!context.mounted) return;
    await Clipboard.setData(ClipboardData(text: copyValue));
    if (!context.mounted) return;
    AppSnackbar.info(context, '$copyLabel — no app available to open it.');
  }
}
