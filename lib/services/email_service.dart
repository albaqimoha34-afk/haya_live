import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// خدمة إرسال البريد الإلكتروني - تُستخدم لإرسال رمز OTP الحقيقي
// عند الضغط على "نسيت كلمة المرور"
//
// ⚠️ قبل التشغيل: استبدل القيمتين أدناه ببريدك وكلمة مرور التطبيق (App Password) الخاصة بك.
// لا تستخدم كلمة مرور حسابك العادية أبدًا هنا.
class EmailService {
  // بريدك الإلكتروني (المُرسِل) - يجب أن يكون حساب Gmail
  static const String _senderEmail = 'bdalbaqymhmd446@gmail.com';

  // كلمة مرور التطبيق (App Password) المكوّنة من 16 حرفًا من إعدادات Google
  // (راجع README لمعرفة كيفية الحصول عليها) - هذه ليست كلمة مرور حسابك العادية
  static const String _senderAppPassword = 'ympxfbjeooxyroxf';

  static const String _senderName = 'هيا لايف';

  // ترسل رمز التحقق (OTP) إلى بريد المستخدم فعليًا عبر خدمة SMTP الخاصة بـ Gmail
  static Future<void> sendOtpEmail({
    required String recipientEmail,
    required String otp,
  }) async {
    final smtpServer = gmail(_senderEmail, _senderAppPassword);

    final message = Message()
      ..from = Address(_senderEmail, _senderName)
      ..recipients.add(recipientEmail)
      ..subject = 'رمز التحقق الخاص بك - هيا لايف'
      ..text = 'رمز التحقق لاستعادة كلمة المرور هو: $otp\n\nصالح لهذه المحاولة فقط.';

    // إرسال الرسالة فعليًا - قد يستغرق بضع ثوانٍ حسب سرعة الإنترنت
    await send(message, smtpServer);
  }
}
