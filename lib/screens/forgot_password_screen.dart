import 'dart:math';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/email_service.dart';

// شاشة نسيت كلمة المرور - تعمل على 3 مراحل داخل نفس الشاشة:
// 0) إدخال البريد الإلكتروني
// 1) إدخال رمز التحقق (OTP) - يُرسل فعليًا إلى بريد المستخدم عبر SMTP
// 2) إدخال كلمة المرور الجديدة
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _dbHelper = DBHelper();

  int _step = 0;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _generatedOtp;
  String? _emailError;
  String? _otpError;
  String? _passwordError;

  // ===== المرحلة 1: إرسال الرمز (محاكاة) =====
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    setState(() => _emailError = null);

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'الرجاء إدخال بريد إلكتروني صحيح');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _dbHelper.getUserByEmail(email);

      if (!mounted) return;

      if (user == null) {
        setState(() => _emailError = 'لا يوجد حساب مسجّل بهذا البريد الإلكتروني');
        return;
      }

      // توليد رمز عشوائي من 6 أرقام وإرساله فعليًا إلى بريد المستخدم عبر SMTP
      final otp = (100000 + Random().nextInt(900000)).toString();
      _generatedOtp = otp;

      await EmailService.sendOtpEmail(recipientEmail: email, otp: otp);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال رمز التحقق إلى بريدك الإلكتروني')),
      );
      setState(() => _step = 1);
    } catch (e) {
      if (!mounted) return;
      setState(() => _emailError = 'تعذّر إرسال البريد الإلكتروني، تحقق من الاتصال وأعد المحاولة');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== المرحلة 2: التحقق من الرمز =====
  void _verifyOtp() {
    setState(() => _otpError = null);
    final entered = _otpController.text.trim();

    if (entered.isEmpty) {
      setState(() => _otpError = 'الرجاء إدخال رمز التحقق');
      return;
    }

    if (entered == _generatedOtp) {
      setState(() => _step = 2);
    } else {
      setState(() => _otpError = 'رمز التحقق غير صحيح، حاول مرة أخرى');
    }
  }

  // ===== المرحلة 3: تعيين كلمة مرور جديدة =====
  Future<void> _resetPassword() async {
    setState(() => _passwordError = null);
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || newPassword.length < 6) {
      setState(() => _passwordError = 'كلمة المرور يجب ألا تقل عن 6 أحرف');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _passwordError = 'كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _dbHelper.updatePassword(_emailController.text.trim(), newPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح، الرجاء تسجيل الدخول')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _passwordError = 'حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // مؤشر بسيط للمرحلة الحالية
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final active = index <= _step;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 32,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.green : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              if (_step == 0) _buildEmailStep(),
              if (_step == 1) _buildOtpStep(),
              if (_step == 2) _buildNewPasswordStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('أدخل بريدك الإلكتروني وسنرسل لك رمز تحقق', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'البريد الإلكتروني',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _emailError,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _isLoading ? null : _sendOtp,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('إرسال رمز التحقق'),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('أدخل رمز التحقق المكوّن من 6 أرقام', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'رمز التحقق',
            prefixIcon: const Icon(Icons.pin_outlined),
            errorText: _otpError,
          ),
        ),
        FilledButton(
          onPressed: _verifyOtp,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('تحقق من الرمز'),
        ),
        TextButton(
          onPressed: _sendOtp,
          child: const Text('إعادة إرسال الرمز'),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('أدخل كلمة المرور الجديدة', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'كلمة المرور الجديدة',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'تأكيد كلمة المرور',
            prefixIcon: const Icon(Icons.lock_outline),
            errorText: _passwordError,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _isLoading ? null : _resetPassword,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('حفظ كلمة المرور'),
        ),
      ],
    );
  }
}
